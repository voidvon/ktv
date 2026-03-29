import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'android_storage_data_source.dart';

class DemoScanDirectoryDataSource {
  final DemoAndroidStorageDataSource _androidStorageDataSource =
      DemoAndroidStorageDataSource();

  Future<String?> pickDirectory({String? initialDirectory}) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidStorageDataSource.pickDirectory(
        initialDirectory: initialDirectory,
      );
    }

    return getDirectoryPath(initialDirectory: initialDirectory);
  }

  Future<bool> ensureDirectoryAccess(String path) {
    return _androidStorageDataSource.ensureDirectoryAccess(path);
  }

  Future<void> clearDirectoryAccess({String? path}) {
    return _androidStorageDataSource.clearDirectoryAccess(path: path);
  }

  Future<void> saveSelectedDirectory(String path) {
    return _androidStorageDataSource.saveSelectedDirectory(path);
  }

  Future<String?> loadSelectedDirectory() {
    return _androidStorageDataSource.loadSelectedDirectory();
  }
}
