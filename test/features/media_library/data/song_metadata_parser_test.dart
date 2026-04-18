import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/song_metadata_parser.dart';

void main() {
  const SongMetadataParser parser = SongMetadataParser();

  test('parseFileName extracts artist title language and tags', () {
    final ParsedSongMetadata metadata = parser.parseFileName(
      '鍛ㄦ澃浼?闈掕姳鐡?鍥借-娴佽.mp4',
    );

    expect(metadata.artist, '鍛ㄦ澃浼?);
    expect(metadata.title, '闈掕姳鐡?);
    expect(metadata.languages, <String>['鍥借']);
    expect(metadata.tags, <String>['娴佽']);
  });

  test('parseFileName keeps hyphenated artist aliases', () {
    final ParsedSongMetadata metadata = parser.parseFileName(
      'A-Lin-缁欐垜涓€涓悊鐢卞繕璁?鍥借.mp4',
    );

    expect(metadata.artist, 'A-Lin');
    expect(metadata.title, '缁欐垜涓€涓悊鐢卞繕璁?);
    expect(metadata.languages, <String>['鍥借']);
  });

  test('parseFileName strips trailing copy noise from suffix keywords', () {
    final ParsedSongMetadata metadata = parser.parseFileName(
      'Beyond-娴烽様澶╃┖-鍥借-娴佽-鍓湰(2).mp4',
    );

    expect(metadata.artist, 'Beyond');
    expect(metadata.title, '娴烽様澶╃┖');
    expect(metadata.languages, <String>['鍥借']);
    expect(metadata.tags, <String>['娴佽']);
  });
}

