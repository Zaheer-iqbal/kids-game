import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/emoji_picture.dart';
import '../../../../core/widgets/tracing_canvas.dart';

/// One traceable subject: the glyph to walk with a finger plus a friendly
/// label, colour and picture so the page can show what is being traced.
class TraceGlyphItem {
  const TraceGlyphItem({
    required this.glyph,
    required this.label,
    required this.colorValue,
    this.word,
    this.emoji,
  });

  /// The characters to trace, e.g. `"A"` or `"12"`.
  final String glyph;

  /// Child-facing label, e.g. `"A for Apple"` or `"One"`.
  final String label;

  /// Opaque ARGB colour.
  final int colorValue;

  /// Spoken word (without the glyph), used by the announce callback.
  final String? word;

  /// Optional emoji picture shown above the canvas.
  final String? emoji;

  Color get color => Color(colorValue);
}

/// Full-screen tracing surface shared by letters and numbers.
///
/// One big canvas per glyph, a gentle nudge to trace the whole shape, and a
/// large green "Next" that only appears once the trace is 100 % complete — so a
/// child is never rushed, and "Next" always means "you did it".
class TracePlayPage extends StatefulWidget {
  const TracePlayPage({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.title,
    required this.announce,
  });

  final List<TraceGlyphItem> items;
  final int initialIndex;
  final String title;

  /// Speaks the current item when the page opens or "Next" advances to it.
  final Future<void> Function(TraceGlyphItem item) announce;

  @override
  State<TracePlayPage> createState() => _TracePlayPageState();
}

class _TracePlayPageState extends State<TracePlayPage>
    with SingleTickerProviderStateMixin {
  late int _index = widget.initialIndex.clamp(0, widget.items.length - 1);
  bool _traced = false;

  // Subtle pulse on the hint text
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.92,
    upperBound: 1.0,
  )..repeat(reverse: true);

  TraceGlyphItem get _current => widget.items[_index];

  @override
  void initState() {
    super.initState();
    unawaited(widget.announce(_current));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onCompleted() {
    setState(() => _traced = true);
    di.sl<MascotCubit>().excited(speak: true, message: 'Great job!');
    unawaited(showCelebrationOverlay(context, message: 'Great job! 🎉'));
  }

  void _next() {
    if (_index >= widget.items.length - 1) {
      context.pop();
      return;
    }
    setState(() {
      _index++;
      _traced = false;
    });
    unawaited(widget.announce(_current));
  }

  @override
  Widget build(BuildContext context) {
    final TraceGlyphItem item = _current;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // ── top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 30),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    // large letter badge
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        item.glyph,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            widget.title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // emoji picture on the right
                    if (item.emoji != null)
                      EmojiPicture(
                        emoji: item.emoji!,
                        color: item.color,
                        fontSize: 40,
                      ),
                  ],
                ),
              ),

              // ── full-size tracing canvas ─────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TracingCanvas(
                      key: ValueKey<String>('trace-${item.glyph}'),
                      label: item.glyph,
                      color: item.color,
                      onCompleted: _onCompleted,
                      onReset: () => setState(() => _traced = false),
                    ),
                  ),
                ),
              ),

              // ── bottom action area ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: SizedBox(
                  height: 66,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                        child: child,
                      );
                    },
                    child: _traced
                        ? SizedBox(
                            key: const ValueKey<String>('trace-next'),
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 30),
                              label: Text(
                                _index >= widget.items.length - 1
                                    ? 'Finish! 🎉'
                                    : 'Next ➜',
                              ),
                            ),
                          )
                        : ScaleTransition(
                            key: const ValueKey<String>('trace-hint'),
                            scale: _pulseCtrl,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.inkMuted.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.gesture_rounded,
                                      size: 22,
                                      color: AppColors.inkMuted
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Trace the whole shape!',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.inkMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
