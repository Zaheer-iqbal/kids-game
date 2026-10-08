import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_cubit.dart';
import '../../../../core/mascot/mascot_mood.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/letter_item.dart';
import '../bloc/alphabet_bloc.dart';
import '../bloc/alphabet_event.dart';
import '../bloc/alphabet_state.dart';
import '../widgets/letter_card.dart';
import '../widgets/letter_detail_sheet.dart';

/// The A–Z alphabet learning experience: header with progress plus the letter
/// grid. Reused by the Home "Alphabet" tab.
class AlphabetSection extends StatelessWidget {
  const AlphabetSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AlphabetBloc>(
      create: (_) => di.sl<AlphabetBloc>()..add(const LoadAlphabet()),
      child: const AlphabetView(),
    );
  }
}

class AlphabetView extends StatelessWidget {
  const AlphabetView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlphabetBloc, AlphabetState>(
      builder: (BuildContext context, AlphabetState state) {
        return switch (state) {
          AlphabetInitial() || AlphabetLoading() =>
            const Center(child: CircularProgressIndicator()),
          AlphabetError(:final String message) => _ErrorView(message: message),
          AlphabetLoaded(:final letters, :final explored) =>
            AlphabetContent(letters: letters, explored: explored),
        };
      },
    );
  }
}

class AlphabetContent extends StatelessWidget {
  const AlphabetContent({super.key, required this.letters, required this.explored});

  final List<LetterItem> letters;
  final Set<String> explored;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AlphabetHeader(letters: letters, explored: explored),
          const SizedBox(height: 12),
          Expanded(child: _AlphabetGrid(letters: letters, explored: explored)),
        ],
      ),
    );
  }
}

class AlphabetHeader extends StatelessWidget {
  const AlphabetHeader({super.key, required this.letters, required this.explored});

  final List<LetterItem> letters;
  final Set<String> explored;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int total = letters.length;
    final int count = explored.length;
    final double fraction = total == 0 ? 0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'ABC Fun',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 24),
                  const SizedBox(width: 6),
                  Text(
                    '$count / $total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 14,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[AppColors.gold, AppColors.quiz],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count of $total letters explored',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _AlphabetGrid extends StatelessWidget {
  const _AlphabetGrid({required this.letters, required this.explored});

  final List<LetterItem> letters;
  final Set<String> explored;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      itemCount: letters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (BuildContext context, int index) {
        final LetterItem letter = letters[index];
        return LetterCard(
          key: ValueKey<String>('letter-${letter.letter}'),
          letter: letter,
          explored: explored.contains(letter.letter),
          onTap: () {
            final bool firstLook = !explored.contains(letter.letter);
            context.read<AlphabetBloc>().add(LetterTapped(letter));
            // Pip stays quiet here (the letter's own phonics is speaking) but
            // jumps when a brand new star is earned.
            context.read<MascotCubit>().setMood(
                  firstLook ? MascotMood.excited : MascotMood.happy,
                );
            unawaited(LetterDetailSheet.show(context, letter));
          },
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.sentiment_dissatisfied_rounded,
              size: 56, color: AppColors.inkMuted),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () =>
                context.read<AlphabetBloc>().add(const LoadAlphabet()),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}