import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/alphabet/data/repositories/alphabet_repository_impl.dart';
import '../../features/alphabet/domain/repositories/alphabet_repository.dart';
import '../../features/alphabet/presentation/bloc/alphabet_bloc.dart';
import '../../features/lesson/data/lesson_repository_impl.dart';
import '../../features/lesson/domain/lesson_repository.dart';
import '../../features/numbers/data/repositories/number_repository_impl.dart';
import '../../features/numbers/domain/repositories/number_repository.dart';
import '../../features/numbers/presentation/bloc/number_bloc.dart';
import '../../features/puzzles/data/repositories/puzzle_repository_impl.dart';
import '../../features/puzzles/domain/repositories/puzzle_repository.dart';
import '../../features/puzzles/presentation/bloc/puzzle_catalog_cubit.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../../features/quiz/domain/repositories/quiz_repository.dart';
import '../../features/quiz/presentation/bloc/quiz_bloc.dart';
import '../mascot/mascot_cubit.dart';
import '../onboarding/onboarding_service.dart';
import '../router/app_router.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../settings/data/settings_repository_impl.dart';
import '../settings/domain/settings_repository.dart';
import '../settings/presentation/settings_cubit.dart';
import '../settings/presentation/settings_state.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  sl
    ..registerLazySingleton<ProgressService>(() => ProgressService(prefs))
    ..registerLazySingleton<AudioService>(AudioService.new)
    ..registerLazySingleton<AppRouter>(AppRouter.new)
    ..registerLazySingleton<OnboardingService>(() => OnboardingService(prefs))
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(prefs),
    )
    // Loaded eagerly so the very first frame already honours the saved
    // parent settings (no "everything on, then flick off" flash).
    ..registerLazySingleton<SettingsCubit>(
      () => SettingsCubit(repository: sl<SettingsRepository>())..load(),
    )
    ..registerLazySingleton<MascotCubit>(
      () => MascotCubit(
        audioService: sl<AudioService>(),
        settingsCubit: sl<SettingsCubit>(),
      ),
    )
    ..registerLazySingleton<AlphabetRepository>(AlphabetRepositoryImpl.new)
    ..registerLazySingleton<NumberRepository>(NumberRepositoryImpl.new)
    ..registerLazySingleton<QuizRepository>(QuizRepositoryImpl.new)
    ..registerLazySingleton<PuzzleRepository>(PuzzleRepositoryImpl.new)
    ..registerLazySingleton<LessonRepository>(
      () => LessonRepositoryImpl(
        alphabetRepository: sl<AlphabetRepository>(),
        numberRepository: sl<NumberRepository>(),
      ),
    )
    ..registerFactory<AlphabetBloc>(
      () => AlphabetBloc(
        repository: sl<AlphabetRepository>(),
        audioService: sl<AudioService>(),
        progressService: sl<ProgressService>(),
      ),
    )
    ..registerFactory<NumberBloc>(
      () => NumberBloc(
        repository: sl<NumberRepository>(),
        audioService: sl<AudioService>(),
        progressService: sl<ProgressService>(),
      ),
    )
    ..registerFactory<QuizBloc>(
      () => QuizBloc(
        repository: sl<QuizRepository>(),
        audioService: sl<AudioService>(),
        progressService: sl<ProgressService>(),
      ),
    )
    ..registerFactory<PuzzleCatalogCubit>(
      () => PuzzleCatalogCubit(
        repository: sl<PuzzleRepository>(),
        progress: sl<ProgressService>(),
      ),
    );

  // The parent's sound/voice switches drive every play and speak call, so the
  // cubit stream is pushed straight into the audio service once at startup.
  final SettingsCubit settings = sl<SettingsCubit>();
  final AudioService audio = sl<AudioService>();
  void applyAudioSettings(SettingsState state) {
    audio.configure(
      soundEnabled: state.soundEnabled,
      voiceEnabled: state.voiceEnabled,
      speechRate: state.speechRate,
      voiceName: state.voiceName,
    );
  }

  applyAudioSettings(settings.state);
  settings.stream.listen(applyAudioSettings);
}