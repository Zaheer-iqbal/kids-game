import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../domain/entities/animal.dart';
import '../../domain/repositories/puzzle_repository.dart';
import '../bloc/puzzle_catalog_cubit.dart';
import '../widgets/animal_picture.dart';

/// "My Animals": the sticker album that fills up as puzzles are solved. Each
/// unlocked animal can be tapped to hear its name and read a fun fact.
class MyAnimalsPage extends StatelessWidget {
  const MyAnimalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PuzzleCatalogCubit>(
      create: (BuildContext context) => PuzzleCatalogCubit(
        repository: di.sl<PuzzleRepository>(),
        progress: di.sl<ProgressService>(),
      )..refresh(),
      child: const _MyAnimalsView(),
    );
  }
}

class _MyAnimalsView extends StatelessWidget {
  const _MyAnimalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: IllustratedBackground()),
          SafeArea(
            child: Column(
              children: <Widget>[
                const AppTopBar(
                  title: 'My Animals',
                  showSettings: false,
                ),
                Expanded(
                  child: BlocBuilder<PuzzleCatalogCubit, PuzzleCatalogState>(
                    builder: (BuildContext context, PuzzleCatalogState state) {
                      final List<PuzzleCatalogEntry> unlocked = state.entries
                          .where((PuzzleCatalogEntry e) => e.solved)
                          .toList();
                      if (unlocked.isEmpty) {
                        return _Empty(progress: state.solvedCount);
                      }
                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(AppTokens.space4),
                            child: Text(
                              'You have collected ${state.solvedCount} animals!',
                              textAlign: TextAlign.center,
                              style: AppTheme.glyphStyle(
                                20,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Expanded(child: _grid(context, state.entries)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, List<PuzzleCatalogEntry> entries) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth > 900
            ? 6
            : constraints.maxWidth > 640
                ? 5
                : constraints.maxWidth > 430
                    ? 4
                    : 3;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            0,
            AppTokens.space4,
            AppTokens.space6,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppTokens.space3,
            crossAxisSpacing: AppTokens.space3,
            childAspectRatio: 0.8,
          ),
          itemCount: entries.length,
          itemBuilder: (BuildContext context, int index) {
            final PuzzleCatalogEntry entry = entries[index];
            if (!entry.unlocked) {
              return const _EmptyTile();
            }
            return _CollectedAnimal(entry: entry);
          },
        );
      },
    );
  }
}

class _CollectedAnimal extends StatelessWidget {
  const _CollectedAnimal({required this.entry});

  final PuzzleCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: entry.animal.name,
      button: true,
      child: GestureDetector(
        onTap: () => _openFact(context, entry.animal),
        child: Column(
          children: <Widget>[
            Expanded(child: AnimalPicture(animal: entry.animal, size: 72)),
            Text(
              entry.animal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFact(BuildContext context, Animal animal) {
    final AudioService audio = di.sl<AudioService>();
    audio.speakText('${animal.name}. ${animal.fact}');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space5,
            0,
            AppTokens.space5,
            AppTokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimalPicture(animal: animal, size: 120),
              const SizedBox(height: AppTokens.space3),
              Text(
                animal.name,
                style: AppTheme.glyphStyle(26, color: AppColors.ink),
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                animal.fact,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: AppColors.outlineSoft, width: 1.5),
      ),
      child: const Center(
        child: Icon(Icons.lock_rounded, color: AppColors.locked, size: 30),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Text(
          'Solve puzzles to collect animals.\n'
          'You have $progress so far!',
          textAlign: TextAlign.center,
          style: AppTheme.glyphStyle(20, color: AppColors.ink),
        ),
      ),
    );
  }
}