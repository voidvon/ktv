import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ApkInstallResult { installStarted, permissionRequired }

abstract interface class UpdatePackageInstaller {
  Future<ApkInstallResult> installApk(String filePath);
}

class MethodChannelUpdatePackageInstaller implements UpdatePackageInstaller {
  MethodChannelUpdatePackageInstaller({
    MethodChannel channel = const MethodChannel(
      'com.app0122.maimai.app/update',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<ApkInstallResult> installApk(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('Web does not support APK installation');
    }
    final Map<dynamic, dynamic>? result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('installApk', <String, Object?>{
          'filePath': filePath,
        });
    final String status = result?['status']?.toString() ?? '';
    return switch (status) {
      'install_started' => ApkInstallResult.installStarted,
      'permission_required' => ApkInstallResult.permissionRequired,
      _ => throw StateError('Unknown install result: $status'),
    };
  }
}
