import 'app_update_info.dart';

class AppUpdateManifest {
  const AppUpdateManifest({required this.platforms});

  final Map<AppUpdatePlatform, AppUpdateInfo> platforms;

  AppUpdateInfo? latestFor(AppUpdatePlatform platform) => platforms[platform];
}
