import 'package:flutter/material.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';

/// A bar chart of a memory region (one bar per word, height ∝ value), for
/// watching sorts run. Cells touched by the last step flash: blue when read,
/// green when written.
class ArrayView extends StatelessWidget {
  final MachineController controller;
  final int base;
  final int length;

  const ArrayView({
    super.key,
    required this.controller,
    required this.base,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    final m = controller.machine;
    final reads = controller.lastStep?.memReads.toSet() ?? const <int>{};
    final writes = controller.lastStep?.memWrites.toSet() ?? const <int>{};

    var maxVal = 1;
    for (var k = 0; k < length; k++) {
      final v = m.memory[base + k].value;
      if (v > maxVal) maxVal = v;
    }

    return ConsolePanel(
      title: 'Array',
      trailing: Text('$length words @ $base', style: MixText.caption),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var k = 0; k < length; k++)
            Expanded(
              child: _Bar(
                value: m.memory[base + k].value,
                fraction: m.memory[base + k].value / maxVal,
                color: writes.contains(base + k)
                    ? MixColors.green
                    : (reads.contains(base + k)
                        ? MixColors.blue
                        : MixColors.amber),
                emphatic:
                    writes.contains(base + k) || reads.contains(base + k),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final double fraction;
  final Color color;
  final bool emphatic;

  const _Bar({
    required this.value,
    required this.fraction,
    required this.color,
    required this.emphatic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: TextStyle(
              fontFamily: monoFamily,
              fontSize: 8.5,
              color: emphatic ? color : MixColors.labelDim,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: FractionallySizedBox(
              heightFactor: fraction.clamp(0.02, 1.0),
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: emphatic ? 0.9 : 0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(2)),
                  border: Border.all(
                      color: color.withValues(alpha: emphatic ? 1 : 0.6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
