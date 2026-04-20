import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/update/application/app_version_source.dart';
import 'package:maimai_ktv/features/update/application/update_platform_info_source.dart';
import 'package:maimai_ktv/features/update/application/update_service.dart';
import 'package:maimai_ktv/features/update/data/update_manifest_client.dart';
import 'package:maimai_ktv/features/update/domain/app_update_info.dart';
import 'package:maimai_ktv/features/update/domain/app_version.dart';
import 'package:maimai_ktv/features/update/domain/update_check_result.dart';

void main() {
  test('returns unavailable when manifest uri is not configured', () async {
    final UpdateService service = UpdateService(
      versionSource: _FakeVersionSource(
        AppVersion(displayVersion: '1.0.0-alpha.7', buildNumber: 7),
      ),
      manifestClient: UpdateManifestClient(manifestUri: null),
      platform: AppUpdatePlatform.android,
      platformInfoSource: const _FakePlatformInfoSource(<String>[]),
    );

    final UpdateCheckResult result = await service.checkForUpdates();

    expect(result.state, UpdateCheckState.unavailable);
    expect(result.message, contains('更新源尚未配置'));
  });

  test('returns updateAvailable when a newer build exists', () async {
    final UpdateService service = UpdateService(
      versionSource: _FakeVersionSource(
        AppVersion(displayVersion: '1.0.0-alpha.7', buildNumber: 7),
      ),
      manifestClient: UpdateManifestClient(
        manifestUri: Uri.parse('https://example.com/latest.json'),
        loader: (Uri uri) async {
          return '''
{
  "version": "1.0.0-alpha.7",
  "buildNumber": 8,
  "downloads": {
    "android": {
      "mode": "apk",
      "url": "https://example.com/app.apk"
    }
  }
}
''';
        },
      ),
      platform: AppUpdatePlatform.android,
      platformInfoSource: const _FakePlatformInfoSource(<String>[]),
    );

    final UpdateCheckResult result = await service.checkForUpdates();

    expect(result.state, UpdateCheckState.updateAvailable);
    expect(result.updateInfo?.version.fullValue, '1.0.0-alpha.7+8');
  });

  test('returns upToDate when remote version is not newer', () async {
    final UpdateService service = UpdateService(
      versionSource: _FakeVersionSource(
        AppVersion(displayVersion: '1.0.0-alpha.7', buildNumber: 7),
      ),
      manifestClient: UpdateManifestClient(
        manifestUri: Uri.parse('https://example.com/latest.json'),
        loader: (Uri uri) async {
          return '''
{
  "version": "1.0.0-alpha.7",
  "buildNumber": 7,
  "downloads": {
    "android": {
      "mode": "apk",
      "url": "https://example.com/app.apk"
    }
  }
}
''';
        },
      ),
      platform: AppUpdatePlatform.android,
      platformInfoSource: const _FakePlatformInfoSource(<String>[]),
    );

    final UpdateCheckResult result = await service.checkForUpdates();

    expect(result.state, UpdateCheckState.upToDate);
    expect(result.message, contains('最新版本'));
  });

  test('returns unavailable when target platform has no package', () async {
    final UpdateService service = UpdateService(
      versionSource: _FakeVersionSource(
        AppVersion(displayVersion: '1.0.0-alpha.7', buildNumber: 7),
      ),
      manifestClient: UpdateManifestClient(
        manifestUri: Uri.parse('https://example.com/latest.json'),
        loader: (Uri uri) async {
          return '''
{
  "version": "1.0.0-alpha.8",
  "buildNumber": 8,
  "downloads": {
    "macos": {
      "mode": "sparkle",
      "feedUrl": "https://example.com/appcast.xml"
    }
  }
}
''';
        },
      ),
      platform: AppUpdatePlatform.windows,
      platformInfoSource: const _FakePlatformInfoSource(<String>[]),
    );

    final UpdateCheckResult result = await service.checkForUpdates();

    expect(result.state, UpdateCheckState.unavailable);
    expect(result.message, contains('当前平台尚未发布可用更新'));
  });

  test('reads platform-specific latest entry from unified manifest', () async {
    final UpdateService service = UpdateService(
      versionSource: _FakeVersionSource(
        AppVersion(displayVersion: '1.0.0-alpha.7', buildNumber: 7),
      ),
      manifestClient: UpdateManifestClient(
        manifestUri: Uri.parse('https://example.com/latest.json'),
        loader: (Uri uri) async {
          return '''
{
  "platforms": {
    "android": {
      "version": "1.0.0-alpha.8",
      "buildNumber": 8,
      "notes": ["Android hotfix"],
      "download": {
        "mode": "apk",
        "variants": [
          {
            "abi": "arm64-v8a",
            "url": "https://example.com/app-arm64.apk"
          }
        ],
        "fallbackUrl": "https://example.com/app-universal.apk"
      }
    },
    "windows": {
      "version": "1.0.0-alpha.9",
      "buildNumber": 9,
      "notes": ["Windows x64 package"],
      "download": {
        "mode": "external",
        "url": "https://example.com/windows-release"
      }
    }
  }
}
''';
        },
      ),
      platform: AppUpdatePlatform.windows,
      platformInfoSource: const _FakePlatformInfoSource(<String>[]),
    );

    final UpdateCheckResult result = await service.checkForUpdates();

    expect(result.state, UpdateCheckState.updateAvailable);
    expect(result.updateInfo?.version.fullValue, '1.0.0-alpha.9+9');
    expect(result.updateInfo?.notes, contains('Windows x64 package'));
  });

  test(
    'returns updateAvailable when android variant matches supported abi',
    () async {
      final UpdateService service = UpdateService(
        versionSource: _FakeVersionSource(
          AppVersion(displayVersion: '1.0.0-alpha.7', buildNumber: 7),
        ),
        manifestClient: UpdateManifestClient(
          manifestUri: Uri.parse('https://example.com/latest.json'),
          loader: (Uri uri) async {
            return '''
{
  "version": "1.0.0-alpha.8",
  "buildNumber": 8,
  "downloads": {
    "android": {
      "mode": "apk",
      "variants": [
        {
          "abi": "arm64-v8a",
          "url": "https://example.com/app-arm64.apk"
        },
        {
          "abi": "armeabi-v7a",
          "url": "https://example.com/app-armeabi.apk"
        }
      ]
    }
  }
}
''';
          },
        ),
        platform: AppUpdatePlatform.android,
        platformInfoSource: const _FakePlatformInfoSource(<String>[
          'arm64-v8a',
        ]),
      );

      final UpdateCheckResult result = await service.checkForUpdates();

      expect(result.state, UpdateCheckState.updateAvailable);
    },
  );

  test(
    'returns unavailable when android variants do not match and no fallback exists',
    () async {
      final UpdateService service = UpdateService(
        versionSource: _FakeVersionSource(
          AppVersion(displayVersion: '1.0.0-alpha.7', buildNumber: 7),
        ),
        manifestClient: UpdateManifestClient(
          manifestUri: Uri.parse('https://example.com/latest.json'),
          loader: (Uri uri) async {
            return '''
{
  "version": "1.0.0-alpha.8",
  "buildNumber": 8,
  "downloads": {
    "android": {
      "mode": "apk",
      "variants": [
        {
          "abi": "x86_64",
          "url": "https://example.com/app-x64.apk"
        }
      ]
    }
  }
}
''';
          },
        ),
        platform: AppUpdatePlatform.android,
        platformInfoSource: const _FakePlatformInfoSource(<String>[
          'arm64-v8a',
        ]),
      );

      final UpdateCheckResult result = await service.checkForUpdates();

      expect(result.state, UpdateCheckState.unavailable);
    },
  );
}

class _FakeVersionSource implements AppVersionSource {
  const _FakeVersionSource(this.version);

  final AppVersion version;

  @override
  Future<AppVersion> readCurrentVersion() async => version;
}

class _FakePlatformInfoSource implements UpdatePlatformInfoSource {
  const _FakePlatformInfoSource(this.supportedAbis);

  final List<String> supportedAbis;

  @override
  Future<List<String>> readAndroidSupportedAbis() async => supportedAbis;
}
