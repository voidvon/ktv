import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/ios_local_media_import_data_source.dart';

void main() {
  test('iosImportTypeGroup allows all files for iOS document picker', () {
    final XTypeGroup typeGroup = IosLocalMediaImportDataSource.iosImportTypeGroup;

    expect(typeGroup.allowsAny, isTrue);
    expect(typeGroup.uniformTypeIdentifiers, isNull);
  });

  test(
    'importFiles copies selected videos into the app library directory',
    () async {
      final Directory sourceRoot = await Directory.systemTemp.createTemp(
        'ktv_ios_import_source_',
      );
      final Directory targetRoot = await Directory.systemTemp.createTemp(
        'ktv_ios_import_target_',
      );
      addTearDown(() async {
        if (await sourceRoot.exists()) {
          await sourceRoot.delete(recursive: true);
        }
        if (await targetRoot.exists()) {
          await targetRoot.delete(recursive: true);
        }
      });

      final File sourceFile = File('${sourceRoot.path}/Singer - Song.dat');
      await sourceFile.writeAsBytes(<int>[1, 2, 3, 4], flush: true);
      final File ignoredFile = File('${sourceRoot.path}/notes.txt');
      await ignoredFile.writeAsString('skip me', flush: true);

      final IosLocalMediaImportDataSource dataSource =
          IosLocalMediaImportDataSource(
            filePicker:
                ({
                  acceptedTypeGroups = const [],
                  String? confirmButtonText,
                  String? initialDirectory,
                }) async {
                  expect(acceptedTypeGroups, hasLength(1));
                  expect(acceptedTypeGroups.single.allowsAny, isTrue);
                  return <XFile>[
                    XFile(sourceFile.path),
                    XFile(ignoredFile.path),
                  ];
                },
            libraryDirectoryProvider: () async => targetRoot,
          );

      final String? importedDirectory = await dataSource.importFiles();

      expect(importedDirectory, targetRoot.path);
      expect(
        await File('${targetRoot.path}/Singer - Song.dat').exists(),
        isTrue,
      );
      expect(await File('${targetRoot.path}/notes.txt').exists(), isFalse);
    },
  );

  test(
    'importFiles renames duplicate file names instead of overwriting',
    () async {
      final Directory sourceRoot = await Directory.systemTemp.createTemp(
        'ktv_ios_import_dup_source_',
      );
      final Directory targetRoot = await Directory.systemTemp.createTemp(
        'ktv_ios_import_dup_target_',
      );
      addTearDown(() async {
        if (await sourceRoot.exists()) {
          await sourceRoot.delete(recursive: true);
        }
        if (await targetRoot.exists()) {
          await targetRoot.delete(recursive: true);
        }
      });

      final File existingFile = File('${targetRoot.path}/Singer - Song.mp4');
      await existingFile.writeAsBytes(<int>[9], flush: true);
      final File sourceFile = File('${sourceRoot.path}/Singer - Song.mp4');
      await sourceFile.writeAsBytes(<int>[1, 2, 3], flush: true);

      final IosLocalMediaImportDataSource dataSource =
          IosLocalMediaImportDataSource(
            filePicker:
                ({
                  acceptedTypeGroups = const [],
                  String? confirmButtonText,
                  String? initialDirectory,
                }) async => <XFile>[XFile(sourceFile.path)],
            libraryDirectoryProvider: () async => targetRoot,
          );

      await dataSource.importFiles();

      expect(
        await File('${targetRoot.path}/Singer - Song.mp4').readAsBytes(),
        <int>[9],
      );
      expect(
        await File('${targetRoot.path}/Singer - Song (2).mp4').readAsBytes(),
        <int>[1, 2, 3],
      );
    },
  );

  test(
    'importFiles throws when no selected files are supported videos',
    () async {
      final Directory sourceRoot = await Directory.systemTemp.createTemp(
        'ktv_ios_import_invalid_source_',
      );
      final Directory targetRoot = await Directory.systemTemp.createTemp(
        'ktv_ios_import_invalid_target_',
      );
      addTearDown(() async {
        if (await sourceRoot.exists()) {
          await sourceRoot.delete(recursive: true);
        }
        if (await targetRoot.exists()) {
          await targetRoot.delete(recursive: true);
        }
      });

      final File sourceFile = File('${sourceRoot.path}/notes.txt');
      await sourceFile.writeAsString('skip me', flush: true);

      final IosLocalMediaImportDataSource dataSource =
          IosLocalMediaImportDataSource(
            filePicker:
                ({
                  acceptedTypeGroups = const [],
                  String? confirmButtonText,
                  String? initialDirectory,
                }) async => <XFile>[XFile(sourceFile.path)],
            libraryDirectoryProvider: () async => targetRoot,
          );

      expect(dataSource.importFiles(), throwsA(isA<StateError>()));
    },
  );
}
