import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_models.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_song_mapper.dart';

void main() {
  final BaiduPanSongMapper mapper = BaiduPanSongMapper();
  final BaiduPanRemoteFile file = BaiduPanRemoteFile(
    fsid: 'fsid-1',
    path: '/KTV/周杰伦-青花瓷-国语-Live.mp4',
    serverFilename: '周杰伦-青花瓷-国语-Live.mp4',
    isDirectory: false,
    size: 1024,
    modifiedAtMillis: 1,
    md5: 'abc123',
    rawPayload: const <String, Object?>{'fsid': 'fsid-1'},
  );

  test('mapRemoteFileToSong parses metadata into a Song model', () {
    final song = mapper.mapRemoteFileToSong(file);

    expect(song.sourceId, 'baidu_pan');
    expect(song.sourceSongId, 'fsid-1');
    expect(song.title, '青花瓷');
    expect(song.artist, '周杰伦');
    expect(song.languages, <String>['国语']);
    expect(song.tags, <String>['Live']);
  });

  test('mapRemoteFileToSourceRecord preserves storage metadata', () {
    final record = mapper.mapRemoteFileToSourceRecord(
      file: file,
      sourceRootId: 'baidu_pan:/KTV',
    );

    expect(record.sourceType, 'baidu_pan');
    expect(record.sourceRootId, 'baidu_pan:/KTV');
    expect(record.fileFingerprint, 'md5:abc123');
    expect(record.mediaLocator, '/KTV/周杰伦-青花瓷-国语-Live.mp4');
  });
}
