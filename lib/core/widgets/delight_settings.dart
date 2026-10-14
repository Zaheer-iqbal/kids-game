import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../settings/presentation/settings_cubit.dart';
import '../settings/presentation/settings_state.dart';

/// Snapshot of the delight switches that animation widgets read.
///
/// Widgets never touch the cubit directly: they ask for this value, which keeps
/// them usable in isolation (unit/widget tests, previews) and makes the
/// "everything is on" default explicit in one place.
@immutable
class DelightSettings {
  const DelightSettings({
    this.animationsEnabled = true,
    this.sparklesEnabled = true,
    this.reduceMotion = false,
  });

  /// Used when no [DelightScope] is above the widget.
  static const DelightSettings defaults = DelightSettings();

  final bool animationsEnabled;
  final bool sparklesEnabled;

  /// Parent switch: keep only simple fades and never move or scale a surface.
  final bool reduceMotion;

  /// Reads the settings in scope, falling back to everything-on when the widget
  /// is used outside the app shell (tests, previews).
  static DelightSettings of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_DelightScope>()
            ?.settings ??
        defaults;
  }

  @override
  bool operator ==(Object other) =>
      other is DelightSettings &&
      other.animationsEnabled == animationsEnabled &&
      other.sparklesEnabled == sparklesEnabled &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode =>
      Object.hash(animationsEnabled, sparklesEnabled, reduceMotion);
}

/// Publishes the current settings to the whole widget tree.
///
/// Dependents rebuild only when a switch actually flips, and animations are
/// driven by their own controllers, so a settings change never costs a frame
/// budget beyond one rebuild of the widgets that read it.
class DelightScope extends StatelessWidget {
  const DelightScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (SettingsState previous, SettingsState current) =>
          previous.animationsEnabled != current.animationsEnabled ||
          previous.sparklesEnabled != current.sparklesEnabled ||
          previous.reduceMotion != current.reduceMotion,
      builder: (BuildContext context, SettingsState state) {
        return _DelightScope(
          settings: DelightSettings(
            animationsEnabled: state.animationsEnabled,
            sparklesEnabled: state.sparklesEnabled,
            reduceMotion: state.reduceMotion,
          ),
          child: child,
        );
      },
    );
  }
}

class _DelightScope extends InheritedWidget {
  const _DelightScope({required this.settings, required super.child});

  final DelightSettings settings;

  @override
  bool updateShouldNotify(_DelightScope oldWidget) =>
      oldWidget.settings != settings;
}
