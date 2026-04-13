import '../../../core/models/song.dart';

class QueuedSongEntry {
  const QueuedSongEntry({
    required this.song,
    required this.queueIndex,
    required this.isCurrent,
    required this.isPendingDownload,
    required this.canPinToTop,
    required this.showPinAction,
    required this.subtitle,
  });

  final Song song;
  final int queueIndex;
  final bool isCurrent;
  final bool isPendingDownload;
  final bool canPinToTop;
  final bool showPinAction;
  final String subtitle;
}
