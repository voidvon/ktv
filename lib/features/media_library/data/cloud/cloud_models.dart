class CloudAuthToken {
  const CloudAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMillis,
    this.scope,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresAtMillis;
  final String? scope;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= expiresAtMillis;

  bool willExpireWithin(Duration duration) {
    final int thresholdMillis = DateTime.now()
        .add(duration)
        .millisecondsSinceEpoch;
    return expiresAtMillis <= thresholdMillis;
  }
}

class CloudSourceConfig {
  const CloudSourceConfig({
    required this.sourceRootId,
    required this.rootPath,
    required this.displayName,
    this.syncToken,
    this.lastSyncedAtMillis,
  });

  final String sourceRootId;
  final String rootPath;
  final String displayName;
  final String? syncToken;
  final int? lastSyncedAtMillis;
}

class CloudAppCredentials {
  const CloudAppCredentials({
    required this.appId,
    required this.appKey,
    required this.secretKey,
    required this.signKey,
    this.redirectUri = 'oob',
    this.scope = 'basic',
  });

  final String appId;
  final String appKey;
  final String secretKey;
  final String signKey;
  final String redirectUri;
  final String scope;

  bool get isComplete =>
      appId.trim().isNotEmpty &&
      appKey.trim().isNotEmpty &&
      secretKey.trim().isNotEmpty &&
      signKey.trim().isNotEmpty;
}

class CloudRemoteFile {
  const CloudRemoteFile({
    required this.fileId,
    required this.path,
    required this.serverFilename,
    required this.isDirectory,
    required this.size,
    required this.modifiedAtMillis,
    this.md5,
    this.category,
    this.dlink,
    this.rawPayload,
  });

  final String fileId;
  final String path;
  final String serverFilename;
  final bool isDirectory;
  final int size;
  final int modifiedAtMillis;
  final String? md5;
  final int? category;
  final String? dlink;
  final Map<String, Object?>? rawPayload;
}

class CloudUserInfo {
  const CloudUserInfo({
    required this.accountId,
    required this.displayName,
    this.avatarUrl,
    this.accountTier,
  });

  final String accountId;
  final String displayName;
  final String? avatarUrl;
  final int? accountTier;
}

class CloudQuotaInfo {
  const CloudQuotaInfo({
    required this.totalBytes,
    required this.usedBytes,
    this.freeBytes,
  });

  final int totalBytes;
  final int usedBytes;
  final int? freeBytes;

  int get availableBytes =>
      freeBytes ?? (totalBytes - usedBytes).clamp(0, totalBytes);
}
