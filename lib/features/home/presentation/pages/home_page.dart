import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/motion/app_motion.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/settings/presentation/pages/settings_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/mascot_view.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../../../../core/widgets/parental_gate.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../../quiz/presentation/pages/quiz_menu_page.dart';
import '../../../rewards/presentation/pages/rewards_page.dart';

/// The app shell. The Home tab is a friendly 4-card hub (letters, numbers,
/// animal puzzles and quiz); the other tabs hold Play, Rewards and the
/// grown-up settings, which sit behind a parental gate.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: IllustratedBackground()),
          SafeArea(
            child: Column(
              children: <Widget>[
                AppTopBar(
                  title: 'Owlie',
                  stars: progress.totalStars,
                  streak: progress.streakDays,
                  showSettings: _index != 3,
                ),
                Expanded(
                  child: switch (_index) {
                    0 => const _HomeHub(),
                    1 => const QuizMenuView(),
                    2 => const RewardsPage(),
                    _ => const SettingsView(),
                  },
                ),
              ],
            ),
          ),
          if (_index == 0) const Positioned(right: 6, bottom: 92, child: _MapMascot()),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        selected: _selectedDestination,
        onSelect: _onSelect,
        destinations: _destinations,
      ),
    );
  }

  String get _selectedDestination => _destinations[_index].value;

  void _onSelect(String value) {
    final int next =
        _destinations.indexWhere((NavBarDestination d) => d.value == value);
    if (next == _index) return;
    if (next == 3) {
      _openGrownUps();
      return;
    }
    setState(() => _index = next);
  }

  /// The grown-up tab is guarded so a wandering tap cannot change settings.
  Future<void> _openGrownUps() async {
    final bool allowed = await showParentalGate(context);
    if (!mounted || !allowed) return;
    setState(() => _index = 3);
  }

  static const List<NavBarDestination> _destinations = <NavBarDestination>[
    NavBarDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      value: 'home',
    ),
    NavBarDestination(
      label: 'Play',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz_rounded,
      value: 'play',
    ),
    NavBarDestination(
      label: 'Rewards',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events_rounded,
      value: 'rewards',
    ),
    NavBarDestination(
      label: 'Grown-ups',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      value: 'parents',
    ),
  ];
}

/// The four-card playground at the centre of the app.
class _HomeHub extends StatelessWidget {
  const _HomeHub();

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();
    // One controller drives the whole hub entrance: title, streak banner and
    // the four cards fan in one after another.
    return MotionStagger(
      itemCount: 6,
      child: ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        170,
      ),
      children: <Widget>[
        AppMotion(
          index: 0,
          child: Text(
            'What shall we play?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        const SizedBox(height: AppTokens.space3),
        AppMotion(index: 1, child: _StreakBanner(progress: progress)),
        const SizedBox(height: AppTokens.space4),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool twoUp = constraints.maxWidth >= 360;
            final double cardWidth = twoUp
                ? (constraints.maxWidth - AppTokens.space4) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: AppTokens.space4,
              runSpacing: AppTokens.space4,
              children: <Widget>[
                AppMotion(
                  index: 2,
                  child: SizedBox(
                  width: cardWidth,
                  child: HomeCard(
                    title: 'Alphabet Land',
                    subtitle: '${progress.exploredCount} of 26 letters explored',
                    emoji: '🅰️',
                    glyph: 'Aa',
                    color: AppColors.accentCoral,
                    onTap: () => context.push(AppRoutes.alphabet),
                  ),
                ),
                ),
                AppMotion(
                  index: 3,
                  child: SizedBox(
                  width: cardWidth,
                  child: HomeCard(
                    title: 'Number World',
                    subtitle:
                        '${progress.exploredNumberCount} of 100 numbers explored',
                    emoji: '🔢',
                    glyph: '123',
                    color: AppColors.accentSky,
                    onTap: () => context.push(AppRoutes.numbers),
                  ),
                ),
                ),
                AppMotion(
                  index: 4,
                  child: SizedBox(
                  width: cardWidth,
                  child: HomeCard(
                    title: 'Animal Puzzles',
                    subtitle: '${progress.solvedPuzzleCount} of 100 animals solved',
                    emoji: '🧩',
                    glyph: '🦁',
                    color: AppColors.accentPurple,
                    onTap: () => context.push(AppRoutes.puzzles),
                  ),
                ),
                ),
                AppMotion(
                  index: 5,
                  child: SizedBox(
                  width: cardWidth,
                  child: HomeCard(
                    title: 'Play Quiz',
                    subtitle: 'Best score ${progress.quizHighScore}',
                    emoji: '🏆',
                    glyph: '★',
                    color: AppColors.quiz,
                    onTap: () => context.push(AppRoutes.quizMenu),
                  ),
                ),
                ),
              ],
            );
          },
        ),
      ],
      ),
    );
  }
}

/// The daily streak, with a claimable milestone chest when one is ready.
class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.progress});

  final ProgressService progress;

  @override
  Widget build(BuildContext context) {
    final int days = progress.streakDays;
    final int? milestone = progress.pendingStreakMilestone;

    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: AppColors.cardBorder, width: 2),
        boxShadow: AppTokens.softShadow(),
      ),
      child: Row(
        children: <Widget>[
          Text(
            days > 0 ? '🔥' : '🌱',
            style: const TextStyle(fontSize: 34),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  days > 0 ? '$days day streak!' : 'Start your streak!',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontVariations: <FontVariation>[FontVariation('wght', 700)],
                    color: AppColors.ink,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Play a lesson, quiz or puzzle every day.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (milestone != null)
            _MilestoneChest(days: milestone, progress: progress),
        ],
      ),
    );
  }
}

class _MilestoneChest extends StatelessWidget {
  const _MilestoneChest({required this.days, required this.progress});

  final int days;
  final ProgressService progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Claim $days day streak reward',
      child: GestureDetector(
        onTap: () async {
          await progress.claimStreakMilestone(days);
          if (!context.mounted) return;
          showCelebrationOverlay(
            context,
            message: '$days day streak! You earned a sticker and a new outfit!',
          );
        },
        child: Column(
          children: <Widget>[
            const Text('🎁', style: TextStyle(fontSize: 32)),
            Text(
              '$days days',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A big, friendly, tappable game card with a hand-drawn feel: a coloured
/// stamp, a title, a progress line and a playful glyph.
class HomeCard extends StatefulWidget {
  const HomeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.glyph,
    required this.onTap,
    this.emoji,
  });

  final String title;
  final String subtitle;
  final Color color;
  final String glyph;
  final String? emoji;
  final VoidCallback onTap;

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: AppTokens.pressDuration,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.space4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusXL),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.35),
                width: 2.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  ),
                  child: Text(
                    widget.glyph,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      fontVariations: const <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: widget.color,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 700),
                          ],
                          color: AppColors.ink,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (widget.emoji != null)
                      Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating, always-tappable friend in the bottom-right corner of the map.
class _MapMascot extends StatelessWidget {
  const _MapMascot();

  @override
  Widget build(BuildContext context) {
    final double maxWidth =
        (MediaQuery.sizeOf(context).width - 12).clamp(0, 260).toDouble();
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const MascotView(
            key: ValueKey<String>('home-mascot'),
            size: 84,
            bubbleLayout: MascotBubbleLayout.leading,
            bubbleMaxWidth: 170,
          ),
        ),
      ),
    );
  }
}