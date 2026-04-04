import 'dart:io';
import 'dart:convert';

import 'package:lpinyin/lpinyin.dart';
import 'package:path/path.dart' as path;
import 'package:ktv2_example/core/media/supported_video_formats.dart';

import '../../../core/models/song_identity.dart';
import 'media_index_store.dart';

class MediaLibraryDataSource {
  static const List<String> _artistHyphenWhitelist = <String>[
    'A-Lin',
    'G-DRAGON',
    'T-ara',
  ];

  static const Map<String, String> _languageKeywordMap = <String, String>{
    '国语': '国语',
    '普通话': '国语',
    '华语': '国语',
    '粤语': '粤语',
    '广东话': '粤语',
    '白话': '粤语',
    '闽南语': '闽南语',
    '闽南话': '闽南语',
    '台语': '闽南语',
    '福建话': '闽南语',
    '英语': '英语',
    '英文': '英语',
    '日语': '日语',
    '日文': '日语',
    '韩语': '韩语',
    '韩文': '韩语',
    '客语': '客语',
    '客家话': '客语',
  };

  static const Map<String, String> _tagKeywordMap = <String, String>{
    '流行': '流行',
    '流行音乐': '流行',
    '流行歌曲': '流行',
    '经典': '经典',
    '经典老歌': '经典',
    '怀旧': '经典',
    '摇滚': '摇滚',
    '摇滚乐': '摇滚',
    '民谣': '民谣',
    '校园民谣': '民谣',
    '舞曲': '舞曲',
    '劲爆': '舞曲',
    '嗨歌': '舞曲',
    'dj': 'DJ',
    '电音': 'DJ',
    '情歌': '情歌',
    '抒情': '情歌',
    '儿歌': '儿歌',
    '童谣': '儿歌',
    '戏曲': '戏曲',
    '黄梅戏': '戏曲',
    '京剧': '戏曲',
    '越剧': '戏曲',
    '对唱': '对唱',
    '合唱': '合唱',
    '现场版': '现场版',
    'live': 'Live',
    '演唱会': '演唱会',
    'mv': 'MV',
    '伴奏版': '伴奏版',
    '原版': '原版',
    '重制版': '重制版',
    '单音轨': '单音轨',
    '双音轨': '双音轨',
  };

  Future<List<LibrarySong>> scanLibrary(
    String rootPath, {
    Map<String, CachedLocalSongFingerprint> cachedFingerprintsByPath =
        const <String, CachedLocalSongFingerprint>{},
  }) async {
    final Directory directory = Directory(rootPath);
    if (!await directory.exists()) {
      throw FileSystemException('媒体库目录不存在', rootPath);
    }

    final List<LibrarySong> songs = <LibrarySong>[];
    final List<Directory> directories = <Directory>[directory];

    while (directories.isNotEmpty) {
      final Directory current = directories.removeLast();
      List<FileSystemEntity> entities;

      try {
        entities = await current.list(followLinks: false).toList();
      } on FileSystemException {
        continue;
      }

      for (final FileSystemEntity entity in entities) {
        if (entity is Directory) {
          directories.add(entity);
          continue;
        }

        if (entity is! File) {
          continue;
        }

        final FileStat stat = await entity.stat();

        final String fileName = _extractFileName(entity.path);
        final String extension = extractVideoExtension(fileName);
        if (!supportedVideoExtensionSet.contains(extension)) {
          continue;
        }

        final _ParsedName metadata = _parseFileName(fileName);
        final String relativePathValue = path.relative(
          entity.path,
          from: rootPath,
        );
        final CachedLocalSongFingerprint? cachedFingerprint =
            cachedFingerprintsByPath[entity.path] ??
            cachedFingerprintsByPath[relativePathValue];
        final String sourceFingerprint = await _buildLocalSourceFingerprint(
          entity,
          stat,
          cachedFingerprint: cachedFingerprint,
        );
        songs.add(
          LibrarySong(
            title: metadata.title,
            artist: metadata.artist,
            mediaPath: entity.path,
            fileName: fileName,
            relativePath: relativePathValue,
            fileSize: stat.size,
            modifiedAtMillis: stat.modified.millisecondsSinceEpoch,
            sourceFingerprint: sourceFingerprint,
            extension: extension,
            languages: metadata.languages,
            tags: metadata.tags,
          ),
        );
      }
    }

    songs.sort((LibrarySong left, LibrarySong right) {
      final int titleCompare = left.title.compareTo(right.title);
      if (titleCompare != 0) {
        return titleCompare;
      }
      return left.artist.compareTo(right.artist);
    });

    return songs;
  }

