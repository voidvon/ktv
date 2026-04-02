import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SongProfileDatabase {
  SongProfileDatabase();

  static const String tableName = 'song_profiles';
  static const String columnMediaPath = 'media_path';
  static const String columnDirectoryPath = 'directory_path';
  static const String columnTitle = 'title';
  static const String columnArtist = 'artist';
  static const String columnLanguages = 'languages';
  static const String columnTags = 'tags';
  static const String columnSearchIndex = 'search_index';
  static const String columnIsFavorite = 'is_favorite';
  static const String columnFavoritedAt = 'favorited_at';
  static const String columnPlayCount = 'play_count';
  static const String columnLastPlayedAt = 'last_played_at';
  static const String columnLastRequestedAt = 'last_requested_at';
  static const String columnUpdatedAt = 'updated_at';

  Future<Database>? _database;

  Future<Database> get database => _database ??= _openDatabase();

  Future<void> close() async {
    final Future<Database>? databaseFuture = _database;
    _database = null;
    if (databaseFuture == null) {
      return;
    }
    final Database openedDatabase = await databaseFuture;
    await openedDatabase.close();
  }

  Future<Database> _openDatabase() async {
    if (!kIsWeb &&
        !Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isFuchsia) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory supportDirectory = await getApplicationSupportDirectory();
    final String databasePath = path.join(
      supportDirectory.path,
      'ktv_song_profiles.db',
    );

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            $columnMediaPath TEXT PRIMARY KEY,
            $columnDirectoryPath TEXT NOT NULL,
            $columnTitle TEXT NOT NULL,
            $columnArtist TEXT NOT NULL,
            $columnLanguages TEXT NOT NULL,
            $columnTags TEXT NOT NULL,
            $columnSearchIndex TEXT NOT NULL,
            $columnIsFavorite INTEGER NOT NULL DEFAULT 0,
            $columnFavoritedAt INTEGER,
            $columnPlayCount INTEGER NOT NULL DEFAULT 0,
            $columnLastPlayedAt INTEGER,
            $columnLastRequestedAt INTEGER,
            $columnUpdatedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX song_profiles_directory_favorite_idx
          ON $tableName($columnDirectoryPath, $columnIsFavorite, $columnFavoritedAt)
        ''');
        await db.execute('''
          CREATE INDEX song_profiles_directory_frequent_idx
          ON $tableName($columnDirectoryPath, $columnPlayCount, $columnLastPlayedAt)
        ''');
      },
    );
  }
}
