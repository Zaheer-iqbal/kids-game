import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/animal.dart';

/// Builds (and caches) the animal "stickers" fully in code: each emoji is
/// painted onto a soft pastel rounded canvas with [PictureRecorder] and
/// [TextPainter], turned into a [ui.Image] and — for jigsaws and sliding
/// puzzles — sliced into tiles. No image or font assets are shipped.
///
/// Everything uses `toImageSync`, so boards can be laid out synchronously; if
/// the platform cannot rasterise (e.g. a bare unit-test binding) the getters
/// return `null` and the widgets fall back to plain emoji text, so a puzzle is
/// never blocked.
class AnimalImages {
  AnimalImages._();

  static final AnimalImages instance = AnimalImages._();

  /// Base sticker resolution; divisible by 2, 3 and 4 so slices stay crisp.
  static const int baseSize = 384;

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

  /// The whole sticker for [animal].
  ui.Image? full(Animal animal) => _image('full:${animal.id}', () {
        return _record(
          Size.square(baseSize.toDouble()),
          (Canvas canvas) => paintSticker(
            canvas,
            Size.square(baseSize.toDouble()),
            animal.emoji,
            colorFor(animal.id),
          ),
        );
      });

  /// One tile of a [columns] x [rows] board, top-left to bottom-right.
  ui.Image? slice(Animal animal, int columns, int rows, int tile) {
    final int base = baseSize;
    final double tileW = base / columns;
    final double tileH = base / rows;
    final int col = tile % columns;
    final int row = tile ~/ columns;
    final Rect source = Rect.fromLTWH(col * tileW, row * tileH, tileW, tileH);

    return _image('slice:${animal.id}:${columns}x$rows:$tile', () {
      final ui.Image? fullImage = full(animal);
      if (fullImage == null) return null;
      return _record(Size(tileW, tileH), (Canvas canvas) {
        canvas.drawImageRect(
          fullImage,
          source,
          Rect.fromLTWH(0, 0, tileW, tileH),
          Paint()..filterQuality = FilterQuality.medium,
        );
      });
    });
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

  /// Paints an emoji glyph, transparent everywhere else. The pastel card is
  /// drawn by the widget, so a slice stays just a piece of the animal and can
  /// be tinted into a clean silhouette. Public so tests can render it too.
  static void paintSticker(Canvas canvas, Size size, String emoji, Color bg) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: size.width * 0.62,
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
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
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

/// A code-drawn animal sticker, optionally showing just one board tile.
///
/// Shows the rasterised sticker when available and falls back to plain emoji
/// text otherwise, so tests and first frames are never empty.
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
  });

  final Animal animal;
  final double size;
  final int? columns;
  final int? rows;
  final int? tile;
  final bool rounded;
  final bool showBackground;
  final Color? background;

  /// Renders the sticker (or one slice) as a single flat silhouette colour.
  final bool silhouette;

  bool get _isSlice => tile != null && columns != null && rows != null;

  @override
  Widget build(BuildContext context) {
    final ui.Image? image = _isSlice
        ? AnimalImages.instance.slice(animal, columns!, rows!, tile!)
        : AnimalImages.instance.full(animal);

    if (image == null) {
      return _fallback();
    }
    final Widget painted = CustomPaint(
      size: Size.square(size),
      painter: _StickerPainter(
        image: image,
        radius: rounded ? size * 0.16 : 0,
        paintBackground: showBackground && !silhouette,
        background: background ?? AnimalImages.colorFor(animal.id),
      ),
    );
    if (!silhouette) return painted;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppColors.silhouette,
        BlendMode.srcIn,
      ),
      child: painted,
    );
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
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: showBackground && !silhouette
            ? (background ?? AnimalImages.colorFor(animal.id))
            : null,
        borderRadius: rounded ? BorderRadius.circular(size * 0.16) : null,
      ),
      child: glyph,
    );
    if (!silhouette) return card;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppColors.silhouette,
        BlendMode.srcIn,
      ),
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
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        color ?? AppColors.silhouette,
        BlendMode.srcIn,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: size * 0.6,
              height: 1,
              fontFamilyFallback: const <String>[
                'Noto Color Emoji',
                'Apple Color Emoji',
                'Segoe UI Emoji',
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerPainter extends CustomPainter {
  const _StickerPainter({
    required this.image,
    required this.radius,
    required this.paintBackground,
    required this.background,
  });

  final ui.Image image;
  final double radius;
  final bool paintBackground;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect dest = Offset.zero & size;
    final RRect clip = RRect.fromRectAndRadius(dest, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(clip);
    if (paintBackground) {
      canvas.drawRect(dest, Paint()..color = background);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StickerPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.radius != radius ||
      oldDelegate.background != background;
}