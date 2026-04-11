import '../../../core/models/song.dart';

class QueuedSongEntry {
  const QueuedSongEntry({
    required this.song,
    required this.queueIndex,
    required this.isCurrent,
    required this.canPinToTop,
    required this.subtitle,
  });

  final Song song;
  final int queueIndex;
  final bool isCurrent;
  final bool canPinToTop;
  final String subtitle;
}
