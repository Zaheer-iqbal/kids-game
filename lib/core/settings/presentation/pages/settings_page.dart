import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/injection_container.dart' as di;
import '../../../services/audio_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/mascot_view.dart';
import '../../../widgets/parental_gate.dart';
import '../../domain/app_settings.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          'For parents and carers. No account needed.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 18),
        const _MascotPreview(),
        const SizedBox(height: 22),
        Text(
          'App Background Theme',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (SettingsState prev, SettingsState next) =>
              prev.themeColorIndex != next.themeColorIndex,
          builder: (BuildContext context, SettingsState state) {
            final SettingsCubit cubit = context.read<SettingsCubit>();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xDDEFDFCF), width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Changes background color across all screens:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(
                      AppThemeColors.themes.length,
                      (int i) {
                        final AppThemeOption opt = AppThemeColors.themes[i];
                        final bool active = state.themeColorIndex == i;
                        return GestureDetector(
                          onTap: () => cubit.setThemeColor(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 90,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: opt.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF4C3FB5)
                                    : const Color(0xFFE2E8F0),
                                width: active ? 2.5 : 1.5,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: active ? 0.12 : 0.04),
                                  blurRadius: active ? 6 : 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(opt.icon,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(
                                  opt.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? const Color(0xFF4C3FB5)
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          'Mascot & Effects',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.ink,
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
                const SizedBox(height: 12),
                _SwitchRow(
                  icon: Icons.motion_photos_off_rounded,
                  title: 'Reduce motion',
                  subtitle:
                      'Gentle fades only. Your phone\u2019s setting is honoured '
                      'either way.',
                  value: state.reduceMotion,
                  onChanged: cubit.setReduceMotion,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        const _VoiceControlsCard(),
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

/// Voice picker and speaking-speed slider, kept behind the grown-up gate so a
/// curious child cannot change how the app sounds. The voice list comes from
/// the device engine, so a parent chooses from real voices, not a fixed set.
class _VoiceControlsCard extends StatefulWidget {
  const _VoiceControlsCard();

  @override
  State<_VoiceControlsCard> createState() => _VoiceControlsCardState();
}

class _VoiceControlsCardState extends State<_VoiceControlsCard> {
  bool _unlocked = false;
  Future<List<String>>? _voices;

  Future<void> _unlock() async {
    final bool allowed = await showParentalGate(context);
    if (!allowed || !mounted) return;
    setState(() {
      _unlocked = true;
      _voices = di.sl<AudioService>().listVoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.quiz.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _unlocked ? Icons.graphic_eq_rounded : Icons.lock_rounded,
                  color: AppColors.quiz,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Voice & speed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _unlocked
                          ? 'Pick the reading voice and how fast it speaks.'
                          : 'Grown-ups only. Unlock to choose who reads to '
                              'your child.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              if (!_unlocked)
                TextButton(onPressed: _unlock, child: const Text('Unlock')),
            ],
          ),
          if (_unlocked) ...<Widget>[
            const SizedBox(height: 14),
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (BuildContext context, SettingsState state) {
                final SettingsCubit cubit = context.read<SettingsCubit>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Speaking speed',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: state.speechRate
                          .clamp(
                            AppSettings.minSpeechRate,
                            AppSettings.maxSpeechRate,
                          )
                          .toDouble(),
                      min: AppSettings.minSpeechRate,
                      max: AppSettings.maxSpeechRate,
                      divisions: 10,
                      label: '${(state.speechRate * 100).round()}%',
                      activeColor: AppColors.quiz,
                      onChanged: cubit.setSpeechRate,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reading voice',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _VoiceDropdown(
                      voices: _voices,
                      selected: state.voiceName,
                      onChanged: cubit.setVoiceName,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => di.sl<AudioService>().testVoice(),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Test voice'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The device voice picker. "Automatic" (null) lets the app choose the best
/// English voice; every other entry is a voice the engine actually reported.
class _VoiceDropdown extends StatelessWidget {
  const _VoiceDropdown({
    required this.voices,
    required this.selected,
    required this.onChanged,
  });

  final Future<List<String>>? voices;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: voices,
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        final List<String> names = snapshot.data ?? const <String>[];
        final bool loading =
            snapshot.connectionState == ConnectionState.waiting;
        final String? current =
            selected != null && names.contains(selected) ? selected : null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineSoft, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: current,
              isExpanded: true,
              hint: Text(loading ? 'Looking for voices…' : 'Automatic'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Automatic (best for this device)'),
                ),
                for (final String name in names)
                  DropdownMenuItem<String?>(
                    value: name,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: loading ? null : onChanged,
            ),
          ),
        );
      },
    );
  }
}
