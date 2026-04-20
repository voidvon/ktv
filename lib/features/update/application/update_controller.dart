import 'package:flutter/foundation.dart';

import '../domain/app_update_info.dart';
import '../domain/app_version.dart';
import '../domain/update_check_result.dart';
import 'update_platform_adapter.dart';
import 'update_service.dart';

class UpdateController extends ChangeNotifier {
  UpdateController({
    required UpdateService updateService,
    required UpdatePlatformAdapter platformAdapter,
  }) : _updateService = updateService,
       _platformAdapter = platformAdapter;

  final UpdateService _updateService;
  final UpdatePlatformAdapter _platformAdapter;

  AppVersion? _currentVersion;
  UpdateCheckResult? _lastResult;
  DateTime? _lastCheckedAt;
  String? _actionErrorMessage;
  bool _isInitializing = false;
  bool _isChecking = false;
  bool _isOpeningUpdate = false;

  AppVersion? get currentVersion => _currentVersion;
  UpdateCheckResult? get lastResult => _lastResult;
  DateTime? get lastCheckedAt => _lastCheckedAt;
  String? get actionErrorMessage => _actionErrorMessage;
  bool get isInitializing => _isInitializing;
  bool get isChecking => _isChecking;
  bool get isOpeningUpdate => _isOpeningUpdate;
  bool get isBusy => _isInitializing || _isChecking || _isOpeningUpdate;
  String get updateActionLabel {
    final AppUpdateInfo? updateInfo = _lastResult?.updateInfo;
    if (updateInfo == null) {
      return '查看发布页';
    }
    if (updateInfo.platform == AppUpdatePlatform.android &&
        updateInfo.target.mode == AppUpdateInstallMode.apk) {
      return '下载并安装';
    }
    return '前往更新';
  }

  String get summaryText {
    if (_isChecking) {
      return '正在检查更新';
    }
    final UpdateCheckResult? result = _lastResult;
    if (result == null) {
      final AppVersion? currentVersion = _currentVersion;
      if (currentVersion != null) {
        return '当前版本 ${currentVersion.displayVersion}';
      }
      if (_isInitializing) {
        return '正在读取版本信息';
      }
      return '查看当前版本并检查新版本';
    }
    return result.message ?? '查看当前版本并检查新版本';
  }

  Future<void> initialize() async {
    if (_isInitializing || _currentVersion != null) {
      return;
    }
    _isInitializing = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      _currentVersion = await _updateService.readCurrentVersion();
    } catch (error) {
      _actionErrorMessage = '读取版本信息失败：$error';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> checkForUpdates() async {
    if (_isChecking) {
      return;
    }
    _isChecking = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final UpdateCheckResult result = await _updateService.checkForUpdates(
        currentVersion: _currentVersion,
      );
      _currentVersion = result.currentVersion;
      _lastResult = result;
      _lastCheckedAt = DateTime.now();
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> openUpdate() async {
    final AppUpdateInfo? updateInfo = _lastResult?.updateInfo;
    if (updateInfo == null || _isOpeningUpdate) {
      return;
    }
    _isOpeningUpdate = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final bool didOpen = await _platformAdapter.openUpdate(updateInfo);
      if (!didOpen) {
        _actionErrorMessage = '没有可用的更新入口';
      }
    } catch (error) {
      _actionErrorMessage = '打开更新入口失败：$error';
    } finally {
      _isOpeningUpdate = false;
      notifyListeners();
    }
  }

  Future<void> openReleasePage() async {
    if (_isOpeningUpdate) {
      return;
    }
    _isOpeningUpdate = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final bool didOpen = await _platformAdapter.openReleasePage();
      if (!didOpen) {
        _actionErrorMessage = '无法打开发布页';
      }
    } catch (error) {
      _actionErrorMessage = '打开发布页失败：$error';
    } finally {
      _isOpeningUpdate = false;
      notifyListeners();
    }
  }
}
