import '../../../core/models/demo_song.dart';
import 'media_library_data_source.dart';
import 'scan_directory_data_source.dart';

class DemoMediaLibraryRepository {
  DemoMediaLibraryRepository({
    DemoMediaLibraryDataSource? mediaLibraryDataSource,
    DemoScanDirectoryDataSource? scanDirectoryDataSource,
  }) : _mediaLibraryDataSource =
           mediaLibraryDataSource ?? DemoMediaLibraryDataSource(),
       _scanDirectoryDataSource =
           scanDirectoryDataSource ?? DemoScanDirectoryDataSource();

  final DemoMediaLibraryDataSource _mediaLibraryDataSource;
  final DemoScanDirectoryDataSource _scanDirectoryDataSource;

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

  Future<List<DemoSong>> scanLibrary(String directory) async {
    final List<DemoLibrarySong> songs = await _mediaLibraryDataSource
        .scanLibrary(directory);
    return songs
        .map(
          (DemoLibrarySong song) => DemoSong(
            title: song.title,
            artist: song.artist,
            language: song.language,
            searchIndex: song.searchIndex,
            mediaPath: song.mediaPath,
          ),
        )
        .toList(growable: false);
  }
}
