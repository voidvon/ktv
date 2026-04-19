import 'package:flutter/foundation.dart';

import '../../media_library/data/media_library_repository.dart';

enum LocalDirectoryActionState { idle, selecting, importing }

class SettingsController extends ChangeNotifier {
  SettingsController({
    required MediaLibraryRepository mediaLibraryRepository,
    String? initialDirectoryPath,
    bool? usesImportedLocalLibrary,
  }) : _mediaLibraryRepository = mediaLibraryRepository,
       _currentDirectoryPath = initialDirectoryPath,
       _usesImportedLocalLibrary =
           usesImportedLocalLibrary ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  final MediaLibraryRepository _mediaLibraryRepository;
  final bool _usesImportedLocalLibrary;

  String? _currentDirectoryPath;
  String? _errorMessage;
  LocalDirectoryActionState _directoryActionState =
      LocalDirectoryActionState.idle;

  String? get currentDirectoryPath => _currentDirectoryPath;
  String? get errorMessage => _errorMessage;
  bool get isPickingDirectory =>
      _directoryActionState != LocalDirectoryActionState.idle;
  bool get isSelectingDirectory =>
      _directoryActionState == LocalDirectoryActionState.selecting;
  bool get isImportingDirectory =>
      _directoryActionState == LocalDirectoryActionState.importing;
  bool get usesImportedLocalLibrary => _usesImportedLocalLibrary;

  Future<String?> pickDirectory() async {
    if (isPickingDirectory) {
      return null;
    }

    if (_usesImportedLocalLibrary) {
      return _pickImportedLocalLibrary();
    }
    return _pickLocalDirectory();
  }

  void recoverStuckDirectorySelection() {
    if (!isSelectingDirectory) {
      return;
    }
    _setPickingState(
      actionState: LocalDirectoryActionState.idle,
      errorMessage: _errorMessage,
    );
  }

  Future<String?> _pickLocalDirectory() async {
    _setPickingState(
      actionState: LocalDirectoryActionState.selecting,
      errorMessage: null,
    );

    try {
      final String? directory = await _mediaLibraryRepository.pickDirectory(
        initialDirectory: _currentDirectoryPath,
      );
      if (directory == null) {
        return null;
      }

      final bool hasAccess = await _mediaLibraryRepository
          .ensureDirectoryAccess(directory);
      if (!hasAccess) {
        _setPickingState(
          actionState: LocalDirectoryActionState.selecting,
          errorMessage: '系统没有保留这个目录的读取授权，请重新选择目录。',
        );
        return null;
      }

      _currentDirectoryPath = directory;
      notifyListeners();
      return directory;
    } catch (error) {
      _setPickingState(
        actionState: LocalDirectoryActionState.selecting,
        errorMessage: '系统文件选择器没有成功启动：$error',
      );
      return null;
    } finally {
      _setPickingState(
        actionState: LocalDirectoryActionState.idle,
        errorMessage: _errorMessage,
      );
    }
  }

  Future<String?> _pickImportedLocalLibrary() async {
    _setPickingState(
      actionState: LocalDirectoryActionState.selecting,
      errorMessage: null,
    );

    try {
      final selectedFiles = await _mediaLibraryRepository.pickImportFiles(
        initialDirectory: _currentDirectoryPath,
      );
      if (selectedFiles.isEmpty) {
        return null;
      }

      _setPickingState(
        actionState: LocalDirectoryActionState.importing,
        errorMessage: null,
      );
      final String? directory = await _mediaLibraryRepository.importPickedFiles(
        selectedFiles,
      );
      if (directory == null) {
        return null;
      }

      _currentDirectoryPath = directory;
      notifyListeners();
      return directory;
    } catch (error) {
      _setPickingState(
        actionState: isImportingDirectory
            ? LocalDirectoryActionState.importing
            : LocalDirectoryActionState.selecting,
        errorMessage: '导入本地文件失败：$error',
      );
      return null;
    } finally {
      _setPickingState(
        actionState: LocalDirectoryActionState.idle,
        errorMessage: _errorMessage,
      );
    }
  }

  void _setPickingState({
    required LocalDirectoryActionState actionState,
    required String? errorMessage,
  }) {
    _directoryActionState = actionState;
    _errorMessage = errorMessage;
    notifyListeners();
  }
}
