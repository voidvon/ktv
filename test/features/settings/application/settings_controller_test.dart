import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/media_library_repository.dart';
import 'package:maimai_ktv/features/media_library/data/scan_directory_data_source.dart';
import 'package:maimai_ktv/features/settings/application/settings_controller.dart';

import '../../../test_support/ktv_test_doubles.dart';

void main() {
  test('pickDirectory updates selected path when access is granted', () async {
    final _FakePickerScanDirectoryDataSource dataSource =
        _FakePickerScanDirectoryDataSource(
          pickedDirectory: '/media',
          accessibleDirectories: <String>{'/media'},
        );
    final SettingsController controller = SettingsController(
      mediaLibraryRepository: MediaLibraryRepository(
        scanDirectoryDataSource: dataSource,
        mediaIndexStore: FakeMediaIndexStore(),
      ),
      initialDirectoryPath: '/initial',
    );

    final String? directory = await controller.pickDirectory();

    expect(directory, '/media');
    expect(controller.currentDirectoryPath, '/media');
    expect(controller.errorMessage, isNull);
    expect(controller.isPickingDirectory, isFalse);
    expect(dataSource.requestedInitialDirectory, '/initial');
  });

  test('pickDirectory reports missing access authorization', () async {
    final SettingsController controller = SettingsController(
      mediaLibraryRepository: MediaLibraryRepository(
        scanDirectoryDataSource: _FakePickerScanDirectoryDataSource(
          pickedDirectory: '/media',
        ),
        mediaIndexStore: FakeMediaIndexStore(),
      ),
    );

    final String? directory = await controller.pickDirectory();

    expect(directory, isNull);
    expect(controller.currentDirectoryPath, isNull);
    expect(controller.errorMessage, contains('读取授权'));
  });

  test('pickDirectory exposes picker startup failures', () async {
    final SettingsController controller = SettingsController(
      mediaLibraryRepository: MediaLibraryRepository(
        scanDirectoryDataSource: _FakePickerScanDirectoryDataSource(
          pickError: StateError('boom'),
        ),
        mediaIndexStore: FakeMediaIndexStore(),
      ),
    );

    final String? directory = await controller.pickDirectory();

    expect(directory, isNull);
    expect(controller.errorMessage, contains('boom'));
    expect(controller.isPickingDirectory, isFalse);
  });
}

class _FakePickerScanDirectoryDataSource extends ScanDirectoryDataSource {
  _FakePickerScanDirectoryDataSource({
    this.pickedDirectory,
    this.pickError,
    Set<String>? accessibleDirectories,
  }) : _accessibleDirectories = accessibleDirectories ?? <String>{};

  final String? pickedDirectory;
  final Object? pickError;
  final Set<String> _accessibleDirectories;
  String? requestedInitialDirectory;

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async {
    requestedInitialDirectory = initialDirectory;
    if (pickError != null) {
      throw pickError!;
    }
    return pickedDirectory;
  }

  @override
  Future<bool> ensureDirectoryAccess(String path) async {
    return _accessibleDirectories.contains(path);
  }
}
