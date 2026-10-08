import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/mascot_view.dart';
import '../settings_cubit.dart';
import '../settings_state.dart';

/// Parent-facing switches for the mascot and the delight animations.
///
/// [SettingsPage] is the standalone route (with a back affordance);
/// [SettingsView] is the bare content reused by the home shell's Grown-ups
/// tab. Deliberately simple: a handful of toggles, a live preview and no
/// account, login or any other ceremony — a parent should be able to mute the
/// sparkle in two taps and get back to the game.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 30),
                    tooltip: 'Back to home',
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Expanded(child: SettingsView()),
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        Text(
          'Grown-up Settings',
          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'For parents and carers. No account needed.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 18),
        const _MascotPreview(),
        const SizedBox(height: 22),
        Text(
          'Mascot & Effects',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (BuildContext context, SettingsState state) {
            final SettingsCubit cubit = context.read<SettingsCubit>();
            return Column(
              children: <Widget>[
                _SwitchRow(
                  icon: Icons.animation_rounded,
                  title: 'Mascot animations',
                  subtitle: 'Breathing, blinking, jumping and wiggling.',
                  value: state.animationsEnabled,
                  onChanged: cubit.setAnimationsEnabled,
                ),
                const SizedBox(height: 12),
                _SwitchRow(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Sparkle surprises',
                  subtitle: 'A few twinkles now and then on a card.',
                  value: state.sparklesEnabled,
                  onChanged: cubit.setSparklesEnabled,
                ),
                const SizedBox(height: 12),
                _SwitchRow(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Mascot voice',
                  subtitle: 'Let Pip read his own words out loud.',
                  value: state.mascotSpeechEnabled,
                  onChanged: cubit.setMascotSpeechEnabled,
                ),
                const SizedBox(height: 12),
                _SwitchRow(
                  icon: Icons.music_note_rounded,
                  title: 'Sound effects',
                  subtitle: 'Pops, chimes and fanfares for taps and wins.',
                  value: state.soundEnabled,
                  onChanged: cubit.setSoundEnabled,
                ),
                const SizedBox(height: 12),
                _SwitchRow(
                  icon: Icons.volume_up_rounded,
                  title: 'Voice narration',
                  subtitle:
                      'Reading letters, numbers, questions and facts aloud.',
                  value: state.voiceEnabled,
                  onChanged: cubit.setVoiceEnabled,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => context.read<SettingsCubit>().resetToDefaults(),
          icon: const Icon(Icons.restart_alt_rounded, size: 24),
          label: const Text('Turn everything back on'),
        ),
      ],
    );
  }
}

/// Live mascot so a parent can hear and see the effect of each switch straight
/// away instead of guessing from a checkbox.
class _MascotPreview extends StatelessWidget {
  const _MascotPreview();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xDDEFDFCF), width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          BlocBuilder<SettingsCubit, SettingsState>(
            buildWhen: (SettingsState previous, SettingsState current) =>
                previous.mascotSpeechEnabled != current.mascotSpeechEnabled,
            builder: (BuildContext context, SettingsState state) {
              return Text(
                state.mascotSpeechEnabled
                    ? 'Tap Pip below to hear him!'
                    : 'Pip is quiet right now.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.inkMuted),
              );
            },
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.center,
            child: MascotView(
              key: ValueKey<String>('settings-mascot-preview'),
              size: 132,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xDDEFDFCF), width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (value ? AppColors.quiz : AppColors.inkMuted)
                  .withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? AppColors.quiz : AppColors.inkMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}
