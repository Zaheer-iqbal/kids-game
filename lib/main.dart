import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'core/mascot/mascot_cubit.dart';
import 'core/router/app_router.dart';
import 'core/settings/presentation/settings_cubit.dart';
import 'core/settings/presentation/settings_state.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/delight_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The whole app is light: dark icons on the light status and navigation
  // bars, set once here and re-asserted by every AppBar's theme.
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  await di.configureDependencies();
  runApp(const AlphabetKidsApp());
}

class AlphabetKidsApp extends StatelessWidget {
  const AlphabetKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The mascot and the parent settings are app-wide singletons, so they are
    // provided once above the router: every screen can read them and they keep
    // their state (and their timers) across navigation.
    return BlocProvider<MascotCubit>.value(
      value: di.sl<MascotCubit>(),
      child: BlocProvider<SettingsCubit>.value(
        value: di.sl<SettingsCubit>(),
        // Re-build MaterialApp whenever the theme colour changes so every
        // screen picks up the new scaffold background immediately.
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (SettingsState prev, SettingsState next) =>
              prev.themeColorIndex != next.themeColorIndex,
          builder: (BuildContext context, SettingsState settings) {
            final AppThemeOption theme =
                AppThemeColors.get(settings.themeColorIndex);
            return MaterialApp.router(
              title: 'Owlie',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light.copyWith(
                scaffoldBackgroundColor: theme.bg,
                colorScheme: AppTheme.light.colorScheme.copyWith(
                  surface: theme.bg,
                ),
              ),
              // A single light theme, explicitly locked: the phone's dark-mode
              // setting must never flip a surface to black or a label to white.
              darkTheme: AppTheme.light.copyWith(
                scaffoldBackgroundColor: theme.bg,
                colorScheme: AppTheme.light.colorScheme.copyWith(
                  surface: theme.bg,
                ),
              ),
              themeMode: ThemeMode.light,
              routerConfig: di.sl<AppRouter>().router,
              // Kid screens respond down to 0.85x and up to 1.6x.
              builder: (BuildContext ctx, Widget? child) =>
                  AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.overlayStyle,
                child: DelightScope(
                  child: MediaQuery.withClampedTextScaling(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.6,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}