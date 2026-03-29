part of 'ktv_demo_shell.dart';

class _GradientShell extends StatelessWidget {
  const _GradientShell({
    required this.child,
    required this.padding,
    required this.compact,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF23004F),
            Color(0xFF4A0A99),
            Color(0xFF2B005A),
            Color(0xFF30006B),
            Color(0xFF6820D9),
            Color(0xFF461094),
            Color(0xFF16012D),
            Color(0xFF3B1177),
            Color(0xFF25024A),
          ],
          stops: <double>[0.0, 0.12, 0.24, 0.36, 0.48, 0.6, 0.74, 0.86, 1.0],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(
              0xFF090012,
            ).withValues(alpha: compact ? 0.25 : 0.28),
            blurRadius: compact ? 28 : 32,
            offset: Offset(0, compact ? 18 : 20),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PlayerProgressTrack extends StatelessWidget {
  const _PlayerProgressTrack({
    required this.controller,
    required this.thickness,
    required this.barHeight,
  });

  final PlayerController controller;
  final double thickness;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final bool hasMedia =
        controller.hasMedia && controller.playbackDuration > Duration.zero;
    return SizedBox(
      height: barHeight,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: thickness,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: const Color(0xFFFF4D8D),
          inactiveTrackColor: const Color(0x33FFFFFF),
          overlayColor: const Color(0x29FF4D8D),
        ),
        child: Slider(
          padding: EdgeInsets.zero,
          value: hasMedia ? controller.playbackProgress : 0,
          onChanged: hasMedia ? controller.seekToProgress : null,
        ),
      ),
    );
  }
}

class _KtvAtmosphereBackground extends StatelessWidget {
  const _KtvAtmosphereBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: const <Widget>[
          Positioned(
            left: -80,
            top: -120,
            child: _GlowOrb(size: 260, color: Color(0xFFAA4DFF)),
          ),
          Positioned(
            right: -60,
            top: 80,
            child: _GlowOrb(size: 220, color: Color(0xFFFF5A7A)),
          ),
          Positioned(
            left: 120,
            bottom: -100,
            child: _GlowOrb(size: 240, color: Color(0xFF3E7BFF)),
          ),
          Positioned(
            right: 80,
            bottom: 120,
            child: _GlowOrb(size: 180, color: Color(0xFFFFB245)),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
