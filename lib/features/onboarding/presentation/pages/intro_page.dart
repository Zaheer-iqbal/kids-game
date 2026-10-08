import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/onboarding/onboarding_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/mascot_view.dart';

/// Three-screen first-launch intro: who the mascot is, what the child can do,
/// and what they collect. Skippable, stored locally, never shown again.
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<_IntroSlide> _slides = <_IntroSlide>[
    _IntroSlide(
      emoji: '🦉',
      title: 'Meet Pip!',
      body:
          'Pip is your adventure buddy. Play little games, hear every sound '
          'and laugh all the way through Alphabet Land.',
      color: AppColors.primary,
    ),
    _IntroSlide(
      emoji: '✍️',
      title: 'Trace & Count',
      body:
          'Draw letters with your finger and count friendly pictures up to '
          '100 — one small step at a time.',
      color: AppColors.accentMint,
    ),
    _IntroSlide(
      emoji: '🏆',
      title: 'Collect Stars',
      body:
          'Finish each lesson to earn shiny stars and badges. Play at your '
          'own speed, there are no timers here.',
      color: AppColors.accentCoral,
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      di.sl<AudioService>().playPop();
      _pageController.nextPage(
        duration: AppTokens.screenFade,
        curve: AppTokens.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await di.sl<OnboardingService>().markIntroSeen();
    if (!mounted) return;
    di.sl<AudioService>()
      ..playDing()
      ..playFanfare();
    context.go(AppRoutes.home);
  }

  Future<void> _skip() async {
    await di.sl<OnboardingService>().markIntroSeen();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool last = _page == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: IllustratedBackground()),
          SafeArea(
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AppTokens.space3,
                      top: AppTokens.space2,
                    ),
                    child: TextButton(
                      onPressed: _skip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (int index) =>
                        setState(() => _page = index),
                    itemBuilder: (BuildContext context, int index) =>
                        _IntroSlideView(slide: _slides[index]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(_slides.length, (int i) {
                    return AnimatedContainer(
                      duration: AppTokens.pressDuration,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space6,
                    AppTokens.space5,
                    AppTokens.space6,
                    AppTokens.space6,
                  ),
                  child: GameButton.large(
                    label: last ? "Let's go!" : 'Next',
                    icon: last ? Icons.celebration_rounded : null,
                    color: _slides[_page].color,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });

  final String emoji;
  final String title;
  final String body;
  final Color color;
}

class _IntroSlideView extends StatelessWidget {
  const _IntroSlideView({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (slide.emoji == '🦉')
            const MascotView(
              key: ValueKey<String>('intro-mascot'),
              size: 168,
              showBubble: false,
            )
          else
            Container(
              width: 150,
              height: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 3),
              ),
              child: Text(slide.emoji, style: const TextStyle(fontSize: 76)),
            ),
          const SizedBox(height: AppTokens.space6),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
