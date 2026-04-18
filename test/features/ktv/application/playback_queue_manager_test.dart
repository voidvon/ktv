import 'package:flutter_test/flutter_test.dart';
import 'package:ktv2/ktv2.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/features/ktv/application/playable_song_resolver.dart';
import 'package:maimai_ktv/features/ktv/application/playback_queue_manager.dart';

import '../../../test_support/ktv_test_doubles.dart';

void main() {
  test('requestSong starts playback when there is no current media', () async {
    final FakePlayerController playerController = FakePlayerController();
    final Song song = buildLocalSong(
      title: '七里香',
      artist: '周杰伦',
      mediaPath: '/music/qilixiang.mp4',
    );
    final PlaybackQueueManager manager = PlaybackQueueManager(
      playerController: playerController,
      playableSongResolver: _FakePlayableSongResolver(),
    );

    final List<Song> nextQueue = await manager.requestSong(<Song>[], song);

    expect(nextQueue, <Song>[song]);
    expect(playerController.currentMediaPath, '/music/qilixiang.mp4');
    expect(playerController.isPlaying, isTrue);
  });

  test('skipCurrentSong jumps to the next playable queued song', () async {
    final FakePlayerController playerController = FakePlayerController();
    final PlaybackQueueManager manager = PlaybackQueueManager(
      playerController: playerController,
      playableSongResolver: _FakePlayableSongResolver(),
    );
    final Song currentSong = buildLocalSong(
      title: '夜曲',
      artist: '周杰伦',
      mediaPath: '/music/yequ.mp4',
    );
    final Song pendingSong = buildRemoteSong(
      title: '待下载',
      artist: '歌手甲',
      sourceId: 'baidu_pan',
      sourceSongId: 'pending',
    );
    final Song nextSong = buildLocalSong(
      title: '晴天',
      artist: '周杰伦',
      mediaPath: '/music/qingtian.mp4',
    );

    await playerController.openMedia(
      const MediaSource(path: '/music/yequ.mp4', displayName: '夜曲'),
    );
    final List<Song> nextQueue = await manager.skipCurrentSong(<Song>[
      currentSong,
      pendingSong,
      nextSong,
    ], canPlaySong: (Song song) => song.sourceId == 'local');

    expect(nextQueue, <Song>[nextSong, pendingSong]);
    expect(playerController.currentMediaPath, '/music/qingtian.mp4');
  });
}

class _FakePlayableSongResolver implements PlayableSongResolver {
  @override
  Future<PlayableMediaResolution> resolve(Song song) async {
    return PlayableMediaResolution(
      song: song,
      localPath: song.mediaPath,
      displayName: song.title,
    );
  }
}
