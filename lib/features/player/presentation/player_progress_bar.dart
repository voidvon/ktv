import 'package:flutter/material.dart';
import 'package:ktv2/ktv2.dart';

class PlayerProgressBar extends StatelessWidget {
  const PlayerProgressBar({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bool hasMedia =
            controller.hasMedia && controller.playbackDuration > Duration.zero;
        final ThemeData theme = Theme.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _formatDuration(controller.playbackPosition),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  _formatDuration(controller.playbackDuration),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Slider(
              value: hasMedia ? controller.playbackProgress : 0,
              onChanged: hasMedia ? controller.seekToProgress : null,
            ),
          ],
        );
      },
    );
  }
}

String _formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
