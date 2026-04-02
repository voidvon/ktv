import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ktv2_example/core/models/artist.dart';
import 'package:ktv2_example/core/models/artist_page.dart';
import 'package:ktv2_example/core/models/song.dart';
import 'package:ktv2_example/core/models/song_page.dart';
import 'package:ktv2_example/features/media_library/data/android_storage_data_source.dart';
import 'package:ktv2_example/features/media_library/data/media_library_repository.dart';
import 'package:ktv2_example/features/media_library/data/media_library_data_source.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('scanLibrary uses local data source for file paths', () async {
    final FakeMediaLibraryDataSource localDataSource =
        FakeMediaLibraryDataSource(
          songsByDirectory: <String, List<LibrarySong>>{
            '/media': <LibrarySong>[
              const LibrarySong(
                title: '青花瓷',
                artist: '周杰伦',
                mediaPath: '/media/青花瓷.mp4',
                fileName: '周杰伦 - 青花瓷.mp4',
                extension: 'mp4',
              ),
            ],
          },
        );
    final FakeAndroidStorageDataSource androidStorageDataSource =
        FakeAndroidStorageDataSource();
    final MediaLibraryRepository repository = MediaLibraryRepository(
      mediaLibraryDataSource: localDataSource,
      androidStorageDataSource: androidStorageDataSource,
    );

    final int count = await repository.scanLibrary('/media');

    expect(count, 1);
    expect(localDataSource.scannedDirectories, <String>['/media']);
    expect(androidStorageDataSource.scanIntoIndexCalls, isEmpty);
  });

  test('content uri uses indexed android source on Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final FakeMediaLibraryDataSource localDataSource =
        FakeMediaLibraryDataSource(
          songsByDirectory: <String, List<LibrarySong>>{},
        );
    final FakeAndroidStorageDataSource androidStorageDataSource =
        FakeAndroidStorageDataSource(
          scanCounts: <String, int>{'content://library/tree': 3},
          songPages: <String, SongPage>{
            'content://library/tree': SongPage(
              songs: <Song>[song(title: '海阔天空', artist: 'Beyond')],
              totalCount: 1,
              pageIndex: 0,
              pageSize: 8,
            ),
          },
          artistPages: <String, ArtistPage>{
            'content://library/tree': const ArtistPage(
              artists: <Artist>[],
              totalCount: 0,
              pageIndex: 0,
              pageSize: 8,
            ),
          },
        );
    final MediaLibraryRepository repository = MediaLibraryRepository(
      mediaLibraryDataSource: localDataSource,
      androidStorageDataSource: androidStorageDataSource,
    );

    final int count = await repository.scanLibrary('content://library/tree');
    final SongPage songPage = await repository.querySongs(
      directory: 'content://library/tree',
      pageIndex: 0,
      pageSize: 8,
    );

    expect(count, 3);
    expect(localDataSource.scannedDirectories, isEmpty);
    expect(androidStorageDataSource.scanIntoIndexCalls, <String>[
      'content://library/tree',
    ]);
    expect(songPage.songs.single.title, '海阔天空');
    expect(androidStorageDataSource.querySongCalls, <String>[
      'content://library/tree',
    ]);
  });
}

Song song({required String title, required String artist}) {
  return Song(
    title: title,
    artist: artist,
    languages: const <String>['其它'],
    searchIndex: '$title $artist'.toLowerCase(),
    mediaPath: '/tmp/$title.mp4',
  );
}

class FakeMediaLibraryDataSource extends MediaLibraryDataSource {
  FakeMediaLibraryDataSource({required this.songsByDirectory});

  final Map<String, List<LibrarySong>> songsByDirectory;
  final List<String> scannedDirectories = <String>[];

  @override
  Future<List<LibrarySong>> scanLibrary(String rootPath) async {
    scannedDirectories.add(rootPath);
    return songsByDirectory[rootPath] ?? const <LibrarySong>[];
  }
}

class FakeAndroidStorageDataSource extends AndroidStorageDataSource {
  FakeAndroidStorageDataSource({
    Map<String, int>? scanCounts,
    Map<String, SongPage>? songPages,
    Map<String, ArtistPage>? artistPages,
  }) : _scanCounts = scanCounts ?? <String, int>{},
       _songPages = songPages ?? <String, SongPage>{},
       _artistPages = artistPages ?? <String, ArtistPage>{};

  final Map<String, int> _scanCounts;
  final Map<String, SongPage> _songPages;
  final Map<String, ArtistPage> _artistPages;
  final List<String> scanIntoIndexCalls = <String>[];
  final List<String> querySongCalls = <String>[];

  @override
  Future<int> scanLibraryIntoIndex(String rootUri) async {
    scanIntoIndexCalls.add(rootUri);
    return _scanCounts[rootUri] ?? 0;
  }

  @override
  Future<SongPage> queryIndexedSongs({
    required String rootUri,
    required int pageIndex,
    required int pageSize,
    String language = '',
    String artist = '',
    String searchQuery = '',
  }) async {
    querySongCalls.add(rootUri);
    return _songPages[rootUri] ??
        SongPage(
          songs: const <Song>[],
          totalCount: 0,
          pageIndex: pageIndex,
          pageSize: pageSize,
        );
  }

  @override
  Future<ArtistPage> queryIndexedArtists({
    required String rootUri,
    required int pageIndex,
    required int pageSize,
    String language = '',
    String searchQuery = '',
  }) async {
    return _artistPages[rootUri] ??
        ArtistPage(
          artists: const <Artist>[],
          totalCount: 0,
          pageIndex: pageIndex,
          pageSize: pageSize,
        );
  }
}
