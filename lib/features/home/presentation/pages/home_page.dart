import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/mascot/mascot_cubit.dart';
import '../../../../core/mascot/mascot_mood.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/settings/presentation/pages/settings_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/mascot_view.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../../quiz/presentation/pages/quiz_menu_page.dart';
import '../../../rewards/presentation/pages/rewards_page.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'adventure_map_page.dart';

/// The app shell: adventure map by default, plus Play, Rewards and Grown-ups
/// behind a floating pill navigation. Pip the owl greets the child on arrival
/// and hangs out over the map.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaitedStreak();
      context.read<MascotCubit>().setMood(MascotMood.idle, speak: true);
    });
  }

  Future<void> unawaitedStreak() =>
      di.sl<ProgressService>().touchStreak();

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();

    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: IllustratedBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                AppTopBar(
                  title: 'ABC Kids',
                  stars: progress.totalStars,
                  streak: progress.streakDays,
                  showSettings: _index != 3,
                ),
                Expanded(
                  child: switch (_index) {
                    0 => const AdventureMapPage(),
                    1 => const QuizMenuView(),
                    2 => const RewardsPage(),
                    _ => const SettingsView(),
                  },
                ),
              ],
            ),
          ),
          if (_index == 0)
            const Positioned(
              right: 6,
              bottom: 92,
              child: _MapMascot(),
            ),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        selected: _selectedDestination,
        onSelect: (String value) {
          final int next = _destinations
              .indexWhere((NavBarDestination d) => d.value == value);
          if (next == _index) return;
          setState(() => _index = next);
        },
        destinations: _destinations,
      ),
    );
  }

  String get _selectedDestination => _destinations[_index].value;

  static const List<NavBarDestination> _destinations =
      <NavBarDestination>[
    NavBarDestination(
      label: 'Map',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      value: 'map',
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

/// Floating, always-tappable friend in the bottom-right corner of the map.
class _MapMascot extends StatelessWidget {
  const _MapMascot();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
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
    );
  }
}
