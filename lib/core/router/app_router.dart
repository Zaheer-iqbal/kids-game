import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/alphabet/presentation/pages/alphabet_world_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lesson/presentation/pages/lesson_page.dart';
import '../../features/numbers/presentation/pages/numbers_home_page.dart';
import '../../features/onboarding/presentation/pages/intro_page.dart';
import '../../features/quiz/domain/entities/quiz_type.dart';
import '../../features/quiz/presentation/pages/quiz_menu_page.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/quiz/presentation/pages/quiz_results_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../settings/presentation/pages/settings_page.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String intro = '/intro';
  static const String home = '/';
  static const String alphabet = '/alphabet';
  static const String numbers = '/numbers';
  static const String settings = '/settings';
  static const String quizMenu = '/quiz-menu';
  static const String quizLetters = '/quiz/letters';
  static const String quizNumbers = '/quiz/numbers';
  static const String quizFunFacts = '/quiz/fun-facts';
  static const String quizOddOneOut = '/quiz/odd-one-out';
  static const String quizResults = '/quiz-results';
  static const String lesson = '/lesson';

  /// `/lesson/<world>/<level>` - one playable level of the adventure map.
  static String lessonRoute(String worldId, int level) =>
      '$lesson/$worldId/$level';

  static String quizRouteFor(QuizType type) => switch (type) {
        QuizType.letterSounds => quizLetters,
        QuizType.numberMatch => quizNumbers,
        QuizType.funFacts => quizFunFacts,
        QuizType.oddOneOut => quizOddOneOut,
      };

  /// Map position (0-3) to its quiz route - used by Quiz Arena levels.
  static String quizRouteForIndex(int index) =>
      quizRouteFor(QuizType.values[index]);
}

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const SplashPage(), state: state),
      ),
      GoRoute(
        path: AppRoutes.intro,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const IntroPage(), state: state),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const HomePage(), state: state),
      ),
      GoRoute(
        path: AppRoutes.alphabet,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const AlphabetWorldPage(), state: state),
      ),
      GoRoute(
        path: AppRoutes.numbers,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const NumbersHomePage(), state: state),
      ),
      GoRoute(
        path: '${AppRoutes.lesson}/:world/:level',
        pageBuilder: (BuildContext context, GoRouterState state) => _softPage(
          child: LessonPage(
            worldId: state.pathParameters['world']!,
            level: int.tryParse(state.pathParameters['level'] ?? '') ?? 0,
          ),
          state: state,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const SettingsPage(), state: state),
      ),
      GoRoute(
        path: AppRoutes.quizMenu,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const QuizMenuPage(), state: state),
      ),
      GoRoute(
        path: AppRoutes.quizLetters,
        pageBuilder: (BuildContext context, GoRouterState state) => _softPage(
          child: const QuizPage(quizType: QuizType.letterSounds),
          state: state,
        ),
      ),
      GoRoute(
        path: AppRoutes.quizNumbers,
        pageBuilder: (BuildContext context, GoRouterState state) => _softPage(
          child: const QuizPage(quizType: QuizType.numberMatch),
          state: state,
        ),
      ),
      GoRoute(
        path: AppRoutes.quizFunFacts,
        pageBuilder: (BuildContext context, GoRouterState state) => _softPage(
          child: const QuizPage(quizType: QuizType.funFacts),
          state: state,
        ),
      ),
      GoRoute(
        path: AppRoutes.quizOddOneOut,
        pageBuilder: (BuildContext context, GoRouterState state) => _softPage(
          child: const QuizPage(quizType: QuizType.oddOneOut),
          state: state,
        ),
      ),
      GoRoute(
        path: AppRoutes.quizResults,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _softPage(child: const QuizResultsPage(), state: state),
      ),
    ],
  );
}

/// Soft fade + slide up for every screen.
///
/// The default go_router transition on this platform is an abrupt horizontal
/// jump, which feels harsh for small children; a gentle fade with a short
/// upward slide reads as one page settling into the next.
CustomTransitionPage<void> _softPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget? page,
    ) {
      final CurvedAnimation curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.07),
            end: Offset.zero,
          ).animate(curve),
          child: page,
        ),
      );
    },
  );
}
