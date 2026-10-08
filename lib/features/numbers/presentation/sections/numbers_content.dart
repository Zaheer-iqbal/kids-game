import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_cubit.dart';
import '../../../../core/mascot/mascot_mood.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/number_entity.dart';
import '../bloc/number_bloc.dart';
import '../bloc/number_event.dart';
import '../bloc/number_state.dart';
import '../widgets/number_card.dart';
import '../widgets/number_detail_sheet.dart';

/// Numbers learning experience: a Bloc-backed "123" header and the 1–100 grid.
/// Reused by the Home "Numbers" tab and the standalone `/numbers` route.
class NumbersSection extends StatelessWidget {
  const NumbersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NumberBloc>(
      create: (_) => di.sl<NumberBloc>()..add(const LoadNumbers()),
      child: const NumbersView(),
    );
  }
}

class NumbersView extends StatelessWidget {
  const NumbersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NumberBloc, NumberState>(
      builder: (BuildContext context, NumberState state) {
        return switch (state) {
          NumberInitial() || NumberLoading() =>
            const Center(child: CircularProgressIndicator()),
          NumberError(:final String message) => _ErrorView(message: message),
          NumberLoaded(:final numbers, :final explored) =>
            NumbersContent(numbers: numbers, explored: explored),
        };
      },
    );
  }
}

class NumbersContent extends StatelessWidget {
  const NumbersContent({super.key, required this.numbers, required this.explored});

  final List<NumberEntity> numbers;
  final Set<String> explored;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NumbersHeader(numbers: numbers, explored: explored),
          const SizedBox(height: 12),
          Expanded(child: _NumberGrid(numbers: numbers, explored: explored)),
        ],
      ),
    );
  }
}

class NumbersHeader extends StatelessWidget {
  const NumbersHeader({super.key, required this.numbers, required this.explored});

  final List<NumberEntity> numbers;
  final Set<String> explored;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int total = numbers.length;
    final int count = explored.length;
    final double fraction = total == 0 ? 0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '123 Count',
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
            const SizedBox(width: 14),
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
                  const Icon(Icons.tag_rounded, color: AppColors.inkMuted, size: 24),
                  const SizedBox(width: 6),
                  Text(
                    '$total',
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
        const SizedBox(height: 14),
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
          '$count of $total numbers explored',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _NumberGrid extends StatelessWidget {
  const _NumberGrid({required this.numbers, required this.explored});

  final List<NumberEntity> numbers;
  final Set<String> explored;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      itemCount: numbers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (BuildContext context, int index) {
        final NumberEntity number = numbers[index];
        return NumberCard(
          key: ValueKey<String>('number-${number.number}'),
          number: number,
          explored: explored.contains('${number.number}'),
          onTap: () {
            final bool firstLook = !explored.contains('${number.number}');
            context.read<NumberBloc>().add(NumberTapped(number));
            // Quiet (the number is read out loud instead), but a brand new
            // star gets Pip's excited wiggle.
            context.read<MascotCubit>().setMood(
                  firstLook ? MascotMood.excited : MascotMood.happy,
                );
            unawaited(NumberDetailSheet.show(context, number));
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
          const Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 56,
            color: AppColors.inkMuted,
          ),
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
                context.read<NumberBloc>().add(const LoadNumbers()),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}