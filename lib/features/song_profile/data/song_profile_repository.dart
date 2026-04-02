import 'package:sqflite/sqflite.dart';

import '../../../core/models/song.dart';
import '../../../core/models/song_page.dart';
import 'song_profile_database.dart';

class SongProfileRepository {
  SongProfileRepository({SongProfileDatabase? database})
    : _database = database ?? SongProfileDatabase();

  final SongProfileDatabase _database;

  static const String _listSeparator = '\n';

  Future<void> close() => _database.close();

  Future<bool> toggleFavorite({
    required Song song,
    required String directoryPath,
  }) async {
    final Database database = await _database.database;
    return database.transaction((Transaction txn) async {
      final Map<String, Object?> values = await _loadOrCreateRow(
        txn,
        song: song,
        directoryPath: directoryPath,
      );
      final bool nextIsFavorite = !_readBool(
        values[SongProfileDatabase.columnIsFavorite],
      );
      final int now = DateTime.now().millisecondsSinceEpoch;
      values[SongProfileDatabase.columnIsFavorite] = nextIsFavorite ? 1 : 0;
      values[SongProfileDatabase.columnFavoritedAt] = nextIsFavorite
          ? now
          : null;
      values[SongProfileDatabase.columnUpdatedAt] = now;
      await txn.insert(
        SongProfileDatabase.tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return nextIsFavorite;
    });
  }

  Future<void> recordSongRequested({
    required Song song,
    required String directoryPath,
  }) async {
    final Database database = await _database.database;
    await database.transaction((Transaction txn) async {
      final Map<String, Object?> values = await _loadOrCreateRow(
        txn,
        song: song,
        directoryPath: directoryPath,
      );
      final int now = DateTime.now().millisecondsSinceEpoch;
      values[SongProfileDatabase.columnLastRequestedAt] = now;
      values[SongProfileDatabase.columnUpdatedAt] = now;
      await txn.insert(
        SongProfileDatabase.tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> recordSongStarted({
    required Song song,
    required String directoryPath,
  }) async {
    final Database database = await _database.database;
    await database.transaction((Transaction txn) async {
      final Map<String, Object?> values = await _loadOrCreateRow(
        txn,
        song: song,
        directoryPath: directoryPath,
      );
      final int now = DateTime.now().millisecondsSinceEpoch;
      values[SongProfileDatabase.columnPlayCount] =
          _readInt(values[SongProfileDatabase.columnPlayCount]) + 1;
      values[SongProfileDatabase.columnLastPlayedAt] = now;
      values[SongProfileDatabase.columnUpdatedAt] = now;
      await txn.insert(
        SongProfileDatabase.tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<Set<String>> loadFavoriteMediaPaths(Iterable<Song> songs) async {
    final List<String> mediaPaths = songs
        .map((Song song) => song.mediaPath)
        .where((String mediaPath) => mediaPath.isNotEmpty)
        .toList(growable: false);
    if (mediaPaths.isEmpty) {
      return <String>{};
    }

    final Database database = await _database.database;
    final String placeholders = List<String>.filled(
      mediaPaths.length,
      '?',
    ).join(', ');
    final List<Map<String, Object?>> rows = await database.rawQuery('''
      SELECT ${SongProfileDatabase.columnMediaPath}
      FROM ${SongProfileDatabase.tableName}
      WHERE ${SongProfileDatabase.columnMediaPath} IN ($placeholders)
        AND ${SongProfileDatabase.columnIsFavorite} = 1
      ''', mediaPaths);
    return rows
        .map(
          (Map<String, Object?> row) =>
              row[SongProfileDatabase.columnMediaPath]?.toString() ?? '',
        )
        .where((String mediaPath) => mediaPath.isNotEmpty)
        .toSet();
  }

  Future<SongPage> queryFavoriteSongs({
    required String directory,
    required int pageIndex,
    required int pageSize,
    String? language,
    String? artist,
    String searchQuery = '',
  }) {
    return _querySongs(
      pageIndex: pageIndex,
      pageSize: pageSize,
      language: language,
      artist: artist,
      searchQuery: searchQuery,
      whereClause:
          '${SongProfileDatabase.columnDirectoryPath} = ? AND ${SongProfileDatabase.columnIsFavorite} = 1',
      whereArgs: <Object?>[directory],
      orderBy:
          '${SongProfileDatabase.columnFavoritedAt} DESC, ${SongProfileDatabase.columnUpdatedAt} DESC, ${SongProfileDatabase.columnTitle} COLLATE NOCASE ASC',
    );
  }

  Future<SongPage> queryFrequentSongs({
    required String directory,
    required int pageIndex,
    required int pageSize,
    String? language,
    String? artist,
    String searchQuery = '',
  }) {
    return _querySongs(
      pageIndex: pageIndex,
      pageSize: pageSize,
      language: language,
      artist: artist,
      searchQuery: searchQuery,
      whereClause:
          '${SongProfileDatabase.columnDirectoryPath} = ? AND ${SongProfileDatabase.columnPlayCount} > 0',
      whereArgs: <Object?>[directory],
      orderBy:
          '${SongProfileDatabase.columnPlayCount} DESC, ${SongProfileDatabase.columnLastPlayedAt} DESC, ${SongProfileDatabase.columnUpdatedAt} DESC, ${SongProfileDatabase.columnTitle} COLLATE NOCASE ASC',
    );
  }

  Future<SongPage> _querySongs({
    required int pageIndex,
    required int pageSize,
    required String? language,
    required String? artist,
    required String searchQuery,
    required String whereClause,
    required List<Object?> whereArgs,
    required String orderBy,
  }) async {
    final int normalizedPageIndex = pageIndex < 0 ? 0 : pageIndex;
    final int normalizedPageSize = pageSize <= 0 ? 1 : pageSize;
    final String normalizedLanguage = (language ?? '').trim();
    final String normalizedArtist = (artist ?? '').trim();
    final String normalizedSearchQuery = searchQuery.trim().toLowerCase();
    final Database database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      SongProfileDatabase.tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    final List<Song> filteredSongs = rows
        .map(_mapRowToSong)
        .where((Song song) {
          if (song.mediaPath.isEmpty) {
            return false;
          }
          if (normalizedLanguage.isNotEmpty &&
              !song.languages.contains(normalizedLanguage)) {
            return false;
          }
          if (normalizedArtist.isNotEmpty &&
              !_extractArtistNames(song.artist).contains(normalizedArtist)) {
            return false;
          }
          if (normalizedSearchQuery.isEmpty) {
            return true;
          }
          return song.searchIndex.contains(normalizedSearchQuery);
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

  Future<Map<String, Object?>> _loadOrCreateRow(
    DatabaseExecutor executor, {
    required Song song,
    required String directoryPath,
  }) async {
    final List<Map<String, Object?>> rows = await executor.query(
      SongProfileDatabase.tableName,
      where: '${SongProfileDatabase.columnMediaPath} = ?',
      whereArgs: <Object?>[song.mediaPath],
      limit: 1,
    );
    final int now = DateTime.now().millisecondsSinceEpoch;
    final Map<String, Object?> values = <String, Object?>{
      SongProfileDatabase.columnMediaPath: song.mediaPath,
      SongProfileDatabase.columnDirectoryPath: directoryPath,
      SongProfileDatabase.columnTitle: song.title,
      SongProfileDatabase.columnArtist: song.artist,
      SongProfileDatabase.columnLanguages: _encodeList(song.languages),
      SongProfileDatabase.columnTags: _encodeList(song.tags),
      SongProfileDatabase.columnSearchIndex: song.searchIndex,
      SongProfileDatabase.columnIsFavorite: 0,
      SongProfileDatabase.columnFavoritedAt: null,
      SongProfileDatabase.columnPlayCount: 0,
      SongProfileDatabase.columnLastPlayedAt: null,
      SongProfileDatabase.columnLastRequestedAt: null,
      SongProfileDatabase.columnUpdatedAt: now,
    };
    if (rows.isNotEmpty) {
      values.addAll(rows.first);
    }
    values.addAll(<String, Object?>{
      SongProfileDatabase.columnDirectoryPath: directoryPath,
      SongProfileDatabase.columnTitle: song.title,
      SongProfileDatabase.columnArtist: song.artist,
      SongProfileDatabase.columnLanguages: _encodeList(song.languages),
      SongProfileDatabase.columnTags: _encodeList(song.tags),
      SongProfileDatabase.columnSearchIndex: song.searchIndex,
    });
    return values;
  }

  Song _mapRowToSong(Map<String, Object?> row) {
    return Song(
      title: row[SongProfileDatabase.columnTitle]?.toString() ?? '未知歌曲',
      artist: row[SongProfileDatabase.columnArtist]?.toString() ?? '未识别歌手',
      languages: _decodeList(row[SongProfileDatabase.columnLanguages]),
      tags: _decodeList(row[SongProfileDatabase.columnTags]),
      searchIndex: row[SongProfileDatabase.columnSearchIndex]?.toString() ?? '',
      mediaPath: row[SongProfileDatabase.columnMediaPath]?.toString() ?? '',
    );
  }

  String _encodeList(List<String> values) => values.join(_listSeparator);

  List<String> _decodeList(Object? rawValue) {
    final String serialized = rawValue?.toString() ?? '';
    if (serialized.isEmpty) {
      return const <String>[];
    }
    return serialized
        .split(_listSeparator)
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  int _readInt(Object? rawValue) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    return int.tryParse(rawValue?.toString() ?? '') ?? 0;
  }

  bool _readBool(Object? rawValue) => _readInt(rawValue) != 0;

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
