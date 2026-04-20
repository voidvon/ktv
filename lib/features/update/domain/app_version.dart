class AppVersion implements Comparable<AppVersion> {
  AppVersion({required this.displayVersion, required this.buildNumber})
    : _coreNumbers = _parseCoreNumbers(displayVersion),
      _preReleaseIdentifiers = _parsePreReleaseIdentifiers(displayVersion);

  final String displayVersion;
  final int buildNumber;
  final List<int> _coreNumbers;
  final List<_PreReleaseIdentifier> _preReleaseIdentifiers;

  String get fullValue => '$displayVersion+$buildNumber';
  bool get isPreRelease => _preReleaseIdentifiers.isNotEmpty;

  static AppVersion parse({
    required String version,
    required String buildNumber,
  }) {
    return AppVersion(
      displayVersion: version.trim(),
      buildNumber: int.tryParse(buildNumber.trim()) ?? 0,
    );
  }

  @override
  int compareTo(AppVersion other) {
    final int coreComparison = _compareCoreNumbers(other);
    if (coreComparison != 0) {
      return coreComparison;
    }

    final bool hasPreRelease = _preReleaseIdentifiers.isNotEmpty;
    final bool otherHasPreRelease = other._preReleaseIdentifiers.isNotEmpty;
    if (!hasPreRelease && otherHasPreRelease) {
      return 1;
    }
    if (hasPreRelease && !otherHasPreRelease) {
      return -1;
    }

    final int preReleaseComparison = _comparePreRelease(other);
    if (preReleaseComparison != 0) {
      return preReleaseComparison;
    }
    return buildNumber.compareTo(other.buildNumber);
  }

  int _compareCoreNumbers(AppVersion other) {
    final int maxLength = _coreNumbers.length > other._coreNumbers.length
        ? _coreNumbers.length
        : other._coreNumbers.length;
    for (int index = 0; index < maxLength; index += 1) {
      final int current = index < _coreNumbers.length ? _coreNumbers[index] : 0;
      final int next = index < other._coreNumbers.length
          ? other._coreNumbers[index]
          : 0;
      final int comparison = current.compareTo(next);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  int _comparePreRelease(AppVersion other) {
    final int maxLength =
        _preReleaseIdentifiers.length > other._preReleaseIdentifiers.length
        ? _preReleaseIdentifiers.length
        : other._preReleaseIdentifiers.length;
    for (int index = 0; index < maxLength; index += 1) {
      if (index >= _preReleaseIdentifiers.length) {
        return -1;
      }
      if (index >= other._preReleaseIdentifiers.length) {
        return 1;
      }
      final int comparison = _preReleaseIdentifiers[index].compareTo(
        other._preReleaseIdentifiers[index],
      );
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  static List<int> _parseCoreNumbers(String displayVersion) {
    final String corePart = displayVersion.split('-').first.trim();
    return corePart
        .split('.')
        .map((String value) => int.tryParse(value) ?? 0)
        .toList(growable: false);
  }

  static List<_PreReleaseIdentifier> _parsePreReleaseIdentifiers(
    String displayVersion,
  ) {
    final int separatorIndex = displayVersion.indexOf('-');
    if (separatorIndex < 0 || separatorIndex == displayVersion.length - 1) {
      return const <_PreReleaseIdentifier>[];
    }
    final String preReleasePart = displayVersion
        .substring(separatorIndex + 1)
        .trim();
    return preReleasePart
        .split('.')
        .where((String value) => value.trim().isNotEmpty)
        .map(_PreReleaseIdentifier.parse)
        .toList(growable: false);
  }
}

class _PreReleaseIdentifier implements Comparable<_PreReleaseIdentifier> {
  const _PreReleaseIdentifier._({required this.value, required this.numeric});

  final String value;
  final bool numeric;

  static _PreReleaseIdentifier parse(String rawValue) {
    final String trimmedValue = rawValue.trim();
    final int? numericValue = int.tryParse(trimmedValue);
    if (numericValue != null) {
      return _PreReleaseIdentifier._(
        value: numericValue.toString(),
        numeric: true,
      );
    }
    return _PreReleaseIdentifier._(value: trimmedValue, numeric: false);
  }

  @override
  int compareTo(_PreReleaseIdentifier other) {
    if (numeric && other.numeric) {
      return int.parse(value).compareTo(int.parse(other.value));
    }
    if (numeric && !other.numeric) {
      return -1;
    }
    if (!numeric && other.numeric) {
      return 1;
    }
    return value.compareTo(other.value);
  }
}
