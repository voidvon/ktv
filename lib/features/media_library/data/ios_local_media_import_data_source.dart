import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/media/supported_video_formats.dart';

typedef LocalMediaFilePicker =
    Future<List<XFile>> Function({
      List<XTypeGroup> acceptedTypeGroups,
      String? confirmButtonText,
      String? initialDirectory,
    });

class IosLocalMediaImportDataSource {
  IosLocalMediaImportDataSource({
    LocalMediaFilePicker? filePicker,
    Future<Directory> Function()? libraryDirectoryProvider,
  }) : _filePicker = filePicker ?? openFiles,
       _libraryDirectoryProvider =
           libraryDirectoryProvider ?? _defaultLibraryDirectoryProvider;

  final LocalMediaFilePicker _filePicker;
  final Future<Directory> Function() _libraryDirectoryProvider;

  // iOS Maps "allow any" to UTType public.data. This is more reliable than
  // trying to describe every video-like container, and it keeps .dat files
  // selectable so we can apply our own extension filter after selection.
  static const XTypeGroup _iosImportTypeGroup = XTypeGroup(
    label: 'Supported Media Files',
  );

  Future<List<XFile>> pickFiles({String? initialDirectory}) {
    return _filePicker(
      acceptedTypeGroups: const <XTypeGroup>[_iosImportTypeGroup],
      confirmButtonText: '导入',
      initialDirectory: initialDirectory,
    );
  }

  Future<String?> importFiles({String? initialDirectory}) async {
    final List<XFile> selectedFiles = await pickFiles(
      initialDirectory: initialDirectory,
    );
    return importPickedFiles(selectedFiles);
  }

  Future<String?> importPickedFiles(List<XFile> selectedFiles) async {
    if (selectedFiles.isEmpty) {
      return null;
    }

    final Directory libraryDirectory = await _libraryDirectoryProvider();
    await libraryDirectory.create(recursive: true);

    int importedFileCount = 0;
    for (final XFile selectedFile in selectedFiles) {
      final String fileName = _resolveFileName(selectedFile);
      if (!isSupportedVideoFileName(fileName)) {
        continue;
      }

      final File targetFile = await _createUniqueTargetFile(
        directory: libraryDirectory,
        preferredFileName: fileName,
      );
      await selectedFile.saveTo(targetFile.path);
      importedFileCount += 1;
    }

    if (importedFileCount == 0) {
      throw StateError('所选文件中没有可导入的视频文件');
    }
    return libraryDirectory.path;
  }

  static XTypeGroup get iosImportTypeGroup => _iosImportTypeGroup;

  static Future<Directory> _defaultLibraryDirectoryProvider() async {
    final Directory supportDirectory = await getApplicationSupportDirectory();
    return Directory(path.join(supportDirectory.path, 'local_media_library'));
  }

  String _resolveFileName(XFile selectedFile) {
    final String normalizedPath = selectedFile.path.trim();
    if (normalizedPath.isNotEmpty) {
      return path.basename(normalizedPath);
    }
    return 'imported_video.mp4';
  }

  Future<File> _createUniqueTargetFile({
    required Directory directory,
    required String preferredFileName,
  }) async {
    final String safeFileName = preferredFileName.trim().isEmpty
        ? 'imported_video.mp4'
        : preferredFileName.trim();
    final String fileStem = path.basenameWithoutExtension(safeFileName);
    final String fileExtension = path.extension(safeFileName);

    File candidate = File(path.join(directory.path, safeFileName));
    if (!await candidate.exists()) {
      return candidate;
    }

    int duplicateIndex = 2;
    while (true) {
      final String duplicateName = '$fileStem ($duplicateIndex)$fileExtension';
      candidate = File(path.join(directory.path, duplicateName));
      if (!await candidate.exists()) {
        return candidate;
      }
      duplicateIndex += 1;
    }
  }
}
