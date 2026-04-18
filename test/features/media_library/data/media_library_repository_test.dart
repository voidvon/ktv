import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/core/models/artist.dart';
import 'package:maimai_ktv/core/models/artist_page.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/core/models/song_identity.dart';
import 'package:maimai_ktv/core/models/song_page.dart';
import 'package:maimai_ktv/features/media_library/data/android_storage_data_source.dart';
import 'package:maimai_ktv/features/media_library/data/media_index_store.dart';
import 'package:maimai_ktv/features/media_library/data/media_library_repository.dart';
import 'package:maimai_ktv/features/media_library/data/media_library_data_source.dart';

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
                title: '闈掕姳鐡?,
                artist: '鍛ㄦ澃浼?,
                mediaPath: '/media/闈掕姳鐡?mp4',
                fileName: '鍛ㄦ澃浼?- 闈掕姳鐡?mp4',
                relativePath: '闈掕姳鐡?mp4',
                fileSize: 1024,
                modifiedAtMillis: 1710000000000,
                sourceFingerprint: 'content:1024:aaaa',
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
    expect(androidStorageDataSource.scanCalls, isEmpty);
  });

  test(
    'content uri scan is persisted into unified local index on Android',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final FakeMediaLibraryDataSource localDataSource =
          FakeMediaLibraryDataSource(
            songsByDirectory: <String, List<LibrarySong>>{},
          );
      final FakeAndroidStorageDataSource androidStorageDataSource =
          FakeAndroidStorageDataSource(
            scannedSongs: <String, List<AndroidLibrarySong>>{
              'content://library/tree': <AndroidLibrarySong>[
                const AndroidLibrarySong(
                  title: '娴烽様澶╃┖',
                  artist: 'Beyond',
                  mediaPath: 'content://library/tree/song-1',
                  fileName: 'Beyond - 娴烽様澶╃┖.mp4',
                  extension: 'mp4',
                ),
              ],
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

      expect(count, 1);
      expect(localDataSource.scannedDirectories, isEmpty);
      expect(androidStorageDataSource.scanCalls, <String>[
        'content://library/tree',
      ]);
      expect(songPage.songs.single.title, '娴烽様澶╃┖');
      final SongPage aggregatePage = await repository.queryAggregatedSongs(
        pageIndex: 0,
        pageSize: 8,
        localDirectory: 'content://library/tree',
      );
      expect(aggregatePage.songs.single.title, '娴烽様澶╃┖');
    },
  );

  test('getSongsByIds resolves exact songs beyond 10000 entries', () async {
    final List<LibrarySong> librarySongs = List<LibrarySong>.generate(
      10050,
      (int index) => LibrarySong(
        title: '姝屾洸$index',
        artist: '姝屾墜',
        mediaPath: '/media/$index.mp4',
        fileName: '姝屾墜 - 姝屾洸$index.mp4',
        relativePath: '$index.mp4',
        fileSize: 2048 + index,
        modifiedAtMillis: 1710000000000 + index,
        sourceFingerprint: 'content:${2048 + index}:$index',
        extension: 'mp4',
      ),
      growable: false,
    );
    final FakeMediaLibraryDataSource localDataSource =
        FakeMediaLibraryDataSource(
          songsByDirectory: <String, List<LibrarySong>>{'/media': librarySongs},
        );
    final MediaLibraryRepository repository = MediaLibraryRepository(
      mediaLibraryDataSource: localDataSource,
      androidStorageDataSource: FakeAndroidStorageDataSource(),
    );
    await repository.scanLibrary('/media');

    final List<Song> songs = await repository.getSongsByIds(
      directory: '/media',
      songIds: <String>[buildAggregateSongId(title: '姝屾洸10049', artist: '姝屾墜')],
    );

    expect(songs, hasLength(1));
    expect(songs.single.title, '姝屾洸10049');
  });

  test(
    'local songs keep aggregate id and file-derived source song id',
    () async {
      final FakeMediaLibraryDataSource localDataSource =
          FakeMediaLibraryDataSource(
            songsByDirectory: <String, List<LibrarySong>>{
              '/media': <LibrarySong>[
                const LibrarySong(
                  title: '鍚屼竴棣栨瓕',
                  artist: '鍚屼竴姝屾墜',
                  mediaPath: '/media/a.mp4',
                  fileName: '鍚屼竴姝屾墜 - 鍚屼竴棣栨瓕.mp4',
                  relativePath: 'a.mp4',
                  fileSize: 100,
                  modifiedAtMillis: 1710000000001,
                  sourceFingerprint: 'content:100:aaaa',
                  extension: 'mp4',
                ),
                const LibrarySong(
                  title: '鍚屼竴棣栨瓕',
                  artist: '鍚屼竴姝屾墜',
                  mediaPath: '/media/b.mp4',
                  fileName: '鍚屼竴姝屾墜 - 鍚屼竴棣栨瓕.mp4',
                  relativePath: 'b.mp4',
                  fileSize: 100,
                  modifiedAtMillis: 1710000000002,
                  sourceFingerprint: 'content:100:bbbb',
                  extension: 'mp4',
                ),
              ],
            },
          );
      final MediaLibraryRepository repository = MediaLibraryRepository(
        mediaLibraryDataSource: localDataSource,
        androidStorageDataSource: FakeAndroidStorageDataSource(),
      );

      await repository.scanLibrary('/media');
      final List<Song> songs = await repository.loadAllSongs(
        directory: '/media',
      );

      expect(songs, hasLength(2));
      expect(songs.first.songId, songs.last.songId);
      expect(songs.first.sourceSongId, isNot(songs.last.sourceSongId));
    },
  );

  test('local source song id stays stable after rename', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'ktv_song_id_',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final File originalFile = File('${root.path}/姝屾墜 - 鍚屼竴棣栨瓕.mp4');
    final List<int> bytes = List<int>.generate(
      200000,
      (int index) => index % 251,
      growable: false,
    );
    await originalFile.writeAsBytes(bytes, flush: true);

    final MediaLibraryDataSource dataSource = MediaLibraryDataSource();
    final List<LibrarySong> firstScan = await dataSource.scanLibrary(root.path);
    expect(firstScan, hasLength(1));

    await originalFile.rename('${root.path}/宸叉敼鍚?mp4');
    final List<LibrarySong> secondScan = await dataSource.scanLibrary(
      root.path,
    );
    expect(secondScan, hasLength(1));
    expect(firstScan.single.sourceSongId, secondScan.single.sourceSongId);
  });

  test(
    'local filename parsing extracts language and tags from suffix',
    () async {
      final Directory root = await Directory.systemTemp.createTemp(
        'ktv_parse_keywords_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final File file = File('${root.path}/鍛ㄦ澃浼?闈掕姳鐡?鍥借-娴佽.mp4');
      await file.writeAsBytes(const <int>[1, 2, 3], flush: true);

      final MediaLibraryDataSource dataSource = MediaLibraryDataSource();
      final List<LibrarySong> songs = await dataSource.scanLibrary(root.path);

      expect(songs, hasLength(1));
      expect(songs.single.artist, '鍛ㄦ澃浼?);
      expect(songs.single.title, '闈掕姳鐡?);
      expect(songs.single.languages, <String>['鍥借']);
      expect(songs.single.tags, <String>['娴佽']);
    },
  );

  test('local filename parsing respects hyphenated artist whitelist', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'ktv_parse_whitelist_',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final File file = File('${root.path}/A-Lin-Love-Love-Love-鍥借-娴佽.mp4');
    await file.writeAsBytes(const <int>[1, 2, 3], flush: true);

    final MediaLibraryDataSource dataSource = MediaLibraryDataSource();
    final List<LibrarySong> songs = await dataSource.scanLibrary(root.path);

    expect(songs, hasLength(1));
    expect(songs.single.artist, 'A-Lin');
    expect(songs.single.title, 'Love-Love-Love');
    expect(songs.single.languages, <String>['鍥借']);
    expect(songs.single.tags, <String>['娴佽']);
  });

  test('aggregated song queries filter and paginate in sqlite', () async {
    final MediaLibraryRepository repository = MediaLibraryRepository(
      mediaLibraryDataSource: FakeMediaLibraryDataSource(
        songsByDirectory: <String, List<LibrarySong>>{
          '/media': <LibrarySong>[
            const TestLibrarySong(
              title: '鐝婄憵娴?,
              artist: '鍛ㄦ澃浼?& Lara',
              mediaPath: '/media/1.mp4',
              fileName: '鍛ㄦ澃浼?& Lara - 鐝婄憵娴?mp4',
              relativePath: '1.mp4',
              fileSize: 1001,
              modifiedAtMillis: 1710000000001,
              sourceFingerprint: 'content:1001:a',
              languages: <String>['鍥借'],
              searchIndex: 'shanhuhai zhoujielun lara',
              extension: 'mp4',
            ),
            const TestLibrarySong(
              title: '澶滄洸',
              artist: '鍛ㄦ澃浼?,
              mediaPath: '/media/2.mp4',
              fileName: '鍛ㄦ澃浼?- 澶滄洸.mp4',
              relativePath: '2.mp4',
              fileSize: 1002,
              modifiedAtMillis: 1710000000002,
              sourceFingerprint: 'content:1002:b',
              languages: <String>['鍥借'],
              searchIndex: 'yequ zhoujielun',
              extension: 'mp4',
            ),
            const TestLibrarySong(
              title: '娴烽様澶╃┖',
              artist: 'Beyond',
              mediaPath: '/media/3.mp4',
              fileName: 'Beyond - 娴烽様澶╃┖.mp4',
              relativePath: '3.mp4',
              fileSize: 1003,
              modifiedAtMillis: 1710000000003,
              sourceFingerprint: 'content:1003:c',
              languages: <String>['绮よ'],
              searchIndex: 'haikuotiankong beyond',
              extension: 'mp4',
            ),
          ],
        },
      ),
      androidStorageDataSource: FakeAndroidStorageDataSource(),
    );
    addTearDown(repository.mediaIndexStore.close);

    await repository.scanLibrary('/media');

    final SongPage page = await repository.queryAggregatedSongs(
      pageIndex: 0,
      pageSize: 1,
      localDirectory: '/media',
      language: '鍥借',
      artist: '鍛ㄦ澃浼?,
    );
    final SongPage secondPage = await repository.queryAggregatedSongs(
      pageIndex: 1,
      pageSize: 1,
      localDirectory: '/media',
      language: '鍥借',
      artist: '鍛ㄦ澃浼?,
    );

    expect(page.totalCount, 2);
    expect(page.songs.single.title, '澶滄洸');
    expect(secondPage.songs.single.title, '鐝婄憵娴?);
  });

  test(
    'aggregated artist queries split artist names and getSongsByIds keeps requested order',
    () async {
      final MediaLibraryRepository repository = MediaLibraryRepository(
        mediaLibraryDataSource: FakeMediaLibraryDataSource(
          songsByDirectory: <String, List<LibrarySong>>{
            '/media': <LibrarySong>[
              const TestLibrarySong(
                title: '鐝婄憵娴?,
                artist: '鍛ㄦ澃浼?& Lara',
                mediaPath: '/media/1.mp4',
                fileName: '鍛ㄦ澃浼?& Lara - 鐝婄憵娴?mp4',
                relativePath: '1.mp4',
                fileSize: 1001,
                modifiedAtMillis: 1710000000001,
                sourceFingerprint: 'content:1001:a',
                languages: <String>['鍥借'],
                searchIndex: 'shanhuhai zhoujielun lara',
                extension: 'mp4',
              ),
              const TestLibrarySong(
                title: '绠€鍗曠埍',
                artist: '鍛ㄦ澃浼?,
                mediaPath: '/media/2.mp4',
                fileName: '鍛ㄦ澃浼?- 绠€鍗曠埍.mp4',
                relativePath: '2.mp4',
                fileSize: 1002,
                modifiedAtMillis: 1710000000002,
                sourceFingerprint: 'content:1002:b',
                languages: <String>['鍥借'],
                searchIndex: 'jiandanai zhoujielun',
                extension: 'mp4',
              ),
            ],
          },
        ),
        androidStorageDataSource: FakeAndroidStorageDataSource(),
      );
      addTearDown(repository.mediaIndexStore.close);

      await repository.scanLibrary('/media');

      final ArtistPage artistPage = await repository.queryAggregatedArtists(
        pageIndex: 0,
        pageSize: 10,
        localDirectory: '/media',
        searchQuery: 'lara',
      );
      final List<Song> songs = await repository.getAggregatedSongsByIds(
        localDirectory: '/media',
        songIds: <String>[
          buildAggregateSongId(title: '绠€鍗曠埍', artist: '鍛ㄦ澃浼?),
          buildAggregateSongId(title: '鐝婄憵娴?, artist: '鍛ㄦ澃浼?& Lara'),
        ],
      );

      expect(artistPage.totalCount, 1);
      expect(artistPage.artists.single.name, 'Lara');
      expect(artistPage.artists.single.songCount, 1);
      expect(songs.map((Song song) => song.title).toList(), <String>[
        '绠€鍗曠埍',
        '鐝婄憵娴?,
      ]);
    },
  );

  test('aggregated songs self-heal when aggregate items are missing', () async {
    final MediaIndexStore store = MediaIndexStore();
    addTearDown(store.close);

    final MediaLibraryRepository seedRepository = MediaLibraryRepository(
      mediaLibraryDataSource: FakeMediaLibraryDataSource(
        songsByDirectory: <String, List<LibrarySong>>{
          '/media': <LibrarySong>[
            const TestLibrarySong(
              title: '闈掕姳鐡?,
              artist: '鍛ㄦ澃浼?,
              mediaPath: '/media/1.mp4',
              fileName: '鍛ㄦ澃浼?- 闈掕姳鐡?mp4',
              relativePath: '1.mp4',
              fileSize: 1001,
              modifiedAtMillis: 1710000000001,
              sourceFingerprint: 'content:1001:a',
              languages: <String>['鍥借'],
              searchIndex: 'qinghuaci zhoujielun',
              extension: 'mp4',
            ),
          ],
        },
      ),
      androidStorageDataSource: FakeAndroidStorageDataSource(),
      mediaIndexStore: store,
    );
    await seedRepository.scanLibrary('/media');

    final db = await store.database;
    await db.delete(MediaIndexStore.aggregateSongItemsTable);

    final MediaLibraryRepository repository = MediaLibraryRepository(
      mediaLibraryDataSource: FakeMediaLibraryDataSource(
        songsByDirectory: const <String, List<LibrarySong>>{},
      ),
      androidStorageDataSource: FakeAndroidStorageDataSource(),
      mediaIndexStore: store,
    );

    final SongPage localPage = await repository.querySongs(
      directory: '/media',
      pageIndex: 0,
      pageSize: 8,
    );
    final SongPage aggregatePage = await repository.queryAggregatedSongs(
      pageIndex: 0,
      pageSize: 8,
      localDirectory: '/media',
    );

    expect(localPage.totalCount, 1);
    expect(localPage.songs.single.title, '闈掕姳鐡?);
    expect(aggregatePage.totalCount, 1);
    expect(aggregatePage.songs.single.title, '闈掕姳鐡?);
  });
}

Song song({required String title, required String artist}) {
  return Song(
    songId: buildAggregateSongId(title: title, artist: artist),
    sourceId: 'local',
    sourceSongId: buildLocalSourceSongId(
      fingerprint: buildLocalMetadataFingerprint(locator: '/tmp/$title.mp4'),
    ),
    title: title,
    artist: artist,
    languages: const <String>['鍏跺畠'],
    searchIndex: '$title $artist'.toLowerCase(),
    mediaPath: '/tmp/$title.mp4',
  );
}

class FakeMediaLibraryDataSource extends MediaLibraryDataSource {
  FakeMediaLibraryDataSource({required this.songsByDirectory});

  final Map<String, List<LibrarySong>> songsByDirectory;
  final List<String> scannedDirectories = <String>[];

  @override
  Future<List<LibrarySong>> scanLibrary(
    String rootPath, {
    Map<String, CachedLocalSongFingerprint> cachedFingerprintsByPath =
        const <String, CachedLocalSongFingerprint>{},
  }) async {
    scannedDirectories.add(rootPath);
    return songsByDirectory[rootPath] ?? const <LibrarySong>[];
  }
}

class TestLibrarySong extends LibrarySong {
  const TestLibrarySong({
    required super.title,
    required super.artist,
    required super.mediaPath,
    required super.fileName,
    required super.relativePath,
    required super.fileSize,
    required super.modifiedAtMillis,
    required super.sourceFingerprint,
    required super.extension,
    super.languages = const <String>['鍏跺畠'],
    super.tags = const <String>[],
    required this.searchIndex,
  });

  @override
  final String searchIndex;
}

class FakeAndroidStorageDataSource extends AndroidStorageDataSource {
  FakeAndroidStorageDataSource({
    Map<String, List<AndroidLibrarySong>>? scannedSongs,
  }) : _scannedSongs = scannedSongs ?? <String, List<AndroidLibrarySong>>{};

  final Map<String, List<AndroidLibrarySong>> _scannedSongs;
  final List<String> scanCalls = <String>[];

  @override
  Future<List<AndroidLibrarySong>> scanLibrary(String rootUri) async {
    scanCalls.add(rootUri);
    return _scannedSongs[rootUri] ?? const <AndroidLibrarySong>[];
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
    return SongPage(
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
    return ArtistPage(
      artists: const <Artist>[],
      totalCount: 0,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }
}

