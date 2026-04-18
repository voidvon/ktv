import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/core/models/song_page.dart';
import 'package:maimai_ktv/features/media_library/data/media_index_store.dart';
import 'package:maimai_ktv/features/media_library/data/media_library_data_source.dart';
import 'package:maimai_ktv/features/media_library/data/media_library_repository.dart';

class _FakeMediaLibraryDataSource extends MediaLibraryDataSource {
  _FakeMediaLibraryDataSource(this.songs);

  final List<LibrarySong> songs;
  int scanCallCount = 0;

  @override
  Future<List<LibrarySong>> scanLibrary(
    String rootPath, {
    Map<String, CachedLocalSongFingerprint> cachedFingerprintsByPath =
        const <String, CachedLocalSongFingerprint>{},
  }) async {
    scanCallCount += 1;
    return songs;
  }
}

class _FakeMediaIndexStore extends MediaIndexStore {
  final Map<String, List<Song>> localSongsByRoot = <String, List<Song>>{};
  bool hasConfiguredAggregateSourcesValue = false;

  @override
  Future<Map<String, CachedLocalSongFingerprint>> loadLocalFingerprintCache({
    required String sourceRootId,
  }) async {
    return const <String, CachedLocalSongFingerprint>{};
  }

  @override
  Future<int> replaceLocalSongs({
    required String sourceRootId,
    required List<LibrarySong> songs,
  }) async {
    localSongsByRoot[sourceRootId] = songs
        .map(
          (LibrarySong song) => Song(
            songId: 'local:${song.title}:${song.artist}',
            sourceId: 'local',
            sourceSongId: song.sourceSongId,
            title: song.title,
            artist: song.artist,
            languages: song.languages,
            tags: song.tags,
            searchIndex: song.searchIndex,
            mediaPath: song.mediaPath,
          ),
        )
        .toList(growable: false);
    return songs.length;
  }

  @override
  Future<List<Song>> loadLocalSongs({required String sourceRootId}) async {
    return localSongsByRoot[sourceRootId] ?? const <Song>[];
  }

  @override
  Future<bool> hasConfiguredAggregateSources({
    String? activeLocalRootId,
  }) async {
    return hasConfiguredAggregateSourcesValue;
  }
}

void main() {
  test('scanLibrary caches songs and querySongs applies filters', () async {
    final _FakeMediaLibraryDataSource dataSource = _FakeMediaLibraryDataSource(
      <LibrarySong>[
        const LibrarySong(
          title: 'Blue Sky',
          artist: 'Singer A',
          mediaPath: '/music/blue-sky.mp4',
          fileName: 'Singer A-Blue Sky-English.mp4',
          relativePath: 'Singer A-Blue Sky-English.mp4',
          fileSize: 1,
          modifiedAtMillis: 1,
          sourceFingerprint: 'fp-1',
          extension: '.mp4',
          languages: <String>['English'],
        ),
        const LibrarySong(
          title: '青花瓷',
          artist: '周杰伦',
          mediaPath: '/music/qinghuaci.mp4',
          fileName: '周杰伦-青花瓷-国语.mp4',
          relativePath: '周杰伦-青花瓷-国语.mp4',
          fileSize: 1,
          modifiedAtMillis: 1,
          sourceFingerprint: 'fp-2',
          extension: '.mp4',
          languages: <String>['国语'],
        ),
      ],
    );
    final MediaLibraryRepository repository = MediaLibraryRepository(
      mediaLibraryDataSource: dataSource,
      mediaIndexStore: _FakeMediaIndexStore(),
    );

    expect(await repository.scanLibrary('/music'), 2);

    final SongPage page = await repository.querySongs(
      directory: '/music',
      pageIndex: 0,
      pageSize: 10,
      language: '国语',
      searchQuery: '周杰',
    );

    expect(dataSource.scanCallCount, 1);
    expect(page.totalCount, 1);
    expect(page.songs.single.title, '青花瓷');
  });

  test(
    'hasConfiguredAggregatedSources short-circuits when local directory exists',
    () async {
      final _FakeMediaIndexStore mediaIndexStore = _FakeMediaIndexStore()
        ..hasConfiguredAggregateSourcesValue = false;
      final MediaLibraryRepository repository = MediaLibraryRepository(
        mediaIndexStore: mediaIndexStore,
      );

      expect(
        await repository.hasConfiguredAggregatedSources(
          localDirectory: '/music',
        ),
        isTrue,
      );
      expect(
        await repository.hasConfiguredAggregatedSources(localDirectory: null),
        isFalse,
      );
    },
  );
}
