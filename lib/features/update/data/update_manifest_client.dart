import 'dart:convert';
import 'dart:io';

import '../domain/app_update_info.dart';
import '../domain/app_update_manifest.dart';
import '../domain/app_version.dart';

typedef UpdateManifestLoader = Future<String> Function(Uri uri);

class UpdateManifestClient {
  UpdateManifestClient({
    required this.manifestUri,
    UpdateManifestLoader? loader,
  }) : _loader = loader ?? _defaultLoader;

  final Uri? manifestUri;
  final UpdateManifestLoader _loader;

  Future<AppUpdateManifest> fetchLatestUpdateManifest() async {
    final Uri? manifestUri = this.manifestUri;
    if (manifestUri == null) {
      throw const UpdateManifestException('更新源尚未配置');
    }

    final String responseBody = await _loader(manifestUri);
    final Object? decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const UpdateManifestException('更新元数据格式无效');
    }

    final Object? platformsObject = decoded['platforms'];
    if (platformsObject is Map<String, dynamic>) {
      final Map<AppUpdatePlatform, AppUpdateInfo> platforms =
          _parsePlatformManifest(platformsObject);
      if (platforms.isEmpty) {
        throw const UpdateManifestException('更新元数据缺少有效的平台配置');
      }
      return AppUpdateManifest(platforms: platforms);
    }

    final Object? downloadsObject = decoded['downloads'];
    if (downloadsObject is! Map<String, dynamic>) {
      throw const UpdateManifestException('更新元数据缺少 downloads 配置');
    }

    return AppUpdateManifest(
      platforms: _parseLegacyManifest(decoded, downloadsObject),
    );
  }

  static Map<AppUpdatePlatform, AppUpdateInfo> _parsePlatformManifest(
    Map<String, dynamic> platformsObject,
  ) {
    final Map<AppUpdatePlatform, AppUpdateInfo> platforms =
        <AppUpdatePlatform, AppUpdateInfo>{};
    platformsObject.forEach((String platformKey, dynamic value) {
      final AppUpdatePlatform platform = _parsePlatform(platformKey);
      if (platform == AppUpdatePlatform.unsupported ||
          value is! Map<String, dynamic>) {
        return;
      }
      final String version = value['version']?.toString().trim() ?? '';
      if (version.isEmpty) {
        return;
      }
      final Object? downloadObject = value['download'];
      if (downloadObject is! Map<String, dynamic>) {
        return;
      }
      final AppUpdateTarget? target = _parseTarget(downloadObject);
      if (target == null) {
        return;
      }
      platforms[platform] = AppUpdateInfo(
        platform: platform,
        version: AppVersion.parse(
          version: version,
          buildNumber: value['buildNumber']?.toString() ?? '0',
        ),
        publishedAt: DateTime.tryParse(value['publishedAt']?.toString() ?? ''),
        requiredUpdate: value['required'] == true,
        notes: (value['notes'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => item.toString().trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
        target: target,
      );
    });
    return platforms;
  }

  static Map<AppUpdatePlatform, AppUpdateInfo> _parseLegacyManifest(
    Map<String, dynamic> decoded,
    Map<String, dynamic> downloadsObject,
  ) {
    final String version = decoded['version']?.toString().trim() ?? '';
    if (version.isEmpty) {
      throw const UpdateManifestException('更新元数据缺少 version 字段');
    }
    final String buildNumber =
        decoded['buildNumber']?.toString().trim().isNotEmpty ?? false
        ? decoded['buildNumber'].toString().trim()
        : '0';
    final DateTime? publishedAt = DateTime.tryParse(
      decoded['publishedAt']?.toString() ?? '',
    );
    final bool requiredUpdate = decoded['required'] == true;
    final List<String> notes =
        (decoded['notes'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => item.toString().trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false);

    final Map<AppUpdatePlatform, AppUpdateInfo> platforms =
        <AppUpdatePlatform, AppUpdateInfo>{};
    downloadsObject.forEach((String platformKey, dynamic value) {
      final AppUpdatePlatform platform = _parsePlatform(platformKey);
      if (platform == AppUpdatePlatform.unsupported ||
          value is! Map<String, dynamic>) {
        return;
      }
      final AppUpdateTarget? target = _parseTarget(value);
      if (target == null) {
        return;
      }
      platforms[platform] = AppUpdateInfo(
        platform: platform,
        version: AppVersion.parse(version: version, buildNumber: buildNumber),
        publishedAt: publishedAt,
        requiredUpdate: requiredUpdate,
        notes: notes,
        target: target,
      );
    });
    if (platforms.isEmpty) {
      throw const UpdateManifestException('更新元数据缺少有效的平台配置');
    }
    return platforms;
  }

  static AppUpdateTarget? _parseTarget(Map<String, dynamic> value) {
    final AppUpdateInstallMode mode = _parseMode(
      value['mode']?.toString() ?? '',
    );
    final Uri? url = _parseOptionalUri(value['url']);
    final Uri? feedUrl = _parseOptionalUri(value['feedUrl']);
    final Uri? fallbackUrl = _parseOptionalUri(value['fallbackUrl']);
    final List<AndroidApkVariant> variants = _parseAndroidVariants(
      value['variants'],
    );
    if (url == null &&
        feedUrl == null &&
        fallbackUrl == null &&
        variants.isEmpty) {
      return null;
    }
    return AppUpdateTarget(
      mode: mode,
      url: url,
      feedUrl: feedUrl,
      sha256: value['sha256']?.toString(),
      variants: variants,
      fallbackUrl: fallbackUrl,
      fallbackSha256: value['fallbackSha256']?.toString(),
    );
  }

  static List<AndroidApkVariant> _parseAndroidVariants(Object? variantsObject) {
    if (variantsObject is! List<dynamic>) {
      return const <AndroidApkVariant>[];
    }
    return variantsObject
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> item) {
          final String abi = item['abi']?.toString().trim() ?? '';
          final Uri? url = _parseOptionalUri(item['url']);
          if (abi.isEmpty || url == null) {
            return null;
          }
          return AndroidApkVariant(
            abi: abi,
            url: url,
            sha256: item['sha256']?.toString(),
          );
        })
        .whereType<AndroidApkVariant>()
        .toList(growable: false);
  }

  static Uri? _parseOptionalUri(Object? rawValue) {
    final String value = rawValue?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    return Uri.tryParse(value);
  }

  static AppUpdatePlatform _parsePlatform(String rawValue) {
    return switch (rawValue.trim().toLowerCase()) {
      'android' => AppUpdatePlatform.android,
      'ios' => AppUpdatePlatform.ios,
      'macos' => AppUpdatePlatform.macos,
      'windows' => AppUpdatePlatform.windows,
      _ => AppUpdatePlatform.unsupported,
    };
  }

  static AppUpdateInstallMode _parseMode(String rawValue) {
    return switch (rawValue.trim().toLowerCase()) {
      'apk' => AppUpdateInstallMode.apk,
      'appinstaller' => AppUpdateInstallMode.appinstaller,
      'sparkle' => AppUpdateInstallMode.sparkle,
      _ => AppUpdateInstallMode.external,
    };
  }

  static Future<String> _defaultLoader(Uri uri) async {
    final HttpClient httpClient = HttpClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      final HttpClientResponse response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw UpdateManifestException('更新请求失败（HTTP ${response.statusCode}）');
      }
      return response.transform(utf8.decoder).join();
    } finally {
      httpClient.close(force: true);
    }
  }
}

class UpdateManifestException implements Exception {
  const UpdateManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}
