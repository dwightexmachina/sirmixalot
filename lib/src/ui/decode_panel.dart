import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';
import 'hover_card.dart';

/// Field-by-field breakdown of the next instruction: ± AA I F C, its
/// disassembly, the effective address computation, and the cycle cost.
class DecodePanel extends StatelessWidget {
  final MachineController controller;

  const DecodePanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final m = controller.machine;
    final Widget body;
    if (controller.error != null) {
      body = Text(controller.error!,
          style: MixText.mono.copyWith(color: MixColors.lampRed, height: 1.5));
    } else if (m.halted) {
      body = Text('Machine halted after ${withPlural(m.instructions)}.',
          style: MixText.monoDim.copyWith(height: 1.5));
    } else if (controller.program == null) {
      body = Text('No program loaded.', style: MixText.monoDim);
    } else {
      body = _decode(m);
    }
    return ConsolePanel(
      title: 'Current Instruction',
      trailing: controller.canStep
          ? Text('${m.pc}', style: MixText.caption)
          : null,
      child: SingleChildScrollView(child: body),
    );
  }

  static String withPlural(int n) =>
      '$n instruction${n == 1 ? '' : 's'}';

  Widget _decode(MixMachine m) {
    final word = m.memory[m.pc];
    final ins = Instruction(word);
    final usesIndex = ins.i >= 1 && ins.i <= 6;
    final effective =
        ins.aa + (usesIndex ? m.rI[ins.i - 1].value : 0);
    final cost = instructionCost(ins.c, ins.f);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _fieldCell(word.sign < 0 ? '-' : '+', 'SIGN', false),
            _fieldCell(
                '${word.bytes[0].toString().padLeft(2, '0')} ${word.bytes[1].toString().padLeft(2, '0')}',
                'A = ${ins.aa}',
                true,
                flex: 2),
            _fieldCell('${ins.i}', 'I', usesIndex),
            _fieldCell('${ins.f}', 'F (${ins.fieldL}:${ins.fieldR})', false),
            _fieldCell('${ins.c}', 'C', false, last: true),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: HoverCard(
            contentBuilder: (_) => InstructionTooltipCard(
              explanation:
                  explainInstruction(word, machine: m, address: m.pc),
            ),
            child: Text(disassemble(word),
                style: MixText.mono.copyWith(
                    fontSize: 14,
                    color: MixColors.amber,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor:
                        MixColors.amber.withValues(alpha: 0.5))),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          usesIndex
              ? 'M = ${ins.aa} + rI${ins.i} (${m.rI[ins.i - 1].value}) = $effective'
              : 'M = ${ins.aa}',
          style: MixText.monoDim.copyWith(fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('COST', style: MixText.caption),
            const SizedBox(width: 8),
            Text('${cost}u',
                style: MixText.mono.copyWith(
                    color: MixColors.amber, fontSize: 12.5)),
            const SizedBox(width: 20),
            Text('OPCODE', style: MixText.caption),
            const SizedBox(width: 8),
            Text('C = ${ins.c}',
                style: MixText.monoDim.copyWith(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _fieldCell(String value, String caption, bool highlight,
      {int flex = 1, bool last = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 44,
        margin: EdgeInsets.only(right: last ? 0 : 3),
        decoration: BoxDecoration(
          color: highlight ? MixColors.amberSoft : MixColors.panelDeep,
          border: Border.all(
              color: highlight
                  ? MixColors.amber.withValues(alpha: 0.55)
                  : MixColors.bezelSoft),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: MixText.mono.copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            Text(caption,
                overflow: TextOverflow.ellipsis,
                style: MixText.caption.copyWith(
                    fontSize: 8,
                    color: highlight
                        ? MixColors.amber
                        : MixColors.labelDim)),
          ],
        ),
      ),
    );
  }
}
