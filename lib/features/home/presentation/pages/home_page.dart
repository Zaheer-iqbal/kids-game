import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_mood.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../../../puzzles/domain/entities/animal.dart';
import '../../../puzzles/domain/repositories/puzzle_repository.dart';
import '../../../puzzles/presentation/pages/puzzle_map_page.dart';
import '../../../rewards/presentation/pages/rewards_page.dart';
import '../widgets/owlie_home_widgets.dart';
import 'owlie_room_page.dart';

/// The primary application shell matching the exact modern Owlie Home UI.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const List<NavBarDestination> _destinations = <NavBarDestination>[
    NavBarDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      value: 'home',
    ),
    NavBarDestination(
      label: 'Puzzles',
      icon: Icons.crop_square_rounded,
      selectedIcon: Icons.crop_square_rounded,
      value: 'puzzles',
    ),
    NavBarDestination(
      label: 'Rewards',
      icon: Icons.star_outline_rounded,
      selectedIcon: Icons.star_rounded,
      value: 'rewards',
    ),
    NavBarDestination(
      label: 'Owl',
      icon: Icons.sentiment_satisfied_rounded,
      selectedIcon: Icons.sentiment_satisfied_alt_rounded,
      value: 'owl',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();

    return Scaffold(
      body: GreenHillBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              // Top Bar with Owlie avatar, title, and star & flame pills
              _OwlieTopBar(
                stars: progress.totalStars > 0 ? progress.totalStars : 24,
                streak: progress.streakDays > 0 ? progress.streakDays : 5,
              ),
              // Tab Body
              Expanded(
                child: switch (_index) {
                  0 => _HomeHub(progress: progress),
                  1 => const PuzzleMapPage(),
                  2 => const RewardsPage(),
                  _ => const OwlieRoomPage(),
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        destinations: _destinations,
        selected: _destinations[_index].value,
        onSelect: (String val) {
          final int next =
              _destinations.indexWhere((NavBarDestination d) => d.value == val);
          if (next != -1 && next != _index) {
            setState(() => _index = next);
          }
        },
      ),
    );
  }
}

/// The top bar with Owlie icon, "Owlie" title, and star / flame badge pills.
class _OwlieTopBar extends StatelessWidget {
  const _OwlieTopBar({
    required this.stars,
    required this.streak,
  });

  final int stars;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: <Widget>[
            const OwlieAvatar(size: 40),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Owlie',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF455582),
                  height: 1,
                ),
              ),
            ),
            const Spacer(),
            // Star Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('⭐', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    '$stars',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Streak / Flame Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('🔥', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The exact Home Hub matching the screenshot.
class _HomeHub extends StatelessWidget {
  const _HomeHub({required this.progress});

