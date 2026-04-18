import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/core/models/artist_page.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/core/models/song_page.dart';
import 'package:maimai_ktv/features/media_library/data/android_storage_data_source.dart';
import 'package:maimai_ktv/features/media_library/data/media_index_store.dart';
import 'package:maimai_ktv/features/media_library/data/scan_directory_data_source.dart';

void main() {
  test('save and load selected directory use sqlite-backed shared store', () async {
    final MediaIndexStore store = MediaIndexStore();
    addTearDown(store.close);
    final ScanDirectoryDataSource dataSource = ScanDirectoryDataSource(
      androidStorageDataSource: FakeAndroidStorageDataSource(),
      mediaIndexStore: store,
    );

    await dataSource.saveSelectedDirectory('C:/Songs');

    expect(await dataSource.loadSelectedDirectory(), 'C:/Songs');
  });

  test('clearDirectoryAccess clears persisted directory when matching saved path', () async {
    final MediaIndexStore store = MediaIndexStore();
    addTearDown(store.close);
    final FakeAndroidStorageDataSource androidStorageDataSource =
        FakeAndroidStorageDataSource();
    final ScanDirectoryDataSource dataSource = ScanDirectoryDataSource(
      androidStorageDataSource: androidStorageDataSource,
      mediaIndexStore: store,
    );
    await dataSource.saveSelectedDirectory('content://library/tree');

    await dataSource.clearDirectoryAccess(path: 'content://library/tree');

    expect(await dataSource.loadSelectedDirectory(), isNull);
    expect(
      androidStorageDataSource.clearedPaths,
      <String?>['content://library/tree'],
    );
  });

  test('clearDirectoryAccess preserves persisted directory when clearing other path', () async {
    final MediaIndexStore store = MediaIndexStore();
    addTearDown(store.close);
    final ScanDirectoryDataSource dataSource = ScanDirectoryDataSource(
      androidStorageDataSource: FakeAndroidStorageDataSource(),
      mediaIndexStore: store,
    );
    await dataSource.saveSelectedDirectory('C:/Songs');

    await dataSource.clearDirectoryAccess(path: 'D:/Other');

    expect(await dataSource.loadSelectedDirectory(), 'C:/Songs');
  });
}

class FakeAndroidStorageDataSource extends AndroidStorageDataSource {
  final List<String?> clearedPaths = <String?>[];

  @override
  Future<void> clearDirectoryAccess({String? path}) async {
    clearedPaths.add(path);
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
      artists: const [],
      totalCount: 0,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }
}

