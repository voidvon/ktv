import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/media_library_repository.dart';
import 'package:maimai_ktv/features/settings/application/settings_controller.dart';

void main() {
  test('pickDirectory updates selected path when access is granted', () async {
    final FakeMediaLibraryRepository repository = FakeMediaLibraryRepository(
      pickedDirectory: '/media',
      accessibleDirectories: <String>{'/media'},
    );
    final SettingsController controller = SettingsController(
      mediaLibraryRepository: repository,
      initialDirectoryPath: '/initial',
    );

    final String? directory = await controller.pickDirectory();

    expect(directory, '/media');
    expect(controller.currentDirectoryPath, '/media');
    expect(controller.errorMessage, isNull);
    expect(controller.isPickingDirectory, isFalse);
    expect(repository.requestedInitialDirectory, '/initial');
  });

  test(
    'pickDirectory exposes access error when authorization is missing',
    () async {
      final SettingsController controller = SettingsController(
        mediaLibraryRepository: FakeMediaLibraryRepository(
          pickedDirectory: '/media',
        ),
      );

      final String? directory = await controller.pickDirectory();

      expect(directory, isNull);
      expect(controller.currentDirectoryPath, isNull);
      expect(controller.errorMessage, contains('璇诲彇鎺堟潈'));
      expect(controller.isPickingDirectory, isFalse);
    },
  );

  test('pickDirectory exposes picker startup failures', () async {
    final SettingsController controller = SettingsController(
      mediaLibraryRepository: FakeMediaLibraryRepository(
        pickError: StateError('boom'),
      ),
    );

    final String? directory = await controller.pickDirectory();

    expect(directory, isNull);
    expect(controller.errorMessage, contains('boom'));
    expect(controller.isPickingDirectory, isFalse);
  });
}

class FakeMediaLibraryRepository extends MediaLibraryRepository {
  FakeMediaLibraryRepository({
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

