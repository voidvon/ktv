import 'package:package_info_plus/package_info_plus.dart';

import '../domain/app_version.dart';

abstract interface class AppVersionSource {
  Future<AppVersion> readCurrentVersion();
}

class PackageInfoAppVersionSource implements AppVersionSource {
  @override
  Future<AppVersion> readCurrentVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return AppVersion.parse(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}
