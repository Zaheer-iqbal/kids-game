import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'core/mascot/mascot_cubit.dart';
import 'core/router/app_router.dart';
import 'core/settings/presentation/settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/delight_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        child: MaterialApp.router(
          title: 'ABC Kids',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: di.sl<AppRouter>().router,
          // Kid screens are laid out at 1.0-1.3x; larger system scaling is
          // capped so text never clips or overflows its cards.
          builder: (BuildContext context, Widget? child) => DelightScope(
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
