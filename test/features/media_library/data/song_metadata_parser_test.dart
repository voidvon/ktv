import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/song_metadata_parser.dart';

void main() {
  const SongMetadataParser parser = SongMetadataParser();

  test('parses artist, title, language, and tags from filenames', () {
    final ParsedSongMetadata metadata = parser.parseFileName(
      '周杰伦-青花瓷-国语-Live.mp4',
    );

    expect(metadata.artist, '周杰伦');
    expect(metadata.title, '青花瓷');
    expect(metadata.languages, <String>['国语']);
    expect(metadata.tags, <String>['Live']);
  });

  test('keeps whitelisted hyphenated artist names intact', () {
    final ParsedSongMetadata metadata = parser.parseFileName(
      'A-Lin-给我一个理由忘记-国语.mv',
    );

    expect(metadata.artist, 'A-Lin');
    expect(metadata.title, '给我一个理由忘记');
    expect(metadata.languages, <String>['国语']);
  });

  test('falls back to an unknown artist for single-segment names', () {
    final ParsedSongMetadata metadata = parser.parseFileName('青花瓷.mp4');

    expect(metadata.artist, '未识别歌手');
    expect(metadata.title, '青花瓷');
    expect(metadata.languages, <String>['其它']);
  });
}
