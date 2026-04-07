import '../../../../core/models/song.dart';

class CloudCachedMedia {
  const CloudCachedMedia({
    required this.localPath,
    required this.displayName,
    this.cacheHit = false,
  });

  final String localPath;
  final String displayName;
  final bool cacheHit;
}

abstract class CloudPlaybackCache {
  Future<CloudCachedMedia> resolve({
    required Song song,
    required String sourceSongId,
  });

  Future<void> clearExpiredCache();
}
