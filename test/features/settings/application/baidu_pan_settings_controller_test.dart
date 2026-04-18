import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_api_client.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_auth_repository.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_models.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_source_config_store.dart';
import 'package:maimai_ktv/features/settings/application/baidu_pan_settings_controller.dart';

void main() {
  BaiduPanSettingsController buildController({
    _FakeBaiduPanAuthRepository? authRepository,
  }) {
    return BaiduPanSettingsController(
      appCredentials: const BaiduPanAppCredentials(
        appId: 'app-id',
        appKey: 'app-key',
        secretKey: 'secret-key',
        signKey: 'sign-key',
      ),
      apiClient: const _FakeBaiduPanApiClient(),
      authRepository: authRepository ?? _FakeBaiduPanAuthRepository(),
      sourceConfigStore: _FakeBaiduPanSourceConfigStore(),
    );
  }

  test(
    'recognizes authorization errors from exceptions and 401 http responses',
    () {
      final BaiduPanSettingsController controller = buildController();
      addTearDown(controller.dispose);

      expect(
        controller.isAuthorizationError(const BaiduPanUnauthorizedException()),
        isTrue,
      );
      expect(
        controller.isAuthorizationError(const HttpException('百度网盘下载失败: 401')),
        isTrue,
      );
      expect(
        controller.isAuthorizationError(const HttpException('百度网盘下载失败: 500')),
        isFalse,
      );
    },
  );

  test(
    'load prepares a device login session when no valid token exists',
    () async {
      final _FakeBaiduPanAuthRepository authRepository =
          _FakeBaiduPanAuthRepository();
      final BaiduPanSettingsController controller = buildController(
        authRepository: authRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(authRepository.createDeviceCodeSessionCallCount, 1);
      expect(controller.deviceCodeSession, isNotNull);
      expect(controller.isPreparingDeviceLogin, isFalse);
    },
  );
}

class _FakeBaiduPanApiClient implements BaiduPanApiClient {
  const _FakeBaiduPanApiClient();

  @override
  Future<BaiduPanQuotaInfo> getQuota() async {
    return const BaiduPanQuotaInfo(totalBytes: 100, usedBytes: 40);
  }

  @override
  Future<BaiduPanUserInfo> getUserInfo() async {
    return const BaiduPanUserInfo(uk: 'uk-1', displayName: '测试用户');
  }

  @override
  Future<BaiduPanRemoteFile> getFileMeta({
    required String fsid,
    bool withDlink = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<BaiduPanRemoteFile>> listAll({
    required String path,
    int start = 0,
    int limit = 1000,
  }) async {
    return const <BaiduPanRemoteFile>[];
  }

  @override
  Future<List<BaiduPanRemoteFile>> listDirectory({
    required String path,
    int start = 0,
    int limit = 1000,
  }) async {
    return const <BaiduPanRemoteFile>[];
  }

  @override
  Future<List<BaiduPanRemoteFile>> search({
    required String key,
    String? path,
    int page = 1,
    int num = 100,
  }) async {
    return const <BaiduPanRemoteFile>[];
  }
}

class _FakeBaiduPanAuthRepository extends BaiduPanAuthRepository {
  int createDeviceCodeSessionCallCount = 0;

  @override
  Future<Uri> buildAuthorizeUri() async => Uri.parse('https://example.com');

  @override
  Future<BaiduPanDeviceCodeSession> createDeviceCodeSession() async {
    createDeviceCodeSessionCallCount += 1;
    return BaiduPanDeviceCodeSession(
      deviceCode: 'device-code',
      userCode: 'user-code',
      verificationUrl: 'https://example.com/verify',
      qrcodeUrl: 'https://example.com/qr',
      expiresAtMillis: DateTime.now()
          .add(const Duration(minutes: 5))
          .millisecondsSinceEpoch,
      intervalSeconds: 5,
    );
  }

  @override
  Future<String> getValidAccessToken() async => 'token';

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<void> loginWithAuthorizationCode(String code) async {}

  @override
  Future<BaiduPanAuthToken?> loginWithDeviceCode(String deviceCode) async {
    return null;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<BaiduPanAuthToken?> readToken() async => null;
}

class _FakeBaiduPanSourceConfigStore extends BaiduPanSourceConfigStore {
  BaiduPanSourceConfig? config;

  @override
  Future<BaiduPanSourceConfig?> loadConfig() async => config;

  @override
  Future<void> saveConfig(BaiduPanSourceConfig config) async {
    this.config = config;
  }

  @override
  Future<void> clearConfig() async {
    config = null;
  }
}
