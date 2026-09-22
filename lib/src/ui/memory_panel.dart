import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';
import 'word_view.dart';

/// All 4000 words, virtualized, with read/write/PC highlighting and an
/// optional follow-the-program-counter mode.
class MemoryPanel extends StatefulWidget {
  final MachineController controller;

  const MemoryPanel({super.key, required this.controller});

  @override
  State<MemoryPanel> createState() => _MemoryPanelState();
}

class _MemoryPanelState extends State<MemoryPanel> {
  static const double _rowExtent = 26;
  final _scroll = ScrollController();
  bool _followPc = true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final m = c.machine;
    final reads = c.lastStep?.memReads.toSet() ?? const <int>{};
    final writes = c.lastStep?.memWrites.toSet() ?? const <int>{};
    final pc = m.pc;

    if (_followPc && c.program != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible(pc));
    }

    return ConsolePanel(
      title: 'Memory',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('FOLLOW PC', style: MixText.caption),
          SizedBox(
            height: 22,
            child: Switch(
              value: _followPc,
              onChanged: (v) => setState(() => _followPc = v),
              activeThumbColor: MixColors.amber,
              activeTrackColor: MixColors.amberSoft,
              inactiveThumbColor: MixColors.labelDim,
              inactiveTrackColor: MixColors.panelDeep,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: MixMachine.memorySize,
              itemExtent: _rowExtent,
              itemBuilder: (context, addr) {
                final word = m.memory[addr];
                Color? accent;
                Color? rowColor;
                if (addr == pc && !m.halted) {
                  accent = MixColors.amber;
                  rowColor = MixColors.amberSoft;
                } else if (writes.contains(addr)) {
                  accent = MixColors.green;
                  rowColor = MixColors.greenSoft;
                } else if (reads.contains(addr)) {
                  accent = MixColors.blue;
                  rowColor = MixColors.blueSoft;
                }
                final program = c.program;
                final isCode = program != null &&
                    program.words.containsKey(addr) &&
                    !program.dataAddresses.contains(addr);
                return Container(
                  decoration: rowColor != null
                      ? BoxDecoration(
                          color: rowColor,
                          borderRadius: BorderRadius.circular(3))
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          addr.toString().padLeft(4, '0'),
                          style: MixText.monoDim.copyWith(
                            fontSize: 11.5,
                            color: accent ?? MixColors.label,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      WordView(word: word, accent: accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isCode ? disassemble(word) : '= ${word.value}',
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: MixText.monoDim.copyWith(
                            fontSize: 11.5,
                            color: accent ?? MixColors.labelDim,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              _LegendKey(color: MixColors.amber, text: 'EXECUTING (PC)'),
              SizedBox(width: 16),
              _LegendKey(color: MixColors.blue, text: 'READ'),
              SizedBox(width: 16),
              _LegendKey(color: MixColors.green, text: 'WRITTEN'),
            ],
          ),
        ],
      ),
    );
  }

  void _ensureVisible(int addr, [int attempt = 0]) {
    if (!_scroll.hasClients) {
      // First frame: the list may not be attached yet — try again next frame.
      if (attempt < 3 && mounted) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _ensureVisible(addr, attempt + 1));
      }
      return;
    }
    final pos = _scroll.position;
    final target = addr * _rowExtent;
    final top = pos.pixels;
    final bottom = top + pos.viewportDimension - _rowExtent;
    if (target >= top && target <= bottom) return;
    final want = (target - pos.viewportDimension / 3)
        .clamp(0.0, pos.maxScrollExtent);
    _scroll.jumpTo(want);
  }
}

class _LegendKey extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendKey({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: MixText.caption.copyWith(fontSize: 9)),
      ],
    );
  }
}
