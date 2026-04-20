import 'app_update_info.dart';
import 'app_version.dart';

enum UpdateCheckState { idle, unavailable, upToDate, updateAvailable, failed }

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.state,
    required this.currentVersion,
    this.updateInfo,
    this.message,
  });

  final UpdateCheckState state;
  final AppVersion currentVersion;
  final AppUpdateInfo? updateInfo;
  final String? message;

  bool get isUpdateAvailable =>
      state == UpdateCheckState.updateAvailable && updateInfo != null;
}
