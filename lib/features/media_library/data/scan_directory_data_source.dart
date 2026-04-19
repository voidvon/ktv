import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_storage_data_source.dart';
import 'ios_local_media_import_data_source.dart';
import 'media_index_store.dart';

class ScanDirectoryDataSource {
  ScanDirectoryDataSource({
    AndroidStorageDataSource? androidStorageDataSource,
    IosLocalMediaImportDataSource? iosLocalMediaImportDataSource,
    MediaIndexStore? mediaIndexStore,
  }) : _androidStorageDataSource =
           androidStorageDataSource ?? AndroidStorageDataSource(),
       _iosLocalMediaImportDataSource =
           iosLocalMediaImportDataSource ?? IosLocalMediaImportDataSource(),
       _mediaIndexStore = mediaIndexStore ?? MediaIndexStore();

  static const MethodChannel _macosChannel = MethodChannel(
    'com.app0122.maimai.app/macos_directory_picker',
  );
  final AndroidStorageDataSource _androidStorageDataSource;
  final IosLocalMediaImportDataSource _iosLocalMediaImportDataSource;
  final MediaIndexStore _mediaIndexStore;

  Future<String?> pickDirectory({String? initialDirectory}) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidStorageDataSource.pickDirectory(
        initialDirectory: initialDirectory,
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      final String? selectedPath = await _macosChannel.invokeMethod<String>(
        'pickDirectory',
        <String, Object?>{'initialDirectory': initialDirectory},
      );
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        debugPrint('macOS directory picker returned no selection');
        return null;
      }
      return selectedPath;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosLocalMediaImportDataSource.importFiles(
        initialDirectory: initialDirectory,
      );
    }

    return getDirectoryPath(initialDirectory: initialDirectory);
  }

  Future<List<XFile>> pickImportFiles({String? initialDirectory}) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError('pickImportFiles is only available on iOS');
    }
    return _iosLocalMediaImportDataSource.pickFiles(
      initialDirectory: initialDirectory,
    );
  }

  Future<String?> importPickedFiles(List<XFile> selectedFiles) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError('importPickedFiles is only available on iOS');
    }
    return _iosLocalMediaImportDataSource.importPickedFiles(selectedFiles);
  }

  Future<bool> ensureDirectoryAccess(String path) {
    return _androidStorageDataSource.ensureDirectoryAccess(path);
  }

  Future<void> clearDirectoryAccess({String? path}) async {
    await _androidStorageDataSource.clearDirectoryAccess(path: path);
    final String? savedPath = await _mediaIndexStore.loadSelectedDirectory();
    final String normalizedTargetPath = (path ?? '').trim();
    if (normalizedTargetPath.isEmpty || savedPath == normalizedTargetPath) {
      await _mediaIndexStore.clearSelectedDirectory();
    }
  }

  Future<void> saveSelectedDirectory(String path) {
    return _mediaIndexStore.saveSelectedDirectory(path);
  }

  Future<String?> loadSelectedDirectory() {
    return _mediaIndexStore.loadSelectedDirectory();
  }
}
