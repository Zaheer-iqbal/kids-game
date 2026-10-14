import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/animal.dart';
import '../../domain/repositories/puzzle_repository.dart';
import '../bloc/puzzle_bloc.dart';
import '../bloc/puzzle_event.dart';
import '../bloc/puzzle_state.dart';
import 'animal_picture.dart';

/// The shadow-match board: the animal is shown in colour and the child taps
/// the matching silhouette among friendly decoys.
class ShadowMatchBoard extends StatelessWidget {
  const ShadowMatchBoard({super.key, required this.state});

  final PuzzleState state;

  @override
  Widget build(BuildContext context) {
    final Animal? animal = state.animal;
    if (animal == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth > 520;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _TargetCard(animal: animal, size: wide ? 180 : 140),
            const SizedBox(height: AppTokens.space5),
            Text(
              'Which shadow matches?',
              textAlign: TextAlign.center,
              style: AppTheme.glyphStyle(
                wide ? 26 : 22,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppTokens.space4,
              runSpacing: AppTokens.space4,
              children: <Widget>[
                for (int i = 0; i < state.options.length; i++)
                  _ShadowOption(
                    optionAnimal:
                        di.sl<PuzzleRepository>().animalAt(state.options[i]),
                    highlighted: state.hintSlot == i,
                    size: wide ? 120 : 96,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.animal, required this.size});

  final Animal animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimalPicture(animal: animal, size: size),
        const SizedBox(height: AppTokens.space2),
        Text(
          animal.name,
          style: AppTheme.glyphStyle(22, color: AppColors.ink),
        ),
      ],
    );
  }
}

class _ShadowOption extends StatelessWidget {
  const _ShadowOption({
    required this.optionAnimal,
    required this.highlighted,
    required this.size,
  });

  final Animal optionAnimal;
  final bool highlighted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget swatch = AnimalPicture(
      animal: optionAnimal,
      size: size - 16,
      silhouette: true,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(
          color: highlighted ? AppColors.gold : AppColors.outlineSoft,
          width: highlighted ? 4 : 2,
        ),
        boxShadow: AppTokens.softShadow(blur: 12, dy: 5),
      ),
      child: Semantics(
        label: 'Shadow of ${optionAnimal.name}',
        button: true,
        child: GestureDetector(
          onTap: () => context.read<PuzzleBloc>().add(
                ShadowOptionSelected(optionAnimal.id),
              ),
          child: swatch,
        ),
      ),
    );
  }
}