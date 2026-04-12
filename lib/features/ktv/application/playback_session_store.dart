import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ktv2/ktv2.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/song.dart';

typedef PlaybackSessionFileProvider = Future<File> Function();

class PersistedPlaybackSession {
  const PersistedPlaybackSession({
    required this.queuedSongs,
    required this.playbackProgress,
    required this.wasPlaying,
    required this.audioOutputMode,
  });

  final List<Song> queuedSongs;
  final double playbackProgress;
  final bool wasPlaying;
  final AudioOutputMode audioOutputMode;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'queuedSongs': queuedSongs.map(_songToJson).toList(growable: false),
      'playbackProgress': playbackProgress,
      'wasPlaying': wasPlaying,
      'audioOutputMode': audioOutputMode.name,
    };
  }

  static PersistedPlaybackSession? fromJson(Map<Object?, Object?> json) {
    final Object? songsObject = json['queuedSongs'];
    final Object? progressObject = json['playbackProgress'];
    final Object? playingObject = json['wasPlaying'];
    final Object? audioModeObject = json['audioOutputMode'];
    if (songsObject is! List ||
        progressObject is! num ||
        playingObject is! bool ||
        audioModeObject is! String) {
      return null;
    }

    final List<Song> queuedSongs = songsObject
        .whereType<Map>()
        .map(
          (Map<Object?, Object?> item) => _songFromJson(
            item.map(
              (Object? key, Object? value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .whereType<Song>()
        .toList(growable: false);

    return PersistedPlaybackSession(
      queuedSongs: queuedSongs,
      playbackProgress: progressObject.toDouble().clamp(0.0, 1.0),
      wasPlaying: playingObject,
      audioOutputMode: AudioOutputMode.values.firstWhere(
        (AudioOutputMode mode) => mode.name == audioModeObject,
        orElse: () => AudioOutputMode.original,
      ),
    );
  }

  static Map<String, Object?> _songToJson(Song song) {
    return <String, Object?>{
      'songId': song.songId,
      'sourceId': song.sourceId,
      'sourceSongId': song.sourceSongId,
      'title': song.title,
      'artist': song.artist,
      'languages': song.languages,
      'tags': song.tags,
      'searchIndex': song.searchIndex,
      'mediaPath': song.mediaPath,
    };
  }

  static Song? _songFromJson(Map<String, Object?> json) {
    final String? songId = json['songId'] as String?;
    final String? sourceId = json['sourceId'] as String?;
    final String? sourceSongId = json['sourceSongId'] as String?;
    final String? title = json['title'] as String?;
    final String? artist = json['artist'] as String?;
    final String? searchIndex = json['searchIndex'] as String?;
    final String? mediaPath = json['mediaPath'] as String?;
    final Object? languagesObject = json['languages'];
    final Object? tagsObject = json['tags'];
    if (songId == null ||
        sourceId == null ||
        sourceSongId == null ||
        title == null ||
        artist == null ||
        searchIndex == null ||
        mediaPath == null ||
        languagesObject is! List) {
      return null;
    }

    final List<String> languages = languagesObject.whereType<String>().toList(
      growable: false,
    );
    if (languages.isEmpty) {
      return null;
    }

    final List<String> tags = tagsObject is List
        ? tagsObject.whereType<String>().toList(growable: false)
        : const <String>[];
    return Song(
      songId: songId,
      sourceId: sourceId,
      sourceSongId: sourceSongId,
      title: title,
      artist: artist,
      languages: languages,
      tags: tags,
      searchIndex: searchIndex,
      mediaPath: mediaPath,
    );
  }
}

class PlaybackSessionStore {
  PlaybackSessionStore({PlaybackSessionFileProvider? fileProvider})
    : _fileProvider = fileProvider ?? _createDefaultFileProvider();

  final PlaybackSessionFileProvider _fileProvider;
  static int _fallbackFileSeed = 0;

  Future<PersistedPlaybackSession?> loadSession() async {
    final File file = await _fileProvider();
    if (!await file.exists()) {
      return null;
    }
    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return null;
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final Object? sessionObject = decoded['session'];
    if (sessionObject is! Map) {
      return null;
    }
    return PersistedPlaybackSession.fromJson(sessionObject);
  }

  Future<void> saveSession(PersistedPlaybackSession session) async {
    final File file = await _fileProvider();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(<String, Object?>{'version': 1, 'session': session.toJson()}),
      flush: true,
    );
  }

  Future<void> clearSession() async {
    final File file = await _fileProvider();
    if (await file.exists()) {
      await file.delete();
    }
  }

  static PlaybackSessionFileProvider _createDefaultFileProvider() {
    File? resolvedFile;
    return () async {
      if (resolvedFile != null) {
        return resolvedFile!;
      }

      Directory supportDirectory;
      String fileName = 'playback_session.json';
      try {
        supportDirectory = await getApplicationSupportDirectory();
      } on MissingPluginException {
        supportDirectory = Directory.systemTemp;
        _fallbackFileSeed += 1;
        fileName =
            'playback_session_test_${DateTime.now().microsecondsSinceEpoch}_$_fallbackFileSeed.json';
      }

      final Directory storeDirectory = Directory(
        path.join(supportDirectory.path, 'ktv'),
      );
      if (!await storeDirectory.exists()) {
        await storeDirectory.create(recursive: true);
      }
      resolvedFile = File(path.join(storeDirectory.path, fileName));
      return resolvedFile!;
    };
  }
}
