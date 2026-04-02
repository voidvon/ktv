import 'package:flutter/foundation.dart';

import '../../../core/models/artist.dart';
import '../../../core/models/artist_page.dart';
import '../../../core/models/song.dart';
import '../../../core/models/song_page.dart';
import 'android_storage_data_source.dart';
import 'media_library_data_source.dart';
import 'scan_directory_data_source.dart';

class MediaLibraryRepository {
  MediaLibraryRepository({
    MediaLibraryDataSource? mediaLibraryDataSource,
    ScanDirectoryDataSource? scanDirectoryDataSource,
    AndroidStorageDataSource? androidStorageDataSource,
  }) : _mediaLibraryDataSource =
           mediaLibraryDataSource ?? MediaLibraryDataSource(),
       _scanDirectoryDataSource =
           scanDirectoryDataSource ?? ScanDirectoryDataSource(),
       _androidStorageDataSource =
           androidStorageDataSource ?? AndroidStorageDataSource();

  final MediaLibraryDataSource _mediaLibraryDataSource;
  final ScanDirectoryDataSource _scanDirectoryDataSource;
  final AndroidStorageDataSource _androidStorageDataSource;
  final Map<String, List<Song>> _cachedSongsByDirectory =
      <String, List<Song>>{};

  Future<String?> pickDirectory({String? initialDirectory}) {
    return _scanDirectoryDataSource.pickDirectory(
      initialDirectory: initialDirectory,
    );
  }

  Future<bool> ensureDirectoryAccess(String path) {
    return _scanDirectoryDataSource.ensureDirectoryAccess(path);
  }

  Future<void> clearDirectoryAccess({String? path}) {
    return _scanDirectoryDataSource.clearDirectoryAccess(path: path);
  }

  Future<void> saveSelectedDirectory(String path) {
    return _scanDirectoryDataSource.saveSelectedDirectory(path);
  }

  Future<String?> loadSelectedDirectory() {
    return _scanDirectoryDataSource.loadSelectedDirectory();
  }

  Future<int> scanLibrary(String directory) async {
    if (_usesIndexedAndroidLibrary(directory)) {
      return _androidStorageDataSource.scanLibraryIntoIndex(directory);
    }

    final List<LibrarySong> songs = await _mediaLibraryDataSource.scanLibrary(
      directory,
    );
    final List<Song> mappedSongs = songs
        .map(
          (LibrarySong song) => Song(
            title: song.title,
            artist: song.artist,
            languages: song.languages,
            tags: song.tags,
            searchIndex: song.searchIndex,
            mediaPath: song.mediaPath,
          ),
        )
        .toList(growable: false);
    _cachedSongsByDirectory[directory] = mappedSongs;
    return mappedSongs.length;
  }

  Future<SongPage> querySongs({
    required String directory,
    required int pageIndex,
    required int pageSize,
    String? language,
    String? artist,
    String searchQuery = '',
  }) async {
    final int normalizedPageIndex = pageIndex < 0 ? 0 : pageIndex;
    final int normalizedPageSize = pageSize <= 0 ? 1 : pageSize;
    final String normalizedLanguage = (language ?? '').trim();
    final String normalizedArtist = (artist ?? '').trim();
    final String normalizedQuery = searchQuery.trim().toLowerCase();

    if (_usesIndexedAndroidLibrary(directory)) {
      return _androidStorageDataSource.queryIndexedSongs(
        rootUri: directory,
        language: normalizedLanguage,
        artist: normalizedArtist,
        searchQuery: normalizedQuery,
        pageIndex: normalizedPageIndex,
        pageSize: normalizedPageSize,
      );
    }

    final List<Song> cachedSongs =
        _cachedSongsByDirectory[directory] ??
        await _scanAndCacheDirectory(directory);
    final List<Song> filteredSongs = cachedSongs
        .where((Song song) {
          if (normalizedLanguage.isNotEmpty &&
              !song.languages.contains(normalizedLanguage)) {
            return false;
          }
          if (normalizedArtist.isNotEmpty &&
              !_extractArtistNames(song.artist).contains(normalizedArtist)) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return song.searchIndex.contains(normalizedQuery);
        })
        .toList(growable: false);
    final int start = normalizedPageIndex * normalizedPageSize;
    final int end = (start + normalizedPageSize).clamp(0, filteredSongs.length);
    final List<Song> pageSongs = start >= filteredSongs.length
        ? const <Song>[]
        : filteredSongs.sublist(start, end);
    return SongPage(
      songs: pageSongs,
      totalCount: filteredSongs.length,
      pageIndex: normalizedPageIndex,
      pageSize: normalizedPageSize,
    );
  }

  Future<ArtistPage> queryArtists({
    required String directory,
    required int pageIndex,
    required int pageSize,
    String? language,
    String searchQuery = '',
  }) async {
    final int normalizedPageIndex = pageIndex < 0 ? 0 : pageIndex;
    final int normalizedPageSize = pageSize <= 0 ? 1 : pageSize;
    final String normalizedLanguage = (language ?? '').trim();
    final String normalizedQuery = searchQuery.trim().toLowerCase();

    if (_usesIndexedAndroidLibrary(directory)) {
      return _androidStorageDataSource.queryIndexedArtists(
        rootUri: directory,
        language: normalizedLanguage,
        searchQuery: normalizedQuery,
        pageIndex: normalizedPageIndex,
        pageSize: normalizedPageSize,
      );
    }

    final List<Song> cachedSongs =
        _cachedSongsByDirectory[directory] ??
        await _scanAndCacheDirectory(directory);
    final Map<String, int> songCountByArtist = <String, int>{};
    for (final Song song in cachedSongs) {
      if (normalizedLanguage.isNotEmpty &&
          !song.languages.contains(normalizedLanguage)) {
        continue;
      }
      for (final String artist in _extractArtistNames(song.artist)) {
        songCountByArtist.update(
          artist,
          (int count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final List<Artist> filteredArtists =
        songCountByArtist.entries
            .map(
              (MapEntry<String, int> entry) => Artist(
                name: entry.key,
                songCount: entry.value,
                searchIndex: entry.key.toLowerCase(),
              ),
            )
            .where((Artist artist) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return artist.searchIndex.contains(normalizedQuery);
            })
            .toList(growable: false)
          ..sort(
            (Artist left, Artist right) => left.name.compareTo(right.name),
          );

    final int start = normalizedPageIndex * normalizedPageSize;
    final int end = (start + normalizedPageSize).clamp(
      0,
      filteredArtists.length,
    );
    final List<Artist> pageArtists = start >= filteredArtists.length
        ? const <Artist>[]
        : filteredArtists.sublist(start, end);
    return ArtistPage(
      artists: pageArtists,
      totalCount: filteredArtists.length,
      pageIndex: normalizedPageIndex,
      pageSize: normalizedPageSize,
    );
  }

  Future<List<Song>> _scanAndCacheDirectory(String directory) async {
    await scanLibrary(directory);
    return _cachedSongsByDirectory[directory] ?? const <Song>[];
  }

  bool _usesIndexedAndroidLibrary(String directory) {
    return !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        _androidStorageDataSource.isDocumentTreeUri(directory);
  }

  List<String> _extractArtistNames(String artistDisplayName) {
    final List<String> artists = artistDisplayName
        .split('&')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    if (artists.isEmpty) {
      return <String>[artistDisplayName.trim()];
    }
    return artists;
  }
}
