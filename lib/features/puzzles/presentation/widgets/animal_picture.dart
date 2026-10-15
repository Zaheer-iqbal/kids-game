import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/animal.dart';

/// Builds (and caches) the animal "stickers" fully in code: each emoji is
/// painted, fit-to-contain and centred, onto a fixed square canvas with
/// [PictureRecorder] and [TextPainter], turned into a [ui.Image] and — for
/// jigsaws and sliding puzzles — sliced into an exact partition of that image.
/// No image or font assets are shipped.
///
/// Everything uses `toImageSync`, so boards can be laid out synchronously; if
/// the platform cannot rasterise (e.g. a bare unit-test binding) the getters
/// return `null` and the widgets fall back to plain emoji text, so a puzzle is
/// never blocked.
class AnimalImages {
  AnimalImages._();

  static final AnimalImages instance = AnimalImages._();

  /// Fixed square composition size. Divisible by 2 and 4 (and near-evenly by
  /// 3), so slices stay crisp on every supported grid.
  static const int canvas = 1024;

  /// Fraction of the canvas the glyph fills, leaving a comfortable margin so
  /// no part of the animal is ever clipped at the edges.
  static const double glyphFill = 0.84;

  static const List<Color> pastels = <Color>[
    Color(0xFFDCEBFF),
    Color(0xFFFFE7D6),
    Color(0xFFDFF6E4),
    Color(0xFFFFE1EC),
    Color(0xFFEDE4FF),
    Color(0xFFFFF3C9),
    Color(0xFFD9F2F6),
  ];

  final Map<String, ui.Image> _cache = <String, ui.Image>{};
  bool _rasterisationBroken = false;

  static Color colorFor(int animalId) => pastels[animalId % pastels.length];

  /// The whole picture for [animal]: a pastel card with the centred animal.
  /// This is what a finished puzzle looks like, so every slice below is a
  /// literal crop of this one image.
  ui.Image? full(Animal animal) => _image('full:${animal.id}', () {
        final Size size = Size.square(AnimalImages.canvas.toDouble());
        return _record(
          size,
          (Canvas canvas) => paintSticker(
            canvas,
            size,
            animal.emoji,
            colorFor(animal.id),
          ),
        );
      });

  /// The animal glyph alone on a transparent canvas. Used to draw the faint
  /// silhouette guide behind a jigsaw board, aligned exactly with the pieces.
  ui.Image? glyph(Animal animal) => _image('glyph:${animal.id}', () {
        final Size size = Size.square(AnimalImages.canvas.toDouble());
        return _record(
          size,
          (Canvas canvas) => paintCenteredGlyph(canvas, size, animal.emoji),
        );
      });

  /// One tile of a [columns] x [rows] board, top-left to bottom-right.
  ui.Image? slice(Animal animal, int columns, int rows, int tile) {
    final List<Rect> rects = sliceRects(canvas, canvas, columns, rows);
    if (tile < 0 || tile >= rects.length) return null;
    final Rect source = rects[tile];

    return _image('slice:${animal.id}:${columns}x$rows:$tile', () {
      final ui.Image? sheet = full(animal);
      if (sheet == null) return null;
      return _record(source.size, (Canvas canvas) {
        canvas.drawImageRect(
          sheet,
          source,
          Offset.zero & source.size,
          Paint()..filterQuality = FilterQuality.medium,
        );
      });
    });
  }

