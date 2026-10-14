import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/onboarding/onboarding_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_logo.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/mascot_view.dart';

/// App launch: the animated ABC Zoo logo assembles itself on the adventure
/// backdrop, then the app hands off to the first-launch intro or the map.
///
/// The whole brand moment is under 2.5 seconds and any outside tap skips it.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Keep the brand moment short; the animated logo lands just before this.
  static const Duration duration = Duration(milliseconds: 2300);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(SplashPage.duration, _handoff);
    });
  }

  void _handoff() {
    if (!mounted || _navigated) return;
    _navigated = true;
    final OnboardingService onboarding = di.sl<OnboardingService>();
    final bool seen = onboarding.hasSeenIntro;
    di.sl<AudioService>().playWhoosh();
    context.go(seen ? AppRoutes.home : AppRoutes.intro);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double logoWidth =
        (MediaQuery.sizeOf(context).shortestSide * 0.72).clamp(200, 340);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const IllustratedBackground(),
          // Tap anywhere outside the logo to skip the brand moment.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handoff,
              child: SafeArea(
                // Scrollable so the brand moment never clips on a short
                // landscape window or at a large text scale.
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AnimatedLogo(size: logoWidth),
                        const SizedBox(height: 4),
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.35, 1),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ABC Zoo',
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(color: AppColors.ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.45, 1),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Learn • Play • Shine',
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.inkMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Pip waves at the child while the brand moment plays.
          Positioned(
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.3, 1),
                  ),
                  child: MascotView(
                    key: const ValueKey<String>('splash-mascot'),
                    size: (MediaQuery.sizeOf(context).shortestSide * 0.28)
                        .clamp(72, 120)
                        .toDouble(),
                    showBubble: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
