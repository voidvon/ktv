import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_playback_cache.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_song_download_service.dart';
import 'package:maimai_ktv/features/media_library/data/cloud/cloud_playback_cache.dart';

import '../../../../test_support/ktv_test_doubles.dart';

void main() {
  test(
    'downloadSong returns a BaiduPanDownloadResult and saves the file',
    () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'baidu-pan-download-test-',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final File cacheFile = File('${tempDir.path}/cache.mp4')
        ..writeAsStringSync('video-bytes');
      final BaiduPanSongDownloadService service = BaiduPanSongDownloadService(
        playbackCache: _FakeBaiduPanPlaybackCache(cacheFile.path),
        fallbackDirectoryProvider: () async => tempDir,
        downloadIndexFileProvider: () async =>
            File('${tempDir.path}/index.json'),
      );
      final Song song = buildRemoteSong(
        title: '青花瓷',
        artist: '周杰伦',
        sourceId: 'baidu_pan',
        sourceSongId: 'song-1',
      );

      final BaiduPanDownloadResult result = await service.downloadSong(
        song: song,
      );

      expect(result, isA<BaiduPanDownloadResult>());
      expect(await File(result.savedPath).exists(), isTrue);
      expect(result.usedPreferredDirectory, isFalse);
    },
  );
}

class _FakeBaiduPanPlaybackCache implements BaiduPanPlaybackCache {
  const _FakeBaiduPanPlaybackCache(this.localPath);

  final String localPath;

  @override
  Future<BaiduPanCachedMedia> resolve({
    required Song song,
    required String sourceSongId,
    void Function(double progress)? onProgress,
    CloudDownloadCancellationToken? cancellationToken,
  }) async {
    return BaiduPanCachedMedia(localPath: localPath, displayName: song.title);
  }

  @override
  Future<void> clearExpiredCache() async {}
}
