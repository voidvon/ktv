import 'package:flutter/foundation.dart';

import 'app_version.dart';

enum AppUpdatePlatform { android, ios, macos, windows, unsupported }

enum AppUpdateInstallMode { external, apk, appinstaller, sparkle }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.version,
    required this.publishedAt,
    required this.requiredUpdate,
    required this.notes,
    required this.target,
  });

  final AppUpdatePlatform platform;
  final AppVersion version;
  final DateTime? publishedAt;
  final bool requiredUpdate;
  final List<String> notes;
  final AppUpdateTarget target;

  static AppUpdatePlatform currentPlatform() {
    if (kIsWeb) {
      return AppUpdatePlatform.unsupported;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppUpdatePlatform.android,
      TargetPlatform.iOS => AppUpdatePlatform.ios,
      TargetPlatform.macOS => AppUpdatePlatform.macos,
      TargetPlatform.windows => AppUpdatePlatform.windows,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux => AppUpdatePlatform.unsupported,
    };
  }
}

class AppUpdateTarget {
  const AppUpdateTarget({
    required this.mode,
    this.url,
    this.feedUrl,
    this.sha256,
    this.variants = const <AndroidApkVariant>[],
    this.fallbackUrl,
    this.fallbackSha256,
  });

  final AppUpdateInstallMode mode;
  final Uri? url;
  final Uri? feedUrl;
  final String? sha256;
  final List<AndroidApkVariant> variants;
  final Uri? fallbackUrl;
  final String? fallbackSha256;

  Uri? get launchUri {
    return switch (mode) {
      AppUpdateInstallMode.sparkle => feedUrl ?? url,
      AppUpdateInstallMode.external ||
      AppUpdateInstallMode.apk ||
      AppUpdateInstallMode.appinstaller => url ?? feedUrl,
    };
  }

  bool get hasDownloadTarget =>
      launchUri != null || fallbackUrl != null || variants.isNotEmpty;

  ResolvedAppUpdateTarget? resolve({
    List<String> supportedAbis = const <String>[],
  }) {
    if (variants.isNotEmpty) {
      for (final String abi in supportedAbis) {
        for (final AndroidApkVariant variant in variants) {
          if (variant.abi == abi) {
            return ResolvedAppUpdateTarget(
              uri: variant.url,
              sha256: variant.sha256,
              matchedAbi: variant.abi,
            );
          }
        }
      }
      if (fallbackUrl != null) {
        return ResolvedAppUpdateTarget(
          uri: fallbackUrl!,
          sha256: fallbackSha256,
        );
      }
      return null;
    }

    final Uri? targetUri = launchUri;
    if (targetUri == null) {
      return null;
    }
    return ResolvedAppUpdateTarget(uri: targetUri, sha256: sha256);
  }
}

class AndroidApkVariant {
  const AndroidApkVariant({required this.abi, required this.url, this.sha256});

  final String abi;
  final Uri url;
  final String? sha256;
}

class ResolvedAppUpdateTarget {
  const ResolvedAppUpdateTarget({
    required this.uri,
    this.sha256,
    this.matchedAbi,
  });

  final Uri uri;
  final String? sha256;
  final String? matchedAbi;
}
