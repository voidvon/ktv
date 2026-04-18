import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/core/models/song_identity.dart';
import 'package:maimai_ktv/features/ktv/application/playable_song_resolver.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_playback_cache.dart';
import 'package:maimai_ktv/features/media_library/data/cloud/cloud_playback_cache.dart';

void main() {
  test('local song uses media path directly', () async {
    final DefaultPlayableSongResolver resolver =
        const DefaultPlayableSongResolver();
    final Song song = _song(
      title: '闈掕姳鐡?,
      sourceId: 'local',
      sourceSongId: 'local-1',
      mediaPath: '/tmp/qinghua.mp4',
    );

    final PlayableMediaResolution media = await resolver.resolve(song);

    expect(media.localPath, '/tmp/qinghua.mp4');
    expect(media.displayName, '闈掕姳鐡?);
    expect(media.cacheHit, isFalse);
  });

  test('baidu pan song resolves from playback cache', () async {
    final _FakeBaiduPanPlaybackCache cache = _FakeBaiduPanPlaybackCache();
    final DefaultPlayableSongResolver resolver = DefaultPlayableSongResolver(
      baiduPanPlaybackCache: cache,
    );
    final Song song = _song(
      title: '澶滄洸',
      sourceId: 'baidu_pan',
      sourceSongId: 'fsid-88',
      mediaPath: '',
    );

    final PlayableMediaResolution media = await resolver.resolve(song);

    expect(cache.lastSourceSongId, 'fsid-88');
    expect(media.localPath, '/cache/yequ.mp4');
    expect(media.displayName, '缂撳瓨澶滄洸');
    expect(media.cacheHit, isTrue);
  });
}

Song _song({
  required String title,
  required String sourceId,
  required String sourceSongId,
  required String mediaPath,
}) {
  return Song(
    songId: buildAggregateSongId(title: title, artist: '鍛ㄦ澃浼?),
    sourceId: sourceId,
    sourceSongId: sourceSongId,
    title: title,
    artist: '鍛ㄦ澃浼?,
    languages: const <String>['鍥借'],
    searchIndex: title.toLowerCase(),
    mediaPath: mediaPath,
  );
}

class _FakeBaiduPanPlaybackCache implements BaiduPanPlaybackCache {
  String? lastSourceSongId;

  @override
  Future<void> clearExpiredCache() async {}

  @override
  Future<BaiduPanCachedMedia> resolve({
    required Song song,
    required String sourceSongId,
    void Function(double progress)? onProgress,
    CloudDownloadCancellationToken? cancellationToken,
  }) async {
    lastSourceSongId = sourceSongId;
    return const BaiduPanCachedMedia(
      localPath: '/cache/yequ.mp4',
      displayName: '缂撳瓨澶滄洸',
      cacheHit: true,
    );
  }
}

