import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';
import 'word_view.dart';

class RegisterPanel extends StatelessWidget {
  final MachineController controller;

  const RegisterPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final m = controller.machine;
    final changed = controller.changedRegs;
    return ConsolePanel(
      title: 'Registers',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _wordRow('rA', m.rA, 5, changed.contains('A')),
            const SizedBox(height: 6),
            _wordRow('rX', m.rX, 5, changed.contains('X')),
            const SizedBox(height: 6),
            _wordRow('rJ', m.rJ, 2, changed.contains('J')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 22,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 6; i++)
                  _indexReg('rI${i + 1}', m.rI[i],
                      changed.contains('I${i + 1}')),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: MixColors.bezelSoft),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('OVERFLOW', style: MixText.caption),
                const SizedBox(width: 10),
                Lamp(label: 'OV', lit: m.overflow, color: MixColors.lampRed),
                const SizedBox(width: 26),
                const Text('COMPARISON', style: MixText.caption),
                const SizedBox(width: 10),
                Lamp(label: 'L', lit: m.comparison == MixComparison.less),
                const SizedBox(width: 8),
                Lamp(label: 'E', lit: m.comparison == MixComparison.equal),
                const SizedBox(width: 8),
                Lamp(label: 'G', lit: m.comparison == MixComparison.greater),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wordRow(String name, MixWord w, int bytesShown, bool hot) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(name,
              style: MixText.monoDim.copyWith(
                  fontSize: 12,
                  color: hot ? MixColors.amber : MixColors.label)),
        ),
        const SizedBox(width: 6),
        WordView(
            word: w,
            bytesShown: bytesShown,
            accent: hot ? MixColors.amber : null),
        const Spacer(),
        Text('= ${w.value}',
            style: MixText.monoDim.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _indexReg(String name, MixWord w, bool hot) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name,
            style: MixText.monoDim.copyWith(
                fontSize: 11.5,
                color: hot ? MixColors.amber : MixColors.labelDim)),
        const SizedBox(width: 8),
        Text(
          '${w.sign < 0 ? '-' : '+'}${w.magnitude}',
          style: MixText.mono.copyWith(
              fontSize: 12,
              fontWeight: hot ? FontWeight.w700 : FontWeight.w400,
              color: hot ? MixColors.amber : MixColors.data),
        ),
      ],
    );
  }
}
