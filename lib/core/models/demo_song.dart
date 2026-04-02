class DemoSong {
  const DemoSong({
    required this.title,
    required this.artist,
    required this.languages,
    this.tags = const <String>[],
    required this.searchIndex,
    required this.mediaPath,
  });

  final String title;
  final String artist;
  final List<String> languages;
  final List<String> tags;
  final String searchIndex;
  final String mediaPath;

  String get language => languages.join('/');

  String get tagsLabel => tags.join('/');

  @override
  bool operator ==(Object other) {
    return other is DemoSong && other.mediaPath == mediaPath;
  }

  @override
  int get hashCode => mediaPath.hashCode;
}
