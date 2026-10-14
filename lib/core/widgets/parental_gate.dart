import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// A simple grown-up gate: to reach the parent settings the adult presses and
/// holds a button for a moment. Curious small fingers rarely hold still that
/// long, so it keeps little ones inside the game without a password.
///
/// Returns true when the hold completed and the settings may open.
Future<bool> showParentalGate(BuildContext context) async {
  final bool? allowed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => const _ParentalGateDialog(),
  );
  return allowed ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog>
    with SingleTickerProviderStateMixin {
  /// Hold time for the gate; a touch shorter than this cancels.
  static const Duration holdDuration = Duration(milliseconds: 1200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: holdDuration,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppTokens.space5),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock_rounded, size: 40, color: AppColors.inkSoft),
            const SizedBox(height: AppTokens.space3),
            Text(
              'For grown-ups',
              style: AppTheme.glyphStyle(24, color: AppColors.ink),
            ),
            const SizedBox(height: AppTokens.space2),
            const Text(
              'Press and hold the button to open settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            _HoldButton(controller: _controller),
            const SizedBox(height: AppTokens.space3),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hold to open settings',
      child: GestureDetector(
        onTapDown: (_) => controller.forward(),
        onTapUp: (_) => controller.reverse(),
        onTapCancel: controller.reverse,
        child: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return Container(
              height: AppTokens.buttonHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                color: AppColors.surfaceSoft,
                border: Border.all(color: AppColors.outlineSoft, width: 2),
              ),
              child: Stack(
                children: <Widget>[
                  FractionallySizedBox(
                    widthFactor: controller.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusPill),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      controller.value == 0
                          ? 'Hold to continue'
                          : 'Keep holding…',
                      style: const TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}