  final ProgressService progress;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: <Widget>[
        // 2x2 Grid: ABC, 123, Quiz, Puzzles
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            // 1. ABC Card (Top Left - Royal Blue)
            BigGameCard(
              backgroundColor: const Color(0xFF4A8BFE),
              title: 'ABC',
              semanticTitle: 'Alphabet Land',
              semanticSubtitle: '${progress.exploredCount} of 26 letters explored',
              graphic: const AbcCardGraphic(),
              onTap: () => context.push(AppRoutes.alphabet),
            ),
            // 2. 123 Card (Top Right - Fresh Green)
            BigGameCard(
              backgroundColor: const Color(0xFF35C774),
              title: '123',
              semanticTitle: 'Number World',
              semanticSubtitle: '${progress.exploredNumberCount} of 100 numbers explored',
              graphic: const BalloonsCardGraphic(),
              onTap: () => context.push(AppRoutes.numbers),
            ),
            // 3. Quiz Card (Bottom Left - Warm Amber Yellow)
            BigGameCard(
              backgroundColor: const Color(0xFFFDB827),
              title: 'Quiz',
              semanticTitle: 'Play Quiz',
              semanticSubtitle: 'Best score ${progress.quizHighScore}',
              graphic: const TrophyCardGraphic(),
              onTap: () => context.push(AppRoutes.quizMenu),
            ),
            // 4. Puzzles Card (Bottom Right - Coral Red)
            BigGameCard(
              backgroundColor: const Color(0xFFFF6E5B),
              title: 'Puzzles',
              semanticTitle: 'Animal Puzzles',
              semanticSubtitle: '${progress.solvedPuzzleCount} of 100 animals solved',
              graphic: const PuzzlesCardGraphic(),
              onTap: () => context.push(AppRoutes.puzzles),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Lower Section: Left stacked cards + Right Owlie mascot with speech bubble
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
            // Left Column: Daily surprise + Animal of the day
            Expanded(
              flex: 7,
              child: Column(
                children: <Widget>[
                  // Card 1: Daily surprise
                  _buildDailySurpriseCard(context),
                  const SizedBox(height: 10),
                  // Card 2: Animal of the day
                  _buildAnimalOfDayCard(context),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Column: Interactive Speech bubble + Bouncing Owlie mascot
            const Expanded(
              flex: 5,
              child: _InteractiveHomeOwlie(),
            ),
          ],
        ),
      ),
      ],
    );
  }

  Widget _buildDailySurpriseCard(BuildContext context) {
    final int starsProgress = (progress.totalStars % 5 == 0 && progress.totalStars > 0)
        ? 5
        : (progress.totalStars % 5);
    final double factor = (starsProgress / 5.0).clamp(0.2, 1.0);

    return GestureDetector(
      onTap: () {
        showCelebrationOverlay(
          context,
          message: 'Daily Surprise Unlocked! You earned 2 bonus stars! 🎁⭐',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // Orange bag/gift pouch
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE78225),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x20E78225),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Daily surprise',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF23314E),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$starsProgress of 5 stars',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF718096),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Rounded green progress bar
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: factor,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF36C774),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalOfDayCard(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();
    final PuzzleRepository puzzleRepo = di.sl<PuzzleRepository>();
    final int puzzleIndex = progress.lastPlayedPuzzleIndex;
    final Animal animal = puzzleRepo.animalAt(puzzleIndex);
    final int stars = progress.puzzleStars(puzzleIndex);
    final bool isSolved = stars > 0;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.puzzles}/$puzzleIndex'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFFECE5),
            width: 1.5,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFFF6E5B).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // Animal Avatar circle with gentle gradient
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFFFD166), Color(0xFFFBB624)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x30FBB624),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(animal.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text(
                        'Animal of the day',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF23314E),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${puzzleIndex + 1}',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${animal.name} puzzle • ${isSolved ? "$stars ⭐ Solved" : "Tap to solve"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSolved
                          ? const Color(0xFF10B981)
                          : const Color(0xFF718096),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            // Coral / Emerald "Go" or "Play" / "Resume" pill button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSolved
                      ? const <Color>[Color(0xFF34D399), Color(0xFF10B981)]
                      : const <Color>[Color(0xFFFF7E6B), Color(0xFFFF5238)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (isSolved
                            ? const Color(0xFF10B981)
                            : const Color(0xFFFF5238))
                        .withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isSolved ? Icons.replay_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isSolved ? 'Replay' : 'Play',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A delightful, interactive, lively Owlie mascot on the Home screen.
/// Tapping Owlie makes him bounce, chirp sound, show floating sparkles/hearts,
/// and speak inspiring & funny quotes dynamically without annoying modal popups!
class _InteractiveHomeOwlie extends StatefulWidget {
  const _InteractiveHomeOwlie();

  @override
  State<_InteractiveHomeOwlie> createState() => _InteractiveHomeOwlieState();
}

class _InteractiveHomeOwlieState extends State<_InteractiveHomeOwlie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _jumpAnimation;

  MascotMood _mood = MascotMood.idle;
  String _speechText = "Let's play!";
  int _reactionToken = 0;
  int _giggleToken = 0;
  int _clickCount = 0;
  final List<_FloatingParticle> _particles = <_FloatingParticle>[];

  static const List<Map<String, dynamic>> _reactions =
      <Map<String, dynamic>>[
    {
      'text': "Twit-twoo! You're awesome! 🦉⭐",
      'mood': MascotMood.excited,
    },
    {
      'text': "Ready for an adventure? Let's go! 🚀",
      'mood': MascotMood.happy,
    },
    {
      'text': "Hehe, that tickles! 😆",
      'mood': MascotMood.encouraging,
    },
    {
      'text': "You're a super star learner! 🌟",
      'mood': MascotMood.excited,
    },
    {
      'text': "High five, buddy! 🖐️",
      'mood': MascotMood.happy,
    },
    {
      'text': "Look at your stars! Keep shining! ✨",
      'mood': MascotMood.excited,
    },
    {
      'text': "I love learning with you! 💖",
      'mood': MascotMood.happy,
    },
    {
      'text': "Twit-twoo! Give me a tickle! 🦉",
      'mood': MascotMood.encouraging,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);

    _jumpAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: -14.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -14.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onTapOwlie() {
    HapticFeedback.lightImpact();
    final AudioService audio = di.sl<AudioService>();
    audio.playSuccessChime();

    final Map<String, dynamic> reaction =
        _reactions[_clickCount % _reactions.length];
    _clickCount++;

    final String text = reaction['text'] as String;
    final MascotMood newMood = reaction['mood'] as MascotMood;

    // Trigger audio speech
    audio.speakText(text);

    setState(() {
      _mood = newMood;
      _speechText = text;
      _reactionToken++;
      _giggleToken++;

      final String emoji =
          <String>['💖', '⭐', '✨', '🎉', '🌟'][_clickCount % 5];
      _particles.add(_FloatingParticle(
        id: DateTime.now().microsecondsSinceEpoch,
        emoji: emoji,
      ));
    });

    _bounceController.forward(from: 0.0);

    // After 2.6s, smoothly revert to idle
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _mood = MascotMood.idle;
          _speechText = "Let's play!";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Animated Speech Bubble above Owlie
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: SpeechBubbleWidget(
            key: ValueKey<String>(_speechText),
            text: _speechText,
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: <Widget>[
            // Soft shadow on the ground
            Container(
              width: 76,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withValues(alpha: 0.12),
                borderRadius: const BorderRadius.all(
                  Radius.elliptical(76, 14),
                ),
              ),
            ),
            // Floating emoji particles
            ..._particles.map((_FloatingParticle p) {
              return _ParticleWidget(
                key: ValueKey<int>(p.id),
                emoji: p.emoji,
                onComplete: () {
                  if (mounted) {
                    setState(() {
                      _particles
                          .removeWhere((_FloatingParticle x) => x.id == p.id);
                    });
                  }
                },
              );
            }),
            // Bouncing Owlie Mascot
            GestureDetector(
              onTap: _onTapOwlie,
              child: AnimatedBuilder(
                animation: _bounceController,
                builder: (BuildContext context, Widget? child) {
                  return Transform.translate(
                    offset: Offset(0, _jumpAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: MascotWidget(
                  mood: _mood,
                  size: 96,
                  reactionToken: _reactionToken,
                  giggleToken: _giggleToken,
                  talking: false,
                  onTap: _onTapOwlie,
                  onSettle: () {
                    if (mounted) {
                      setState(() => _mood = MascotMood.idle);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FloatingParticle {
  const _FloatingParticle({required this.id, required this.emoji});
  final int id;
  final String emoji;
}

class _ParticleWidget extends StatefulWidget {
  const _ParticleWidget({
    super.key,
    required this.emoji,
    required this.onComplete,
  });

  final String emoji;
  final VoidCallback onComplete;

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward().then((_) {
      if (mounted) widget.onComplete();
    });

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, Widget? child) {
        final double t = _ctrl.value;
        final double dy = -20 - (t * 45);
        final double opacity = (1.0 - t).clamp(0.0, 1.0);
        return Positioned(
          top: dy,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: 0.8 + (t * 0.4),
              child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
        );
      },
    );
  }
}