  String _extractFileName(String path) {
    final String normalizedPath = path.replaceAll('\\', '/');
    return normalizedPath.split('/').last;
  }

  _ParsedName _parseFileName(String fileName) {
    final int dotIndex = fileName.lastIndexOf('.');
    final String baseName = dotIndex == -1
        ? fileName
        : fileName.substring(0, dotIndex);

    final List<String> segments = _splitSegments(baseName);
    if (segments.length < 2) {
      return _ParsedName(
        title: baseName.trim(),
        artist: '未识别歌手',
        languages: const <String>['其它'],
        tags: const <String>[],
      );
    }

    final int artistSegmentCount = _resolveArtistSegmentCount(segments);
    final String artist = segments.take(artistSegmentCount).join('-').trim();
    if (artist.isEmpty) {
      return _ParsedName(
        title: baseName.trim(),
        artist: '未识别歌手',
        languages: const <String>['其它'],
        tags: const <String>[],
      );
    }

    final List<String> reversedLanguages = <String>[];
    final List<String> reversedTags = <String>[];
    int titleEndExclusive = segments.length;
    for (
      int index = segments.length - 1;
      index >= artistSegmentCount;
      index--
    ) {
      final String? normalizedKeyword = _normalizeKeyword(segments[index]);
      if (normalizedKeyword == null) {
        break;
      }
      final String? language = _languageKeywordMap[normalizedKeyword];
      if (language != null) {
        _appendUnique(reversedLanguages, language);
        titleEndExclusive = index;
        continue;
      }
      final String? tag = _tagKeywordMap[normalizedKeyword];
      if (tag != null) {
        _appendUnique(reversedTags, tag);
        titleEndExclusive = index;
        continue;
      }
      break;
    }

    final List<String> titleSegments = segments.sublist(
      artistSegmentCount,
      titleEndExclusive,
    );
    final String title = titleSegments.join('-').trim();
    return _ParsedName(
      title: title.isEmpty ? baseName.trim() : title,
      artist: artist,
      languages: reversedLanguages.isEmpty
          ? const <String>['其它']
          : reversedLanguages.reversed.toList(growable: false),
      tags: reversedTags.reversed.toList(growable: false),
    );
  }

