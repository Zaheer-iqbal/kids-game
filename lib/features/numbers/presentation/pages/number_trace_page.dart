import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tracing/presentation/pages/trace_play_page.dart';
import '../../domain/entities/number_entity.dart';
import '../../domain/repositories/number_repository.dart';

/// Full-screen finger-tracing for the numbers 1–100. Opens on the [number]
/// that was tapped and lets "Next" count up from there.
class NumberTracePage extends StatefulWidget {
  const NumberTracePage({super.key, required this.number});

  final int number;

  @override
  State<NumberTracePage> createState() => _NumberTracePageState();
}

class _NumberTracePageState extends State<NumberTracePage> {
  late final Future<List<NumberEntity>> _numbers =
      di.sl<NumberRepository>().getNumbers();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NumberEntity>>(
      future: _numbers,
      builder:
          (BuildContext context, AsyncSnapshot<List<NumberEntity>> snapshot) {
        final List<NumberEntity> numbers = snapshot.data ?? const <NumberEntity>[];
        if (numbers.isEmpty) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final int index = numbers.indexWhere(
          (NumberEntity item) => item.number == widget.number,
        );
        return TracePlayPage(
          title: 'Trace the number',
          initialIndex: index < 0 ? 0 : index,
          items: <TraceGlyphItem>[
            for (final NumberEntity item in numbers)
              TraceGlyphItem(
                glyph: '${item.number}',
                label: item.word,
                word: item.word,
                colorValue: item.colorValue,
                emoji: item.emoji,
              ),
          ],
          announce: (TraceGlyphItem item) => di
              .sl<AudioService>()
              .speakNumber(item.word ?? item.label, value: int.tryParse(item.glyph)),
        );
      },
    );
  }
}
