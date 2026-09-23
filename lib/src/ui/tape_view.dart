import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';

/// Shows the magnetic tape units as rows of block values with a read/write
/// head marker, so external (tape) sorts can be watched. Each block shows its
/// first word; the head position is highlighted.
class TapeView extends StatelessWidget {
  final MachineController controller;
  final int tapeCount;

  const TapeView({super.key, required this.controller, this.tapeCount = 4});

  @override
  Widget build(BuildContext context) {
    final m = controller.machine;
    return ConsolePanel(
      title: 'Tape Units',
      trailing: const Text('◀ HEAD', style: MixText.caption),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var n = 0; n < tapeCount; n++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TapeRow(
                  index: n,
                  blocks: m.tape(n).blocks,
                  head: m.tape(n).position,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TapeRow extends StatelessWidget {
  final int index;
  final List<List<MixWord>> blocks;
  final int head;

  const _TapeRow({
    required this.index,
    required this.blocks,
    required this.head,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text('TAPE $index',
              style: MixText.caption.copyWith(color: MixColors.label)),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var b = 0; b < blocks.length; b++) _cell(b),
                if (head >= blocks.length) _headOnlyCell(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(int b) {
    final atHead = b == head;
    final value = blocks[b].isEmpty ? 0 : blocks[b][0].value;
    return Container(
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const BoxConstraints(minWidth: 22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: atHead ? MixColors.amberSoft : MixColors.panelDeep,
        border: Border.all(
            color: atHead ? MixColors.amber : MixColors.bezelSoft),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text('$value',
          style: MixText.monoDim.copyWith(
              fontSize: 10.5,
              color: atHead ? MixColors.amber : MixColors.data)),
    );
  }

  Widget _headOnlyCell() {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      width: 22,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: MixColors.amber),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text('▸',
          style: TextStyle(fontSize: 10, color: MixColors.amber)),
    );
  }
}
