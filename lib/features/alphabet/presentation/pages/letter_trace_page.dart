import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tracing/presentation/pages/trace_play_page.dart';
import '../../domain/entities/letter_item.dart';
import '../../domain/repositories/alphabet_repository.dart';

/// Full-screen finger-tracing for the letters of the alphabet. Opens on the
/// [letter] that was tapped and lets "Next" walk up to Z.
class LetterTracePage extends StatefulWidget {
  const LetterTracePage({super.key, required this.letter});

  final String letter;

  @override
  State<LetterTracePage> createState() => _LetterTracePageState();
}

class _LetterTracePageState extends State<LetterTracePage> {
  late final Future<List<LetterItem>> _letters =
      di.sl<AlphabetRepository>().getLetters();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LetterItem>>(
      future: _letters,
      builder: (BuildContext context, AsyncSnapshot<List<LetterItem>> snapshot) {
        final List<LetterItem> letters = snapshot.data ?? const <LetterItem>[];
        if (letters.isEmpty) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final String target = widget.letter.toUpperCase();
        final int index = letters.indexWhere(
          (LetterItem item) => item.letter.toUpperCase() == target,
        );
        return TracePlayPage(
          title: 'Trace the letter',
          initialIndex: index < 0 ? 0 : index,
          items: <TraceGlyphItem>[
            for (final LetterItem item in letters)
              TraceGlyphItem(
                glyph: item.letter,
                label: item.label,
                word: item.word,
                colorValue: item.colorValue,
                emoji: item.emoji,
              ),
          ],
          announce: (TraceGlyphItem item) => di
              .sl<AudioService>()
              .speakPhonics(item.glyph, item.word ?? item.label),
        );
      },
    );
  }
}
