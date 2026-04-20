import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../domain/app_update_info.dart';

abstract interface class UpdatePackageDownloader {
  Future<File> downloadApk(ResolvedAppUpdateTarget target);
}

class HttpUpdatePackageDownloader implements UpdatePackageDownloader {
  @override
  Future<File> downloadApk(ResolvedAppUpdateTarget target) async {
    final Directory tempDirectory = await getTemporaryDirectory();
    final Directory updatesDirectory = Directory(
      path.join(tempDirectory.path, 'updates'),
    );
    await updatesDirectory.create(recursive: true);

    final String fileName = _resolveFileName(target.uri);
    final File outputFile = File(path.join(updatesDirectory.path, fileName));
    final HttpClient httpClient = HttpClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(target.uri);
      final HttpClientResponse response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw UpdateActionException('下载更新失败（HTTP ${response.statusCode}）');
      }

      final IOSink sink = outputFile.openWrite();
      try {
        await response.forEach(sink.add);
      } finally {
        await sink.close();
      }

      final String? sha256 = target.sha256?.trim();
      if (sha256 != null && sha256.isNotEmpty) {
        final String digest = await _computeSha256(outputFile);
        if (digest.toLowerCase() != sha256.toLowerCase()) {
          throw const UpdateActionException('下载完成，但更新包校验失败');
        }
      }
      return outputFile;
    } finally {
      httpClient.close(force: true);
    }
  }

  String _resolveFileName(Uri uri) {
    final String rawName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : '';
    final String fallbackName = 'maimai-ktv-update.apk';
    if (rawName.isEmpty) {
      return fallbackName;
    }
    return rawName.toLowerCase().endsWith('.apk') ? rawName : '$rawName.apk';
  }

  Future<String> _computeSha256(File file) async {
    final Digest digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}

class UpdateActionException implements Exception {
  const UpdateActionException(this.message);

  final String message;

  @override
  String toString() => message;
}
