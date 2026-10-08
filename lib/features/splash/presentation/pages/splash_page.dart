import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/onboarding/onboarding_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/delight_settings.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/mascot_view.dart';

/// App launch: a short, code-drawn brand moment on the adventure backdrop,
/// then it hands off to the first-launch intro or straight to the map.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const Duration duration = Duration(milliseconds: 1500);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashPage.duration,
  );
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleHandoff());
  }

  void _scheduleHandoff() {
    Future<void>.delayed(SplashPage.duration, () {
      if (!mounted || _navigated) return;
      _navigated = true;
      final OnboardingService onboarding = di.sl<OnboardingService>();
      final bool seen = onboarding.hasSeenIntro;
      di.sl<AudioService>().playWhoosh();
      context.go(seen ? AppRoutes.home : AppRoutes.intro);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const IllustratedBackground(),
          Center(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0, 0.5),
              ),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
                ),
                child: const _BrandLogo(),
              ),
            ),
          ),
          // Pip waves at the child while the brand moment plays.
          Positioned(
            right: 24,
            bottom: 40,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.3, 1),
              ),
              child: const MascotView(
                key: ValueKey<String>('splash-mascot'),
                size: 120,
                showBubble: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three bouncing rounded tiles spelling A B C plus a 1 2 3 tile.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    final List<_Tile> tiles = <_Tile>[
      _Tile(char: 'A', color: AppColors.accentCoral, delay: 0),
      _Tile(char: 'B', color: AppColors.primary, delay: 80),
      _Tile(char: 'C', color: AppColors.accentMint, delay: 160),
      _Tile(char: '⭐', color: AppColors.secondary, delay: 240),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: tiles
              .map((Widget tile) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: tile,
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'ABC Kids',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                shadows: const <Shadow>[
                  Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Learn • Play • Shine',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.char,
    required this.color,
    required this.delay,
  });

  final String char;
  final Color color;
  final int delay;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 180 + widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool animate = DelightSettings.of(context).animationsEnabled;
    if (!animate) {
      return _tile();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutBack.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(opacity: _controller.value.clamp(0.0, 1.0), child: child),
        );
      },
      child: _tile(),
    );
  }

  Widget _tile() {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.color.withValues(alpha: 1),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        widget.char,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
