import 'dart:async';

import 'package:flutter/material.dart';

import '../di/injection_container.dart' as di;
import '../mascot/mascot_cubit.dart';
import '../mascot/mascot_mood.dart';
import '../motion/app_motion.dart';
import '../theme/app_colors.dart';
import 'delight_settings.dart';
import 'mascot_painter.dart';
import 'mascot_widget.dart';
import 'particle_field.dart';

/// Launches a cheerful full-screen confetti burst with a check badge and Pip,
/// the mascot, cheering at full size.
///
/// Rendered above everything (own overlay route) so it works from a bottom
/// sheet or any screen. Auto-dismisses after [autoDismiss].
Future<void> showCelebrationOverlay(
  BuildContext context, {
  String? message,
  Duration autoDismiss = const Duration(milliseconds: 2000),
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (BuildContext context, Animation<double> animation, _, Widget? child) {
      return FadeTransition(opacity: animation, child: child);
    },
    pageBuilder: (BuildContext context, Animation<double> _, __) =>
        _CelebrationDialog(message: message, autoDismiss: autoDismiss),
  );
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog({this.message, required this.autoDismiss});

  final String? message;
  final Duration autoDismiss;

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoDismiss, _dismiss);
  }

  void _dismiss() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool animate = DelightSettings.of(context).animationsEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Code-drawn confetti (no particle package): one burst from the
          // centre of the screen that rains down while the child celebrates.
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return ParticleBurst(
                origin: Offset(
                  constraints.maxWidth / 2,
                  constraints.maxHeight * 0.42,
                ),
                count: 90,
                spread: 1.6,
                colors: AppColors.letterPalette,
                duration: const Duration(milliseconds: 1600),
              );
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
            child: Center(
              child: AppMotion(
                style: MotionPresets.dialogIn,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                      // The mascot takes over the celebration: always excited,
                      // in his warm "sunny" colours, cheering the child on.
                      MascotWidget(
                        mood: MascotMood.excited,
                        size: animate ? 150 : 132,
                        palette: MascotPalette.sunny,
                        message: di.sl<MascotCubit>()
                            .randomLineFor(MascotMood.excited),
                        bubbleLayout: MascotBubbleLayout.above,
                        bubbleMaxWidth: 260,
                      ),
                      if (widget.message != null) ...<Widget>[
                        const SizedBox(height: 8),
                        // A solid white pill with dark ink text always stays
                        // readable, whatever the light scene behind it.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }
}