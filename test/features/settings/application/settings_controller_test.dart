import 'dart:async';

import 'package:file_selector/file_selector.dart';
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

  test(
    'pickDirectory on iOS import flow transitions from selecting to importing',
    () async {
      final Completer<List<XFile>> pickCompleter = Completer<List<XFile>>();
      final Completer<String?> importCompleter = Completer<String?>();
      final _FakePickerScanDirectoryDataSource dataSource =
          _FakePickerScanDirectoryDataSource(
            pickedFilesFuture: pickCompleter.future,
            importDirectoryFuture: importCompleter.future,
          );
      final SettingsController controller = SettingsController(
        mediaLibraryRepository: MediaLibraryRepository(
          scanDirectoryDataSource: dataSource,
          mediaIndexStore: FakeMediaIndexStore(),
        ),
        usesImportedLocalLibrary: true,
      );

      final Future<String?> pendingResult = controller.pickDirectory();

      expect(controller.isSelectingDirectory, isTrue);
      pickCompleter.complete(<XFile>[XFile('/tmp/Singer - Song.dat')]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isImportingDirectory, isTrue);
      importCompleter.complete('/imported');

      final String? directory = await pendingResult;

      expect(directory, '/imported');
      expect(controller.currentDirectoryPath, '/imported');
      expect(controller.isPickingDirectory, isFalse);
      expect(dataSource.importedFiles, hasLength(1));
    },
  );

  test('recoverStuckDirectorySelection unlocks a pending iOS picker', () async {
    final Completer<List<XFile>> pickCompleter = Completer<List<XFile>>();
    final SettingsController controller = SettingsController(
      mediaLibraryRepository: MediaLibraryRepository(
        scanDirectoryDataSource: _FakePickerScanDirectoryDataSource(
          pickedFilesFuture: pickCompleter.future,
        ),
        mediaIndexStore: FakeMediaIndexStore(),
      ),
      usesImportedLocalLibrary: true,
    );

    final Future<String?> pendingResult = controller.pickDirectory();

    expect(controller.isSelectingDirectory, isTrue);
    controller.recoverStuckDirectorySelection();
    expect(controller.isPickingDirectory, isFalse);

    pickCompleter.complete(const <XFile>[]);
    expect(await pendingResult, isNull);
    expect(controller.isPickingDirectory, isFalse);
  });
}

class _FakePickerScanDirectoryDataSource extends ScanDirectoryDataSource {
  _FakePickerScanDirectoryDataSource({
    this.pickedDirectory,
    this.pickedFilesFuture,
    this.importDirectoryFuture,
    this.pickError,
    Set<String>? accessibleDirectories,
  }) : _accessibleDirectories = accessibleDirectories ?? <String>{};

  final String? pickedDirectory;
  final Future<List<XFile>>? pickedFilesFuture;
  final Future<String?>? importDirectoryFuture;
  final Object? pickError;
  final Set<String> _accessibleDirectories;
  String? requestedInitialDirectory;
  List<XFile>? importedFiles;

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async {
    requestedInitialDirectory = initialDirectory;
    if (pickError != null) {
      throw pickError!;
    }
    return pickedDirectory;
  }

  @override
  Future<List<XFile>> pickImportFiles({String? initialDirectory}) async {
    requestedInitialDirectory = initialDirectory;
    if (pickError != null) {
      throw pickError!;
    }
    if (pickedFilesFuture != null) {
      return pickedFilesFuture!;
    }
    return const <XFile>[];
  }

  @override
  Future<String?> importPickedFiles(List<XFile> selectedFiles) async {
    importedFiles = selectedFiles;
    if (pickError != null) {
      throw pickError!;
    }
    if (importDirectoryFuture != null) {
      return importDirectoryFuture!;
    }
    return null;
  }

  @override
  Future<bool> ensureDirectoryAccess(String path) async {
    return _accessibleDirectories.contains(path);
  }
}
