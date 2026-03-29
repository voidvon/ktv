part of 'ktv_demo_shell.dart';

class _GradientShell extends StatelessWidget {
  const _GradientShell({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
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

class _PersistentPreviewSurface extends StatelessWidget {
  const _PersistentPreviewSurface({
    super.key,
    required this.controller,
    required this.route,
  });

  final PlayerController controller;
  final DemoRoute route;

  @override
  Widget build(BuildContext context) {
    final bool isHome = route == DemoRoute.home;
    return KtvPlayerView(
      controller: controller,
      backgroundColor: isHome
          ? const Color(0xFF0A0018)
          : const Color(0xFF090013),
      placeholder: isHome
          ? const _HomePreviewPlaceholder()
          : const _SongPreviewPlaceholder(),
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
