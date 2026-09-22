import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../theme.dart';

/// A MIX word rendered as its sign box and byte boxes.
class WordView extends StatelessWidget {
  final MixWord word;

  /// How many (rightmost) bytes to show: 5 for full words, 2 for rJ.
  final int bytesShown;
  final Color? accent;

  const WordView({
    super.key,
    required this.word,
    this.bytesShown = 5,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      _cell(word.sign < 0 ? '-' : '+', dim: true),
      for (var k = 5 - bytesShown; k < 5; k++)
        _cell(word.bytes[k].toString().padLeft(2, '0')),
    ];
    return Row(mainAxisSize: MainAxisSize.min, children: cells);
  }

  Widget _cell(String text, {bool dim = false}) {
    return Container(
      width: 26,
      height: 22,
      margin: const EdgeInsets.only(right: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent != null ? accent!.withValues(alpha: 0.15) : MixColors.panelDeep,
        border: Border.all(
            color: accent?.withValues(alpha: 0.55) ?? MixColors.bezelSoft),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: monoFamily,
          fontSize: 11.5,
          color: dim ? MixColors.dataDim : MixColors.data,
        ),
      ),
    );
  }
}

/// A small console indicator lamp with a label under it.
class Lamp extends StatelessWidget {
  final String label;
  final bool lit;
  final Color color;

  const Lamp({
    super.key,
    required this.label,
    required this.lit,
    this.color = MixColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit ? color : MixColors.lampOff,
            border: Border.all(color: lit ? color : MixColors.bezel),
            boxShadow: lit
                ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 7)]
                : const [],
          ),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                fontFamily: monoFamily,
                fontSize: 9,
                color: MixColors.labelDim)),
      ],
    );
  }
}
