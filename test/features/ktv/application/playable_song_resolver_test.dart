import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/features/ktv/application/playable_song_resolver.dart';
import 'package:maimai_ktv/features/media_library/data/cloud/cloud_playback_cache.dart';

import '../../../test_support/ktv_test_doubles.dart';

void main() {
  test('resolves local songs directly from their media path', () async {
    final Song song = buildLocalSong(
      title: '晴天',
      artist: '周杰伦',
      mediaPath: '/music/qingtian.mp4',
    );
    const DefaultPlayableSongResolver resolver = DefaultPlayableSongResolver();

    final PlayableMediaResolution result = await resolver.resolve(song);

    expect(result.localPath, '/music/qingtian.mp4');
    expect(result.displayName, '晴天');
    expect(result.cacheHit, isFalse);
  });

  test('uses a configured cloud playback cache for remote songs', () async {
    final Song song = buildRemoteSong(
      title: '搁浅',
      artist: '周杰伦',
      sourceId: '115',
      sourceSongId: '115-song-1',
    );
    final DefaultPlayableSongResolver resolver = DefaultPlayableSongResolver(
      cloudPlaybackCaches: <String, CloudPlaybackCache>{
        '115': const _FakeCloudPlaybackCache(),
      },
    );

    final PlayableMediaResolution result = await resolver.resolve(song);

    expect(result.localPath, '/tmp/cloud-cache.mp4');
    expect(result.displayName, 'cloud-cache.mp4');
    expect(result.cacheHit, isTrue);
  });
}

class _FakeCloudPlaybackCache implements CloudPlaybackCache {
  const _FakeCloudPlaybackCache();

  @override
  Future<CloudCachedMedia> resolve({
    required Song song,
    required String sourceSongId,
    void Function(double progress)? onProgress,
    CloudDownloadCancellationToken? cancellationToken,
  }) async {
    return const CloudCachedMedia(
      localPath: '/tmp/cloud-cache.mp4',
      displayName: 'cloud-cache.mp4',
      cacheHit: true,
    );
  }

  @override
  Future<void> clearExpiredCache() async {}
}
