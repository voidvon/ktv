import 'dart:async';

import 'package:ktv2/ktv2.dart';

import '../../../core/models/song.dart';
import 'playable_song_resolver.dart';

class PlaybackQueueManager {
  const PlaybackQueueManager({
    required this.playerController,
    this.playableSongResolver = const DefaultPlayableSongResolver(),
  });

  final PlayerController playerController;
  final PlayableSongResolver playableSongResolver;

  Future<List<Song>> requestSong(List<Song> queuedSongs, Song song) async {
    final List<Song> nextQueue = List<Song>.of(queuedSongs);
    final bool hasCurrentSong =
        nextQueue.isNotEmpty && playerController.hasMedia;

    if (hasCurrentSong) {
      if (nextQueue.contains(song)) {
        return nextQueue;
      }
      nextQueue.add(song);
      return nextQueue;
    }

    nextQueue
      ..remove(song)
      ..insert(0, song);
    final PlayableMediaResolution media = await playableSongResolver.resolve(
      song,
    );
    await playerController.openMedia(
      MediaSource(path: media.localPath, displayName: media.displayName),
    );
    return nextQueue;
  }

  List<Song> prioritizeQueuedSong(List<Song> queuedSongs, Song song) {
    final List<Song> nextQueue = List<Song>.of(queuedSongs);
    final int currentIndex = nextQueue.indexOf(song);
    final int targetIndex = playerController.hasMedia ? 1 : 0;
    if (currentIndex <= targetIndex) {
      return nextQueue;
    }
    nextQueue
      ..removeAt(currentIndex)
      ..insert(targetIndex, song);
    return nextQueue;
  }

  List<Song> removeQueuedSong(List<Song> queuedSongs, Song song) {
    final List<Song> nextQueue = List<Song>.of(queuedSongs);
    final int currentIndex = nextQueue.indexOf(song);
    if (currentIndex <= 0) {
      return nextQueue;
    }
    nextQueue.removeAt(currentIndex);
    return nextQueue;
  }

  void togglePlayback() {
    if (!playerController.hasMedia) {
      return;
    }
    unawaited(playerController.togglePlayback());
  }

  void toggleAudioMode() {
    if (!playerController.hasMedia) {
      return;
    }
    unawaited(playerController.toggleAudioOutputMode());
  }

  void restartPlayback() {
    if (!playerController.hasMedia) {
      return;
    }
    unawaited(_restartPlayback());
  }

  Future<void> _restartPlayback() async {
    await playerController.seekToProgress(0);
    if (!playerController.isPlaying) {
      await playerController.togglePlayback();
    }
  }

  Future<List<Song>> skipCurrentSong(
    List<Song> queuedSongs, {
    required bool Function(Song song) canPlaySong,
  }) async {
    if (!playerController.hasMedia && queuedSongs.isEmpty) {
      return queuedSongs;
    }

    final List<Song> remainingQueue = List<Song>.of(queuedSongs);
    if (remainingQueue.isNotEmpty) {
      remainingQueue.removeAt(0);
    }

    if (remainingQueue.isEmpty) {
      return queuedSongs;
    }

    final int nextPlayableIndex = remainingQueue.indexWhere(canPlaySong);
    if (nextPlayableIndex < 0) {
      return queuedSongs;
    }
    if (nextPlayableIndex > 0) {
      final Song nextPlayableSong = remainingQueue.removeAt(nextPlayableIndex);
      remainingQueue.insert(0, nextPlayableSong);
    }

    final Song nextSong = remainingQueue.first;
    final PlayableMediaResolution media = await playableSongResolver.resolve(
      nextSong,
    );
    await playerController.openMedia(
      MediaSource(path: media.localPath, displayName: media.displayName),
    );
    return remainingQueue;
  }

  Future<void> stopPlayback() {
    return playerController.stopPlayback();
  }
}
