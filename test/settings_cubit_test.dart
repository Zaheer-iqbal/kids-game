import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/settings/data/settings_repository_impl.dart';
import 'package:kids/core/settings/domain/app_settings.dart';
import 'package:kids/core/settings/domain/settings_repository.dart';
import 'package:kids/core/settings/presentation/settings_cubit.dart';
import 'package:kids/core/settings/presentation/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens an in-memory store seeded with [prefs] and a cubit that already read
/// it — the same order the app uses during dependency configuration.
Future<SettingsCubit> loadedCubit([
  Map<String, Object> prefs = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences store = await SharedPreferences.getInstance();
  return SettingsCubit(repository: SettingsRepositoryImpl(store))..load();
}

void main() {
  group('SettingsCubit', () {
    test('a fresh install has every delight feature switched on', () async {
      final SettingsCubit cubit = await loadedCubit();

      expect(cubit.state.settings, AppSettings.defaults);
      expect(cubit.state.isLoaded, isTrue);

      await cubit.close();
    });

    test('load reads what a previous session stored', () async {
      final SettingsCubit cubit = await loadedCubit(<String, Object>{
        SettingsRepositoryImpl.animationsKey: false,
        SettingsRepositoryImpl.sparklesKey: false,
        SettingsRepositoryImpl.speechKey: false,
      });

      expect(cubit.state.animationsEnabled, isFalse);
      expect(cubit.state.sparklesEnabled, isFalse);
      expect(cubit.state.mascotSpeechEnabled, isFalse);

      await cubit.close();
    });

    test('a switch emits immediately so the UI never waits on the disk',
        () async {
      final SettingsCubit cubit = await loadedCubit();
      final List<SettingsState> seen = <SettingsState>[];
      final sub = cubit.stream.listen(seen.add);

      cubit.setSparklesEnabled(false);
      await pumpEventQueue();

      expect(seen, hasLength(1));
      expect(seen.single.sparklesEnabled, isFalse);
      // Untouched switches keep their value.
      expect(seen.single.animationsEnabled, isTrue);
      expect(seen.single.mascotSpeechEnabled, isTrue);

      await sub.cancel();
      await cubit.close();
    });

    test('switches survive a restart', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences store = await SharedPreferences.getInstance();
      final SettingsCubit cubit =
          SettingsCubit(repository: SettingsRepositoryImpl(store))..load();

      cubit
        ..setAnimationsEnabled(false)
        ..setMascotSpeechEnabled(false);
      await pumpEventQueue();
      await cubit.close();

      // Same store, brand new cubit: the stored values must come back.
      final SettingsCubit reopened =
          SettingsCubit(repository: SettingsRepositoryImpl(store))..load();
      expect(reopened.state.animationsEnabled, isFalse);
      expect(reopened.state.mascotSpeechEnabled, isFalse);
      expect(reopened.state.sparklesEnabled, isTrue);

      await reopened.close();
    });

    test('the toggle helpers flip whatever is currently stored', () async {
      final SettingsCubit cubit = await loadedCubit();

      cubit
        ..toggleAnimations()
        ..toggleSparkles()
        ..toggleMascotSpeech();
      expect(cubit.state.settings, AppSettings.defaults.copyWith(
        animationsEnabled: false,
        sparklesEnabled: false,
        mascotSpeechEnabled: false,
      ));

      // Flipping back returns to the defaults.
      cubit
        ..toggleAnimations()
        ..toggleSparkles()
        ..toggleMascotSpeech();
      expect(cubit.state.settings, AppSettings.defaults);

      await cubit.close();
    });

    test('resetToDefaults puts every switch back on and persists it', () async {
      final SettingsCubit cubit = await loadedCubit(<String, Object>{
        SettingsRepositoryImpl.animationsKey: false,
        SettingsRepositoryImpl.sparklesKey: false,
        SettingsRepositoryImpl.speechKey: false,
      });

      cubit.resetToDefaults();
      expect(cubit.state.settings, AppSettings.defaults);
      await pumpEventQueue();

      final SharedPreferences store = await SharedPreferences.getInstance();
      expect(
        store.getBool(SettingsRepositoryImpl.animationsKey),
        isTrue,
        reason: 'the reset must be written to storage, not just to memory',
      );
      expect(store.getBool(SettingsRepositoryImpl.sparklesKey), isTrue);
      expect(store.getBool(SettingsRepositoryImpl.speechKey), isTrue);

      await cubit.close();
    });

    test('a failed write cannot break the screen', () async {
      final SettingsCubit cubit =
          SettingsCubit(repository: const _BrokenRepository())
            ..load();

      cubit.setAnimationsEnabled(false);

      expect(cubit.state.animationsEnabled, isFalse);
      await cubit.close();
    });
  });
}

/// Repository whose writes always fail, to prove the cubit emits first.
class _BrokenRepository implements SettingsRepository {
  const _BrokenRepository();

  @override
  AppSettings load() => AppSettings.defaults;

  @override
  Future<void> save(AppSettings settings) async =>
      throw StateError('disk is full');
}
