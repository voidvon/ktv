import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DemoAndroidStorageService {
  static const MethodChannel _channel = MethodChannel(
    'ktv2_example/android_storage',
  );

  bool isDocumentTreeUri(String path) => path.startsWith('content://');

  Future<String?> pickDirectory({String? initialDirectory}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final String? selectedUri = await _channel.invokeMethod<String>(
      'pickDirectory',
      <String, Object?>{'initialDirectory': initialDirectory},
    );
    if (selectedUri == null || selectedUri.trim().isEmpty) {
      return null;
    }
    return selectedUri;
  }

  Future<bool> ensureDirectoryAccess(String path) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !isDocumentTreeUri(path)) {
      return true;
    }

    final bool? accessible = await _channel.invokeMethod<bool>(
      'ensureDirectoryAccess',
      <String, Object?>{'path': path},
    );
    return accessible ?? false;
  }

  Future<void> clearDirectoryAccess({String? path}) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        path == null ||
        !isDocumentTreeUri(path)) {
      return;
    }

    await _channel.invokeMethod<void>('clearDirectoryAccess', <String, Object?>{
      'path': path,
    });
  }

  Future<void> saveSelectedDirectory(String path) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await _channel.invokeMethod<void>(
      'saveSelectedDirectory',
      <String, Object?>{'path': path},
    );
  }

  Future<String?> loadSelectedDirectory() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final String? path = await _channel.invokeMethod<String>(
      'loadSelectedDirectory',
    );
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    return path;
  }

  Future<List<DemoAndroidLibrarySong>> scanLibrary(String rootUri) async {
    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>(
      'scanLibrary',
      <String, Object?>{'rootUri': rootUri},
    );

    final List<DemoAndroidLibrarySong> songs = <DemoAndroidLibrarySong>[];
    for (final dynamic item in result ?? const <dynamic>[]) {
      if (item is! Map) {
        continue;
      }

      final Map<Object?, Object?> map = Map<Object?, Object?>.from(item);
      songs.add(
        DemoAndroidLibrarySong(
          title: (map['title'] as String?) ?? '未知歌曲',
          artist: (map['artist'] as String?) ?? '未识别歌手',
          mediaPath: (map['filePath'] as String?) ?? '',
          fileName: (map['fileName'] as String?) ?? '',
          extension: (map['extension'] as String?) ?? '',
        ),
      );
    }
    return songs;
  }
}

class DemoAndroidLibrarySong {
  const DemoAndroidLibrarySong({
    required this.title,
    required this.artist,
    required this.mediaPath,
    required this.fileName,
    required this.extension,
  });

  final String title;
  final String artist;
  final String mediaPath;
  final String fileName;
  final String extension;
}
