import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';

/// Bottom strip: line printer on greenbar paper, plus card units.
class DeviceStrip extends StatelessWidget {
  final MachineController controller;

  const DeviceStrip({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final m = controller.machine;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _PrinterPanel(printer: m.printer)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ConsolePanel(
            title: 'Card Units',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _deviceLine('READER · 16',
                    m.cardReader.remaining > 0
                        ? '${m.cardReader.remaining} card(s) waiting'
                        : 'hopper empty',
                    m.cardReader.remaining > 0),
                const SizedBox(height: 10),
                _deviceLine('PUNCH · 17',
                    m.cardPunch.cards.isNotEmpty
                        ? '${m.cardPunch.cards.length} card(s) punched'
                        : 'idle',
                    m.cardPunch.cards.isNotEmpty),
                const SizedBox(height: 10),
                _deviceLine('TAPES · 0–7', 'not mounted', false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _deviceLine(String name, String status, bool active) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? MixColors.green : MixColors.lampOff,
          ),
        ),
        const SizedBox(width: 8),
        Text(name, style: MixText.caption),
        const SizedBox(width: 10),
        Expanded(
          child: Text(status,
              overflow: TextOverflow.ellipsis,
              style: MixText.monoDim.copyWith(fontSize: 11)),
        ),
      ],
    );
  }
}

class _PrinterPanel extends StatefulWidget {
  final LinePrinter printer;

  const _PrinterPanel({required this.printer});

  @override
  State<_PrinterPanel> createState() => _PrinterPanelState();
}

class _PrinterPanelState extends State<_PrinterPanel> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.printer.lines;
    return ConsolePanel(
      title: 'Line Printer · Unit 18',
      trailing: Text(
        lines.isEmpty ? 'IDLE' : '${lines.length} LINE(S)',
        style: MixText.caption,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: MixColors.paper,
          borderRadius: BorderRadius.circular(3),
        ),
        clipBehavior: Clip.antiAlias,
        child: lines.isEmpty
            ? Center(
                child: Text('— no output —',
                    style: MixText.caption
                        .copyWith(color: MixColors.paperInk.withValues(alpha: 0.5))))
            : ListView.builder(
                controller: _scroll,
                reverse: true,
                itemCount: lines.length,
                itemExtent: 22,
                itemBuilder: (context, i) {
                  final index = lines.length - 1 - i;
                  final line = lines[index];
                  if (line == LinePrinter.pageBreak) {
                    return Container(
                      alignment: Alignment.center,
                      color: index.isEven
                          ? MixColors.paperBar
                          : MixColors.paper,
                      child: Text('· · · · · · · ·  TOP OF PAGE  · · · · · · · ·',
                          style: TextStyle(
                              fontFamily: monoFamily,
                              fontSize: 9,
                              color: MixColors.paperInk
                                  .withValues(alpha: 0.45))),
                    );
                  }
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color:
                        index.isEven ? MixColors.paperBar : MixColors.paper,
                    child: Text(
                      line,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: const TextStyle(
                          fontFamily: monoFamily,
                          fontSize: 11.5,
                          color: MixColors.paperInk),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
