import 'package:url_launcher/url_launcher.dart';

import '../domain/app_update_info.dart';
import 'update_package_downloader.dart';
import 'update_package_installer.dart';
import 'update_platform_info_source.dart';

abstract interface class UpdatePlatformAdapter {
  Future<bool> openUpdate(AppUpdateInfo updateInfo);

  Future<bool> openReleasePage();
}

class ExternalUpdatePlatformAdapter implements UpdatePlatformAdapter {
  ExternalUpdatePlatformAdapter({
    required this.platform,
    required this.releasePageUri,
    Future<bool> Function(Uri uri)? launcher,
    UpdatePlatformInfoSource? platformInfoSource,
    UpdatePackageDownloader? packageDownloader,
    UpdatePackageInstaller? packageInstaller,
  }) : _launcher =
           launcher ??
           ((Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication)),
       _platformInfoSource =
           platformInfoSource ?? MethodChannelUpdatePlatformInfoSource(),
       _packageDownloader = packageDownloader ?? HttpUpdatePackageDownloader(),
       _packageInstaller =
           packageInstaller ?? MethodChannelUpdatePackageInstaller();

  final AppUpdatePlatform platform;
  final Uri releasePageUri;
  final Future<bool> Function(Uri uri) _launcher;
  final UpdatePlatformInfoSource _platformInfoSource;
  final UpdatePackageDownloader _packageDownloader;
  final UpdatePackageInstaller _packageInstaller;

  @override
  Future<bool> openUpdate(AppUpdateInfo updateInfo) async {
    final ResolvedAppUpdateTarget? resolvedTarget = await _resolveTarget(
      updateInfo.target,
    );
    if (resolvedTarget == null) {
      return openReleasePage();
    }
    if (platform == AppUpdatePlatform.android &&
        updateInfo.target.mode == AppUpdateInstallMode.apk) {
      return _downloadAndInstall(resolvedTarget);
    }
    return _launcher(resolvedTarget.uri);
  }

  @override
  Future<bool> openReleasePage() {
    return _launcher(releasePageUri);
  }

  Future<ResolvedAppUpdateTarget?> _resolveTarget(
    AppUpdateTarget target,
  ) async {
    if (platform == AppUpdatePlatform.android) {
      final List<String> supportedAbis = await _platformInfoSource
          .readAndroidSupportedAbis();
      return target.resolve(supportedAbis: supportedAbis);
    }
    return target.resolve();
  }

  Future<bool> _downloadAndInstall(ResolvedAppUpdateTarget target) async {
    final file = await _packageDownloader.downloadApk(target);
    final ApkInstallResult result = await _packageInstaller.installApk(
      file.path,
    );
    switch (result) {
      case ApkInstallResult.installStarted:
        return true;
      case ApkInstallResult.permissionRequired:
        throw const UpdateActionException('请先允许应用安装未知来源应用，再重新点击更新');
    }
  }
}
