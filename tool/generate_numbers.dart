// Generates assets/data/numbers.json with entries for 1..100, each carrying
// the number, its word form, a fun icon key and a color.
//
// Run from the project root: dart run tool/generate_numbers.dart
import 'dart:convert';
import 'dart:io';

const List<String> _iconKeys = <String>[
  'star_rounded',
  'favorite',
  'pets',
  'eco',
  'cake',
  'rocket_launch',
  'toys',
  'sports_esports',
  'emoji_emotions',
  'music_note',
  'local_cafe',
  'icecream',
  'sunny',
  'ac_unit',
  'water_drop',
  'forest',
];

const List<String> _palette = <String>[
  '#FFB199', '#FF9E7D', '#FF8960', '#F26D6D',
  '#FF7594', '#F778B9', '#E28FE0', '#B993F0',
  '#8F95F0', '#5FA8E6', '#70C1E8', '#6FC8C9',
  '#78D6B6', '#8FD694', '#92D177', '#B8CC6B',
  '#E0C868', '#FFC15C', '#FFA94D', '#FF9A3B',
  '#F08A5B', '#E5A16F', '#D2A77B', '#C9B79C',
  '#AFB2D6', '#B39DD6',
];

const List<String> _ones = <String>[
  '', 'One', 'Two', 'Three', 'Four', 'Five',
  'Six', 'Seven', 'Eight', 'Nine', 'Ten',
  'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
  'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
];

const List<String> _tens = <String>[
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
  'Sixty', 'Seventy', 'Eighty', 'Ninety',
];

String _words(int n) {
  if (n < 20) return _ones[n];
  if (n < 100) {
    final String ten = _tens[n ~/ 10];
    final String one = _ones[n % 10];
    return one.isEmpty ? ten : '$ten $one';
  }
  if (n == 100) return 'One Hundred';
  return '$n';
}

void main() {
  final List<Map<String, Object>> entries = <Map<String, Object>>[];
  for (int n = 1; n <= 100; n++) {
    entries.add(<String, Object>{
      'number': n,
      'word': _words(n),
      'icon': _iconKeys[(n - 1) % _iconKeys.length],
      'color': _palette[(n - 1) % _palette.length],
    });
  }

  final File out = File('assets/data/numbers.json');
  out.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(entries),
  );
  stdout.writeln('Wrote ${entries.length} numbers to ${out.path}');
}