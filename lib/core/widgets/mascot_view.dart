import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../mascot/mascot_cubit.dart';
import '../mascot/mascot_state.dart';
import 'mascot_painter.dart';
import 'mascot_widget.dart';

/// Binds the [MascotCubit] to a [MascotWidget].
///
/// Screens place this instead of the raw widget, so there is exactly one place
/// that knows how a mood becomes a pose and a tap becomes a giggle. Only the
/// mascot subtree rebuilds when the mood changes — the grid around it does not.
class MascotView extends StatelessWidget {
  const MascotView({
    super.key,
    this.size = 120,
    this.bubbleLayout = MascotBubbleLayout.above,
    this.bubbleMaxWidth = 230,
    this.palette = MascotPalette.owl,
    this.showBubble = true,
  });

  final double size;
  final MascotBubbleLayout bubbleLayout;
  final double bubbleMaxWidth;
  final MascotPalette palette;

  /// Off for a decorative mascot that should never talk.
  final bool showBubble;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MascotCubit, MascotState>(
      buildWhen: (MascotState previous, MascotState current) =>
          previous != current,
      builder: (BuildContext context, MascotState state) {
        final MascotCubit cubit = context.read<MascotCubit>();
        return MascotWidget(
          mood: state.mood,
          size: size,
          message: showBubble ? state.message : null,
          reactionToken: state.token,
          giggleToken: state.giggleToken,
          palette: palette,
          bubbleLayout: bubbleLayout,
          bubbleMaxWidth: bubbleMaxWidth,
          onTap: cubit.giggle,
          onSettle: cubit.idle,
        );
      },
    );
  }
}