  List<String> _splitSegments(String baseName) {
    final String normalized = baseName
        .replaceAll(' - ', '-')
        .replaceAll(' — ', '-')
        .replaceAll(' – ', '-')
        .trim();
    return normalized
        .split('-')
        .map((String segment) => segment.trim())
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);
  }

  int _resolveArtistSegmentCount(List<String> segments) {
    for (int count = segments.length - 1; count >= 1; count--) {
      final String candidate = segments.take(count).join('-');
      if (_artistHyphenWhitelist.contains(candidate) &&
          segments.length - count >= 1) {
        return count;
      }
    }
    return 1;
  }

  String? _normalizeKeyword(String rawSegment) {
    String normalized = _stripTrailingNoise(rawSegment.trim());
    if (normalized.isEmpty) {
      return null;
    }
    normalized = _normalizeFullWidth(normalized)
        .replaceAll('國語', '国语')
        .replaceAll('粵語', '粤语')
        .replaceAll('廣東話', '广东话')
        .replaceAll('閩南語', '闽南语')
        .replaceAll('閩南話', '闽南话')
        .replaceAll('臺語', '台语')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized.toLowerCase();
  }

  String _stripTrailingNoise(String rawSegment) {
    String value = rawSegment.trim();
    if (value.isEmpty) {
      return value;
    }
    final List<RegExp> patterns = <RegExp>[
      RegExp(r'[_ ]?副本(?:\(\d+\))?$', caseSensitive: false),
      RegExp(r'[_ ]?copy$', caseSensitive: false),
      RegExp(r'\(\d+\)$'),
    ];
    bool changed = true;
    while (changed && value.isNotEmpty) {
      changed = false;
      for (final RegExp pattern in patterns) {
        final String nextValue = value.replaceFirst(pattern, '').trim();
        if (nextValue != value) {
          value = nextValue;
          changed = true;
        }
      }
    }
    return value;
  }

  String _normalizeFullWidth(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int codePoint in input.runes) {
      if (codePoint == 0x3000) {
        buffer.writeCharCode(0x20);
        continue;
      }
      if (codePoint >= 0xFF01 && codePoint <= 0xFF5E) {
        buffer.writeCharCode(codePoint - 0xFEE0);
        continue;
      }
      buffer.writeCharCode(codePoint);
    }
    return buffer.toString();
  }

  void _appendUnique(List<String> values, String value) {
    if (!values.contains(value)) {
      values.add(value);
    }
  }

  Future<String> _buildLocalSourceFingerprint(
    File file,
    FileStat stat, {
    CachedLocalSongFingerprint? cachedFingerprint,
  }) async {
    if (cachedFingerprint != null &&
        cachedFingerprint.matches(
          nextFileSize: stat.size,
          nextModifiedAtMillis: stat.modified.millisecondsSinceEpoch,
        ) &&
        cachedFingerprint.sourceFingerprint.trim().isNotEmpty) {
      return cachedFingerprint.sourceFingerprint;
    }
    try {
      const int chunkSize = 64 * 1024;
      final int fileSize = stat.size;
      final RandomAccessFile randomAccessFile = await file.open();
      try {
        final List<List<int>> chunks = <List<int>>[
          utf8.encode('v1:$fileSize:'),
        ];
        final int headSize = fileSize < chunkSize ? fileSize : chunkSize;
        if (headSize > 0) {
          chunks.add(await randomAccessFile.read(headSize));
        }
        if (fileSize > chunkSize) {
          final int tailSize = fileSize <= chunkSize * 2
              ? fileSize - headSize
              : chunkSize;
          if (tailSize > 0) {
            await randomAccessFile.setPosition(fileSize - tailSize);
            chunks.add(await randomAccessFile.read(tailSize));
          }
        }
        final int hashValue = _computeFnv1a64(chunks);
        final String hashText = hashValue
            .toUnsigned(64)
            .toRadixString(16)
            .padLeft(16, '0');
        return 'content:$fileSize:$hashText';
      } finally {
        await randomAccessFile.close();
      }
    } on FileSystemException {
      return buildLocalMetadataFingerprint(
        locator: file.path,
        fileSize: stat.size,
        modifiedAtMillis: stat.modified.millisecondsSinceEpoch,
      );
    }
  }
}

class LibrarySong {
  const LibrarySong({
    required this.title,
    required this.artist,
    required this.mediaPath,
    required this.fileName,
    required this.relativePath,
    required this.fileSize,
    required this.modifiedAtMillis,
    required this.sourceFingerprint,
    required this.extension,
    this.languages = const <String>['其它'],
    this.tags = const <String>[],
  });

  final String title;
  final String artist;
  final String mediaPath;
  final String fileName;
  final String relativePath;
  final int fileSize;
  final int modifiedAtMillis;
  final String sourceFingerprint;
  final String extension;
  final List<String> languages;
  final List<String> tags;

  String get sourceSongId =>
      buildLocalSourceSongId(fingerprint: sourceFingerprint);

  String get searchIndex {
    final String raw =
        '$title $artist ${languages.join(' ')} ${tags.join(' ')} $fileName $extension'
            .toLowerCase();
    final String titleInitials = _buildPinyinInitials(title);
    final String artistInitials = _buildPinyinInitials(artist);
    return '$raw $titleInitials $artistInitials'.trim();
  }
}

int _computeFnv1a64(Iterable<List<int>> chunks) {
  const int offsetBasis = 0xcbf29ce484222325;
  const int prime = 0x100000001b3;
  const int mask = 0xffffffffffffffff;
  int hash = offsetBasis;
  for (final List<int> chunk in chunks) {
    for (final int byte in chunk) {
      hash ^= byte & 0xff;
      hash = (hash * prime) & mask;
    }
  }
  return hash;
}

String _buildPinyinInitials(String source) {
  final String normalizedSource = source.trim();
  if (normalizedSource.isEmpty) {
    return '';
  }

  // Intentionally use only initials, not full pinyin.
  final String initials = PinyinHelper.getShortPinyin(
    normalizedSource,
  ).toLowerCase();
  return initials.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _ParsedName {
  const _ParsedName({
    required this.title,
    required this.artist,
    required this.languages,
    required this.tags,
  });

  final String title;
  final String artist;
  final List<String> languages;
  final List<String> tags;
}
