import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_mood.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/mascot_widget.dart';
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

            // Right Column: Speech bubble + Owlie mascot
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SpeechBubbleWidget(text: "Let's play!"),
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
                      GestureDetector(
                        onTap: () {
                          showCelebrationOverlay(
                            context,
                            message: "Owlie says: Twit-twoo! Let's learn together! 🦉✨",
                          );
                        },
                        child: const MascotWidget(
                          mood: MascotMood.idle,
                          size: 96,
                          talking: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.puzzles}/0'),
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
            // Golden circular lion face
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFBB624),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x20FBB624),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Text('🦁', style: TextStyle(fontSize: 21)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Animal of the day',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF23314E),
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Lion puzzle',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF718096),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Coral "Go" pill button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6E5B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x30FF6E5B),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Go',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}