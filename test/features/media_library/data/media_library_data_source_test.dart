import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/media_library_data_source.dart';

void main() {
  test(
    'scanLibrary includes common video formats and skips non-video files',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'ktv_media_library_test_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final List<String> supportedFiles = <String>[
        'Singer A - Song A.mp4',
        'Singer B - Song B.MKV',
        'Singer C - Song C.avi',
        'Singer D - Song D.dat',
        'Singer E - Song E.rmvb',
        'Singer F - Song F.mpg',
        'Singer G - Song G.webm',
        'Singer H - Song H.wmv',
      ];
      final List<String> unsupportedFiles = <String>[
        'Singer X - Song X.txt',
        'Singer Y - Song Y.jpg',
        'Singer Z - Song Z.lrc',
      ];

      for (final String fileName in supportedFiles.followedBy(
        unsupportedFiles,
      )) {
        await File('${directory.path}/$fileName').writeAsString('sample');
      }

      final MediaLibraryDataSource dataSource = MediaLibraryDataSource();
      final List<LibrarySong> songs = await dataSource.scanLibrary(
        directory.path,
      );

      expect(
        songs.map((LibrarySong song) => song.fileName).toSet(),
        supportedFiles.toSet(),
      );
    },
  );
}

