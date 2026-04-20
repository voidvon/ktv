import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/update/application/update_platform_adapter.dart';
import 'package:maimai_ktv/features/update/application/update_package_downloader.dart';
import 'package:maimai_ktv/features/update/application/update_package_installer.dart';
import 'package:maimai_ktv/features/update/application/update_platform_info_source.dart';
import 'package:maimai_ktv/features/update/domain/app_update_info.dart';
import 'package:maimai_ktv/features/update/domain/app_version.dart';

void main() {
  test('android adapter downloads and installs matching abi variant', () async {
    Uri? downloadedUri;
    String? installedPath;
    final ExternalUpdatePlatformAdapter adapter = ExternalUpdatePlatformAdapter(
      platform: AppUpdatePlatform.android,
      releasePageUri: Uri.parse('https://example.com/releases'),
      platformInfoSource: const _FakePlatformInfoSource(<String>[
        'arm64-v8a',
        'armeabi-v7a',
      ]),
      packageDownloader: FakeUpdatePackageDownloader(
        onDownload: (ResolvedAppUpdateTarget target) async {
          downloadedUri = target.uri;
          return File('/tmp/update.apk');
        },
      ),
      packageInstaller: FakeUpdatePackageInstaller(
        onInstall: (String filePath) async {
          installedPath = filePath;
          return ApkInstallResult.installStarted;
        },
      ),
    );

    final bool didOpen = await adapter.openUpdate(
      AppUpdateInfo(
        platform: AppUpdatePlatform.android,
        version: AppVersion(displayVersion: '1.0.0-alpha.8', buildNumber: 8),
        publishedAt: null,
        requiredUpdate: false,
        notes: const <String>[],
        target: AppUpdateTarget(
          mode: AppUpdateInstallMode.apk,
          variants: <AndroidApkVariant>[
            AndroidApkVariant(
              abi: 'arm64-v8a',
              url: Uri.parse('https://example.com/app-arm64.apk'),
            ),
          ],
          fallbackUrl: Uri.parse('https://example.com/app-universal.apk'),
        ),
      ),
    );

    expect(didOpen, isTrue);
    expect(downloadedUri.toString(), 'https://example.com/app-arm64.apk');
    expect(installedPath, '/tmp/update.apk');
  });

  test(
    'android adapter falls back to universal package when no abi matches',
    () async {
      Uri? downloadedUri;
      final ExternalUpdatePlatformAdapter adapter =
          ExternalUpdatePlatformAdapter(
            platform: AppUpdatePlatform.android,
            releasePageUri: Uri.parse('https://example.com/releases'),
            platformInfoSource: const _FakePlatformInfoSource(<String>[
              'arm64-v8a',
            ]),
            packageDownloader: FakeUpdatePackageDownloader(
              onDownload: (ResolvedAppUpdateTarget target) async {
                downloadedUri = target.uri;
                return File('/tmp/update.apk');
              },
            ),
            packageInstaller: FakeUpdatePackageInstaller(
              onInstall: (String filePath) async {
                return ApkInstallResult.installStarted;
              },
            ),
          );

      final bool didOpen = await adapter.openUpdate(
        AppUpdateInfo(
          platform: AppUpdatePlatform.android,
          version: AppVersion(displayVersion: '1.0.0-alpha.8', buildNumber: 8),
          publishedAt: null,
          requiredUpdate: false,
          notes: const <String>[],
          target: AppUpdateTarget(
            mode: AppUpdateInstallMode.apk,
            variants: <AndroidApkVariant>[
              AndroidApkVariant(
                abi: 'x86_64',
                url: Uri.parse('https://example.com/app-x64.apk'),
              ),
            ],
            fallbackUrl: Uri.parse('https://example.com/app-universal.apk'),
          ),
        ),
      );

      expect(didOpen, isTrue);
      expect(downloadedUri.toString(), 'https://example.com/app-universal.apk');
    },
  );

  test(
    'android adapter surfaces permission prompt requirement from installer',
    () async {
      final ExternalUpdatePlatformAdapter adapter =
          ExternalUpdatePlatformAdapter(
            platform: AppUpdatePlatform.android,
            releasePageUri: Uri.parse('https://example.com/releases'),
            platformInfoSource: const _FakePlatformInfoSource(<String>[
              'arm64-v8a',
            ]),
            packageDownloader: FakeUpdatePackageDownloader(
              onDownload: (ResolvedAppUpdateTarget target) async {
                return File('/tmp/update.apk');
              },
            ),
            packageInstaller: FakeUpdatePackageInstaller(
              onInstall: (String filePath) async {
                return ApkInstallResult.permissionRequired;
              },
            ),
          );

      expect(
        () => adapter.openUpdate(
          AppUpdateInfo(
            platform: AppUpdatePlatform.android,
            version: AppVersion(
              displayVersion: '1.0.0-alpha.8',
              buildNumber: 8,
            ),
            publishedAt: null,
            requiredUpdate: false,
            notes: const <String>[],
            target: AppUpdateTarget(
              mode: AppUpdateInstallMode.apk,
              url: Uri.parse('https://example.com/app.apk'),
            ),
          ),
        ),
        throwsA(isA<UpdateActionException>()),
      );
    },
  );
}

class _FakePlatformInfoSource implements UpdatePlatformInfoSource {
  const _FakePlatformInfoSource(this.supportedAbis);

  final List<String> supportedAbis;

  @override
  Future<List<String>> readAndroidSupportedAbis() async => supportedAbis;
}

class FakeUpdatePackageDownloader implements UpdatePackageDownloader {
  FakeUpdatePackageDownloader({required this.onDownload});

  final Future<File> Function(ResolvedAppUpdateTarget target) onDownload;

  @override
  Future<File> downloadApk(ResolvedAppUpdateTarget target) =>
      onDownload(target);
}

class FakeUpdatePackageInstaller implements UpdatePackageInstaller {
  FakeUpdatePackageInstaller({required this.onInstall});

  final Future<ApkInstallResult> Function(String filePath) onInstall;

  @override
  Future<ApkInstallResult> installApk(String filePath) => onInstall(filePath);
}