  /// The exact source rectangles for a [columns] x [rows] partition of a
  /// [width] x [height] image, in row-major order.
  ///
  /// Edges are rounded to whole pixels and shared between neighbours, so the
  /// rectangles tile the image **exactly**: their union is the full image and
  /// no two of them overlap. This is the property the puzzle board relies on
  /// to rebuild one picture from its pieces.
  static List<Rect> sliceRects(int width, int height, int columns, int rows) {
    final List<int> xs = _edges(width, columns);
    final List<int> ys = _edges(height, rows);
    final List<Rect> rects = <Rect>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        rects.add(
          Rect.fromLTRB(
            xs[col].toDouble(),
            ys[row].toDouble(),
            xs[col + 1].toDouble(),
            ys[row + 1].toDouble(),
          ),
        );
      }
    }
    return rects;
  }

  /// Integer pixel edges for splitting [length] into [segments] parts. The
  /// first is always 0 and the last always [length], so the parts add up.
  static List<int> _edges(int length, int segments) {
    final List<int> edges = <int>[0];
    for (int i = 1; i < segments; i++) {
      edges.add((length * i / segments).round());
    }
    edges.add(length);
    return edges;
  }

  ui.Image? _image(String key, ui.Image? Function() build) {
    if (_rasterisationBroken) return null;
    final ui.Image? cached = _cache[key];
    if (cached != null) return cached;
    final ui.Image? made = build();
    if (made == null) {
      _rasterisationBroken = true;
      return null;
    }
    // Keep the cache bounded; the sticker images are small and reused heavily.
    if (_cache.length > 240) _cache.clear();
    _cache[key] = made;
    return made;
  }

  ui.Image? _record(Size size, void Function(Canvas canvas) draw) {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      draw(canvas);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = picture.toImageSync(
        size.width.round(),
        size.height.round(),
      );
      picture.dispose();
      return image;
    } catch (_) {
      return null;
    }
  }

  /// Paints the finished picture: a flat [background] with the emoji scaled to
  /// fit and centred exactly on top. Public so tests can render it too.
  static void paintSticker(Canvas canvas, Size size, String emoji, Color background) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    paintCenteredGlyph(canvas, size, emoji);
  }

  /// Draws [emoji] scaled with `BoxFit.contain` (plus a small margin) and
  /// centred exactly inside [size]. The glyph is measured first, so the whole
  /// animal always lands square in the middle no matter how the font reports
  /// its line box.
  static void paintCenteredGlyph(Canvas canvas, Size size, String emoji) {
    final TextPainter painter = _emojiPainter(emoji, size.width * 0.9);
    final double width = painter.width;
    final double height = painter.height;
    if (width <= 0 || height <= 0) return;

    final double scale = math.min(
      size.width * glyphFill / width,
      size.height * glyphFill / height,
    );
    final double dx = (size.width - width * scale) / 2;
    final double dy = (size.height - height * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// A flat single-colour silhouette of the animal, drawn with the same fit
  /// and centring as [paintSticker], so it lines up with the puzzle pieces.
  static void paintGlyphSilhouette(
    Canvas canvas,
    Size size,
    String emoji,
    Color color,
  ) {
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
    paintCenteredGlyph(canvas, size, emoji);
    canvas.restore();
  }

  static TextPainter _emojiPainter(String emoji, double fontSize) {
    return TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.0,
          fontFamilyFallback: const <String>[
            'Noto Color Emoji',
            'Apple Color Emoji',
            'Segoe UI Emoji',
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  @visibleForTesting
  void clear() {
    for (final ui.Image image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _rasterisationBroken = false;
  }
}

/// A code-drawn animal sticker: either the whole picture, a single puzzle
/// tile, or a flat silhouette. Falls back to plain emoji text when the
/// platform cannot rasterise, so tests and first frames are never empty.
class AnimalPicture extends StatelessWidget {
  const AnimalPicture({
    super.key,
    required this.animal,
    required this.size,
    this.columns,
    this.rows,
    this.tile,
    this.rounded = true,
    this.showBackground = true,
    this.background,
    this.silhouette = false,
    this.seamless = false,
  });

  final Animal animal;

  /// Side length for the square sticker. Ignored when [seamless] is true, in
  /// which case the picture fills whatever space it is given.
  final double size;

  final int? columns;
  final int? rows;
  final int? tile;
  final bool rounded;
  final bool showBackground;
  final Color? background;

  /// Renders the sticker (or one slice) as a single flat silhouette colour.
  final bool silhouette;

  /// Draws the tile edge to edge with no rounding or inset, so neighbouring
  /// tiles join seamlessly into one picture on a board.
  final bool seamless;

  bool get _isSlice => tile != null && columns != null && rows != null;

  @override
  Widget build(BuildContext context) {
    final ui.Image? image = _isSlice
        ? AnimalImages.instance.slice(animal, columns!, rows!, tile!)
        : AnimalImages.instance.full(animal);

    if (image == null) return _fallback();

    final double radius = seamless || !rounded ? 0 : size * 0.16;
    final Widget painted = CustomPaint(
      size: seamless ? Size.zero : Size.square(size),
      painter: _StickerPainter(
        image: image,
        radius: radius,
        paintBackground: !seamless && showBackground && !silhouette,
        background: background ?? AnimalImages.colorFor(animal.id),
        silhouetteColor: silhouette ? AppColors.silhouette : null,
      ),
      child: seamless ? const SizedBox.expand() : null,
    );
    return painted;
  }

  Widget _fallback() {
    final Widget glyph = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          animal.emoji,
          style: TextStyle(fontSize: size * 0.6, height: 1),
          textAlign: TextAlign.center,
        ),
      ),
    );
    final Widget card = Container(
      width: seamless ? null : size,
      height: seamless ? null : size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: showBackground && !silhouette
            ? (background ?? AnimalImages.colorFor(animal.id))
            : null,
        borderRadius: !seamless && rounded
            ? BorderRadius.circular(size * 0.16)
            : null,
      ),
      child: glyph,
    );
    if (!silhouette) return card;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(AppColors.silhouette, BlendMode.srcIn),
      child: card,
    );
  }
}

/// A flat single-colour silhouette of an animal, used as the jigsaw target
/// shadow and on shadow-match levels. Keeping it glyph-only (no card) means
/// only the animal shape is tinted, exactly like a real puzzle shadow.
class AnimalSilhouette extends StatelessWidget {
  const AnimalSilhouette({
    super.key,
    required this.emoji,
    required this.size,
    this.color,
  });

  final String emoji;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GlyphSilhouettePainter(
        emoji: emoji,
        color: color ?? AppColors.silhouette,
      ),
    );
  }
}

class _GlyphSilhouettePainter extends CustomPainter {
  const _GlyphSilhouettePainter({required this.emoji, required this.color});

  final String emoji;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    AnimalImages.paintGlyphSilhouette(canvas, size, emoji, color);
  }

  @override
  bool shouldRepaint(_GlyphSilhouettePainter oldDelegate) =>
      oldDelegate.emoji != emoji || oldDelegate.color != color;
}

class _StickerPainter extends CustomPainter {
  const _StickerPainter({
    required this.image,
    required this.radius,
    required this.paintBackground,
    required this.background,
    this.silhouetteColor,
  });

  final ui.Image image;
  final double radius;
  final bool paintBackground;
  final Color background;
  final Color? silhouetteColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect dest = Offset.zero & size;
    final RRect clip = RRect.fromRectAndRadius(dest, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(clip);
    if (paintBackground) {
      canvas.drawRect(dest, Paint()..color = background);
    }
    final Paint paint = Paint()..filterQuality = FilterQuality.medium;
    if (silhouetteColor != null) {
      paint.colorFilter = ColorFilter.mode(silhouetteColor!, BlendMode.srcIn);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dest,
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StickerPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.radius != radius ||
      oldDelegate.background != background ||
      oldDelegate.paintBackground != paintBackground ||
      oldDelegate.silhouetteColor != silhouetteColor;
}
