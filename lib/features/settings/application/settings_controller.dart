import 'package:flutter/foundation.dart';

import '../../media_library/data/media_library_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required MediaLibraryRepository mediaLibraryRepository,
    String? initialDirectoryPath,
  }) : _mediaLibraryRepository = mediaLibraryRepository,
       _currentDirectoryPath = initialDirectoryPath;

  final MediaLibraryRepository _mediaLibraryRepository;

  String? _currentDirectoryPath;
  String? _errorMessage;
  bool _isPickingDirectory = false;

  String? get currentDirectoryPath => _currentDirectoryPath;
  String? get errorMessage => _errorMessage;
  bool get isPickingDirectory => _isPickingDirectory;

  Future<String?> pickDirectory() async {
    if (_isPickingDirectory) {
      return null;
    }

    _setPickingState(isPickingDirectory: true, errorMessage: null);

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
          isPickingDirectory: true,
          errorMessage: '系统没有保留这个目录的读取授权，请重新选择目录。',
        );
        return null;
      }

      _currentDirectoryPath = directory;
      notifyListeners();
      return directory;
    } catch (error) {
      _setPickingState(
        isPickingDirectory: true,
        errorMessage: '系统目录选择器没有成功启动：$error',
      );
      return null;
    } finally {
      _setPickingState(isPickingDirectory: false, errorMessage: _errorMessage);
    }
  }

  void _setPickingState({
    required bool isPickingDirectory,
    required String? errorMessage,
  }) {
    _isPickingDirectory = isPickingDirectory;
    _errorMessage = errorMessage;
    notifyListeners();
  }
}
