import '../data/update_manifest_client.dart';
import '../domain/app_update_info.dart';
import '../domain/app_update_manifest.dart';
import '../domain/app_version.dart';
import '../domain/update_check_result.dart';
import 'app_version_source.dart';
import 'update_platform_info_source.dart';

class UpdateService {
  UpdateService({
    required AppVersionSource versionSource,
    required UpdateManifestClient manifestClient,
    required this.platform,
    UpdatePlatformInfoSource? platformInfoSource,
  }) : _versionSource = versionSource,
       _manifestClient = manifestClient,
       _platformInfoSource =
           platformInfoSource ?? MethodChannelUpdatePlatformInfoSource();

  final AppVersionSource _versionSource;
  final UpdateManifestClient _manifestClient;
  final UpdatePlatformInfoSource _platformInfoSource;
  final AppUpdatePlatform platform;

  Future<AppVersion> readCurrentVersion() {
    return _versionSource.readCurrentVersion();
  }

  Future<UpdateCheckResult> checkForUpdates({
    AppVersion? currentVersion,
  }) async {
    final AppVersion resolvedCurrentVersion =
        currentVersion ?? await _versionSource.readCurrentVersion();

    try {
      final AppUpdateManifest manifest = await _manifestClient
          .fetchLatestUpdateManifest();
      final AppUpdateInfo? updateInfo = manifest.latestFor(platform);
      if (updateInfo == null) {
        return UpdateCheckResult(
          state: UpdateCheckState.unavailable,
          currentVersion: resolvedCurrentVersion,
          message: '当前平台尚未发布可用更新',
        );
      }
      final int comparison = updateInfo.version.compareTo(
        resolvedCurrentVersion,
      );
      if (comparison <= 0) {
        return UpdateCheckResult(
          state: UpdateCheckState.upToDate,
          currentVersion: resolvedCurrentVersion,
          updateInfo: updateInfo,
          message: '当前已经是最新版本',
        );
      }
      if (!await _hasAvailableTarget(updateInfo.target)) {
        return UpdateCheckResult(
          state: UpdateCheckState.unavailable,
          currentVersion: resolvedCurrentVersion,
          updateInfo: updateInfo,
          message: '检测到新版本，但当前平台暂未提供更新包',
        );
      }
      return UpdateCheckResult(
        state: UpdateCheckState.updateAvailable,
        currentVersion: resolvedCurrentVersion,
        updateInfo: updateInfo,
        message: '发现新版本 ${updateInfo.version.displayVersion}',
      );
    } on UpdateManifestException catch (error) {
      return UpdateCheckResult(
        state: UpdateCheckState.unavailable,
        currentVersion: resolvedCurrentVersion,
        message: error.message,
      );
    } catch (error) {
      return UpdateCheckResult(
        state: UpdateCheckState.failed,
        currentVersion: resolvedCurrentVersion,
        message: '检查更新失败：$error',
      );
    }
  }

  Future<bool> _hasAvailableTarget(AppUpdateTarget target) async {
    if (platform == AppUpdatePlatform.android) {
      final List<String> supportedAbis = await _platformInfoSource
          .readAndroidSupportedAbis();
      return target.resolve(supportedAbis: supportedAbis) != null;
    }
    return target.resolve() != null || target.hasDownloadTarget;
  }
}
