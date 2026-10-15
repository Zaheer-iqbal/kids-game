import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/features/puzzles/domain/entities/animal.dart';
import 'package:kids/features/puzzles/domain/entities/animal_puzzle.dart';
import 'package:kids/features/puzzles/presentation/widgets/animal_picture.dart';

Future<Uint8List> _bytes(ui.Image image) async {
  final ByteData? data =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

/// Draws a known, position-dependent pattern so any gap, overlap or shift in
/// the slicing shows up as a pixel difference.
void _paintPattern(Canvas canvas, int width, int height) {
  final Paint paint = Paint();
  for (int y = 0; y < height; y += 4) {
    for (int x = 0; x < width; x += 4) {
      paint.color = Color.fromARGB(
        255,
        (x * 2) % 256,
        (y * 3) % 256,
        ((x + y) * 5) % 256,
      );
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 4, 4),
        paint,
      );
    }
  }
}

ui.Image _imageFrom(Size size, void Function(Canvas canvas) draw) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  draw(canvas);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image =
      picture.toImageSync(size.width.round(), size.height.round());
  picture.dispose();
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimalImages.sliceRects', () {
    const List<List<int>> grids = <List<int>>[
      <int>[1, 1],
      <int>[2, 2],
      <int>[2, 3],
      <int>[3, 3],
      <int>[3, 4],
      <int>[4, 3],
    ];

    test('produces one rectangle per piece', () {
      for (final List<int> grid in grids) {
        final List<Rect> rects =
            AnimalImages.sliceRects(1024, 1024, grid[0], grid[1]);
        expect(rects.length, grid[0] * grid[1],
            reason: 'grid ${grid[0]}x${grid[1]}');
      }
    });

    test('areas sum to exactly the whole image (no gaps or overlaps)', () {
      for (final List<int> grid in grids) {
        final List<Rect> rects =
            AnimalImages.sliceRects(1024, 1024, grid[0], grid[1]);
        double area = 0;
        for (final Rect rect in rects) {
          area += rect.width * rect.height;
        }
        expect(area, 1024.0 * 1024.0, reason: 'grid ${grid[0]}x${grid[1]}');
      }
    });

    test('edges are whole pixels and span the full image', () {
      for (final List<int> grid in grids) {
        final List<Rect> rects =
            AnimalImages.sliceRects(1024, 1024, grid[0], grid[1]);
        for (final Rect rect in rects) {
          expect(rect.left, rect.left.roundToDouble());
          expect(rect.top, rect.top.roundToDouble());
          expect(rect.right, rect.right.roundToDouble());
          expect(rect.bottom, rect.bottom.roundToDouble());
        }
        expect(rects.map((Rect r) => r.left).reduce(_min), 0);
        expect(rects.map((Rect r) => r.top).reduce(_min), 0);
        expect(rects.map((Rect r) => r.right).reduce(_max), 1024);
        expect(rects.map((Rect r) => r.bottom).reduce(_max), 1024);
      }
    });

    test('neighbouring rectangles share exact edges', () {
      final List<Rect> rects = AnimalImages.sliceRects(1024, 1024, 3, 4);
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 3; col++) {
          final Rect cell = rects[row * 3 + col];
          if (col < 2) {
            expect(cell.right, rects[row * 3 + col + 1].left);
          }
          if (row < 3) {
            expect(cell.bottom, rects[(row + 1) * 3 + col].top);
          }
        }
      }
    });
  });

  group('pixel reassembly', () {
    for (final List<int> grid in const <List<int>>[
      <int>[2, 2],
      <int>[2, 3],
      <int>[3, 4],
    ]) {
      test('slicing ${grid[0]}x${grid[1]} then redrawing rebuilds the source',
          () async {
        const int side = 120;
        final ui.Image source = _imageFrom(
          Size(side.toDouble(), side.toDouble()),
          (Canvas canvas) => _paintPattern(canvas, side, side),
        );

        final List<Rect> rects = AnimalImages.sliceRects(side, side, grid[0], grid[1]);
        final ui.Image rebuilt = _imageFrom(
          Size(side.toDouble(), side.toDouble()),
          (Canvas canvas) {
            for (final Rect rect in rects) {
              canvas.drawImageRect(
                source,
                rect,
                rect,
                Paint()..filterQuality = FilterQuality.none,
              );
            }
          },
        );

        expect(await _bytes(rebuilt), await _bytes(source));
        source.dispose();
        rebuilt.dispose();
      });
    }
  });

  group('composed stickers', () {
    const Animal lion = Animal(
      id: 0,
      name: 'Lion',
      emoji: '🦁',
      sound: 'Roar!',
      fact: 'Lions live in prides.',
    );

    test('the full picture is a square canvas', () {
      final ui.Image? full = AnimalImages.instance.full(lion);
      expect(full, isNotNull);
      expect(full!.width, AnimalImages.canvas);
      expect(full.height, AnimalImages.canvas);
    });

    test('every slice matches its rect size for every grid', () {
      for (final List<int> grid in const <List<int>>[
        <int>[2, 2],
        <int>[2, 3],
        <int>[3, 3],
        <int>[3, 4],
      ]) {
        final List<Rect> rects =
            AnimalImages.sliceRects(AnimalImages.canvas, AnimalImages.canvas, grid[0], grid[1]);
        for (int tile = 0; tile < rects.length; tile++) {
          final ui.Image? slice =
              AnimalImages.instance.slice(lion, grid[0], grid[1], tile);
          expect(slice, isNotNull, reason: 'grid ${grid[0]}x${grid[1]} tile $tile');
          expect(slice!.width, rects[tile].width.round());
          expect(slice.height, rects[tile].height.round());
        }
      }
    });
  });

  group('PuzzleDifficulty ladder', () {
    test('piece counts map onto easy / medium / hard', () {
      expect(
        const AnimalPuzzle(
          index: 0,
          type: AnimalPuzzleType.jigsaw,
          columns: 2,
          rows: 2,
        ).difficulty,
        PuzzleDifficulty.easy,
      );
      expect(
        const AnimalPuzzle(
          index: 0,
          type: AnimalPuzzleType.jigsaw,
          columns: 2,
          rows: 3,
        ).difficulty,
        PuzzleDifficulty.medium,
      );
      expect(
        const AnimalPuzzle(
          index: 0,
          type: AnimalPuzzleType.jigsaw,
          columns: 3,
          rows: 3,
        ).difficulty,
        PuzzleDifficulty.medium,
      );
      expect(
        const AnimalPuzzle(
          index: 0,
          type: AnimalPuzzleType.jigsaw,
          columns: 3,
          rows: 4,
        ).difficulty,
        PuzzleDifficulty.hard,
      );
    });

    test('every generated level has a difficulty label', () {
      for (int i = 0; i < 100; i++) {
        final AnimalPuzzle puzzle = AnimalPuzzle.forIndex(i);
        expect(puzzle.difficulty.label, isNotEmpty);
      }
    });
  });
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;
