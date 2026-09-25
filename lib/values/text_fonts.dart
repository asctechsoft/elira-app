import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/data_models/text_layer.dart';

/// The fonts offered for text layers. Ids are persisted in the edit stack, so
/// they are API — a [label] can be renamed freely, an id cannot.
class TextFont {
  const TextFont({required this.id, required this.label, required this.sample});

  final String id;
  final String label;

  /// Two letters shown in the picker, set in the font itself.
  final String sample;

  TextStyle style({required double fontSize, required Color color}) {
    final base = TextStyle(
      fontSize: fontSize,
      color: color,
      height: 1.15,
      // Photos are busy; without a shadow white text vanishes over a
      // highlight and black text vanishes over a shadow.
      shadows: const [
        Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1)),
      ],
    );
    if (!TextFonts.allowDownloadableFonts) return _fallback(base);
    return base.merge(_family[id] ??= _googleFamily());
  }

  /// Size- and colour-free family style, resolved once per font. Text layers
  /// restyle on every drag and size tick; going through GoogleFonts each time
  /// redoes its lookup and style construction for nothing.
  static final Map<String, TextStyle> _family = {};

  TextStyle _googleFamily() => switch (id) {
        'serif' => GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        'display' => GoogleFonts.bebasNeue(letterSpacing: 1.5),
        'script' => GoogleFonts.caveat(fontWeight: FontWeight.w700),
        'mono' => GoogleFonts.robotoMono(fontWeight: FontWeight.w600),
        _ => GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      };

  /// Platform fonts only. Still visibly different from each other, so the
  /// picker does not collapse into five identical swatches.
  TextStyle _fallback(TextStyle base) => switch (id) {
        'serif' => base.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w700),
        'display' =>
          base.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        'script' => base.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
        'mono' => base.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600),
        _ => base.copyWith(fontWeight: FontWeight.w800),
      };
}

class TextFonts {
  const TextFonts._();

  /// The five families are fetched from Google Fonts at runtime, so the first
  /// use on a device with no network falls back to a platform font — and the
  /// exported caption would then not match what the editor showed.
  ///
  /// Setting this false skips the network entirely and draws with platform
  /// fonts, which is what tests do so their output is deterministic. The real
  /// fix is to bundle the .ttf files as assets; until then this is the switch
  /// that makes the behaviour a choice rather than a surprise.
  static bool allowDownloadableFonts = true;

  static const List<TextFont> all = [
    TextFont(id: TextLayer.defaultFontId, label: 'Sans', sample: 'Aa'),
    TextFont(id: 'serif', label: 'Serif', sample: 'Bb'),
    TextFont(id: 'display', label: 'Display', sample: 'Cc'),
    TextFont(id: 'script', label: 'Script', sample: 'Dd'),
    TextFont(id: 'mono', label: 'Mono', sample: 'Ee'),
  ];

  /// An unknown id resolves to the default rather than throwing, so a project
  /// saved by a newer build still opens.
  static TextFont byId(String id) =>
      all.firstWhere((f) => f.id == id, orElse: () => all.first);

  /// The palette offered for text. White and black first: those are the two
  /// that actually work on most photos.
  static const List<int> colors = [
    0xFFFFFFFF,
    0xFF111827,
    0xFF2B7EFB,
    0xFF7B4FDB,
    0xFFEF4444,
    0xFFF59E0B,
    0xFF22C55E,
    0xFFEC4899,
  ];
}

TextAlign textAlignOf(TextLayerAlign align) => switch (align) {
      TextLayerAlign.left => TextAlign.left,
      TextLayerAlign.center => TextAlign.center,
      TextLayerAlign.right => TextAlign.right,
    };
