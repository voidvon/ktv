import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final _ManifestUpdateOptions options = _ManifestUpdateOptions.parse(
    arguments,
  );
  final File manifestFile = File(options.filePath);
  final Map<String, Object?> root = _readRootObject(manifestFile);
  final Map<String, Object?> platforms =
      (root['platforms'] as Map?)?.cast<String, Object?>() ??
      <String, Object?>{};

  platforms[options.platform] = options.toPlatformEntry();
  root['platforms'] = platforms;

  manifestFile.parent.createSync(recursive: true);
  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(root),
  );
}

Map<String, Object?> _readRootObject(File manifestFile) {
  if (!manifestFile.existsSync()) {
    return <String, Object?>{};
  }
  final String content = manifestFile.readAsStringSync().trim();
  if (content.isEmpty) {
    return <String, Object?>{};
  }
  final Object? decoded = jsonDecode(content);
  if (decoded is! Map) {
    throw FormatException('Manifest root must be a JSON object.');
  }
  return decoded.cast<String, Object?>();
}

class _ManifestUpdateOptions {
  _ManifestUpdateOptions({
    required this.filePath,
    required this.platform,
    required this.version,
    required this.buildNumber,
    required this.publishedAt,
    required this.requiredUpdate,
    required this.notes,
    required this.mode,
    this.url,
    this.feedUrl,
    this.sha256,
    this.fallbackUrl,
    this.fallbackSha256,
    required this.variants,
  });

  final String filePath;
  final String platform;
  final String version;
  final int buildNumber;
  final String publishedAt;
  final bool requiredUpdate;
  final List<String> notes;
  final String mode;
  final String? url;
  final String? feedUrl;
  final String? sha256;
  final String? fallbackUrl;
  final String? fallbackSha256;
  final List<_AndroidVariant> variants;

  static _ManifestUpdateOptions parse(List<String> arguments) {
    String? filePath;
    String? platform;
    String? version;
    int? buildNumber;
    String? publishedAt;
    bool requiredUpdate = false;
    String? mode;
    String? url;
    String? feedUrl;
    String? sha256;
    String? fallbackUrl;
    String? fallbackSha256;
    final List<String> notes = <String>[];
    final List<_AndroidVariant> variants = <_AndroidVariant>[];

    for (int index = 0; index < arguments.length; index += 1) {
      final String argument = arguments[index];
      String nextValue() {
        if (index + 1 >= arguments.length) {
          throw ArgumentError('Missing value for $argument');
        }
        index += 1;
        return arguments[index];
      }

      switch (argument) {
        case '--file':
          filePath = nextValue();
        case '--platform':
          platform = nextValue();
        case '--version':
          version = nextValue();
        case '--build-number':
          buildNumber = int.tryParse(nextValue()) ?? 0;
        case '--published-at':
          publishedAt = nextValue();
        case '--required-update':
          requiredUpdate = true;
        case '--note':
          notes.add(nextValue());
        case '--mode':
          mode = nextValue();
        case '--url':
          url = nextValue();
        case '--feed-url':
          feedUrl = nextValue();
        case '--sha256':
          sha256 = nextValue();
        case '--fallback-url':
          fallbackUrl = nextValue();
        case '--fallback-sha256':
          fallbackSha256 = nextValue();
        case '--variant':
          variants.add(_AndroidVariant.parse(nextValue()));
        default:
          throw ArgumentError('Unknown argument: $argument');
      }
    }

    if (filePath == null ||
        platform == null ||
        version == null ||
        buildNumber == null ||
        publishedAt == null ||
        mode == null) {
      throw ArgumentError('Missing required arguments for manifest update');
    }

    return _ManifestUpdateOptions(
      filePath: filePath,
      platform: platform,
      version: version,
      buildNumber: buildNumber,
      publishedAt: publishedAt,
      requiredUpdate: requiredUpdate,
      notes: notes,
      mode: mode,
      url: url,
      feedUrl: feedUrl,
      sha256: sha256,
      fallbackUrl: fallbackUrl,
      fallbackSha256: fallbackSha256,
      variants: variants,
    );
  }

  Map<String, Object?> toPlatformEntry() {
    return <String, Object?>{
      'version': version,
      'buildNumber': buildNumber,
      'publishedAt': publishedAt,
      'required': requiredUpdate,
      'notes': notes,
      'download': <String, Object?>{
        'mode': mode,
        if (_hasText(url)) 'url': url,
        if (_hasText(feedUrl)) 'feedUrl': feedUrl,
        if (_hasText(sha256)) 'sha256': sha256,
        if (_hasText(fallbackUrl)) 'fallbackUrl': fallbackUrl,
        if (_hasText(fallbackSha256)) 'fallbackSha256': fallbackSha256,
        if (variants.isNotEmpty)
          'variants': variants.map((variant) => variant.toJson()).toList(),
      },
    };
  }

  bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;
}

class _AndroidVariant {
  const _AndroidVariant({required this.abi, required this.url, this.sha256});

  final String abi;
  final String url;
  final String? sha256;

  static _AndroidVariant parse(String rawValue) {
    final List<String> parts = rawValue.split('|');
    if (parts.length < 2) {
      throw ArgumentError(
        'Variant must use the format abi|url|sha256, got: $rawValue',
      );
    }
    return _AndroidVariant(
      abi: parts[0].trim(),
      url: parts[1].trim(),
      sha256: parts.length >= 3 && parts[2].trim().isNotEmpty
          ? parts[2].trim()
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'abi': abi,
      'url': url,
      if (sha256?.isNotEmpty ?? false) 'sha256': sha256,
    };
  }
}
