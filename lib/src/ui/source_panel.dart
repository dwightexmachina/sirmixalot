import 'package:flutter/material.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';

/// MIXAL listing with assembled addresses in the gutter and the next
/// instruction highlighted.
class SourcePanel extends StatelessWidget {
  final MachineController controller;

  const SourcePanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final currentLine = controller.currentSourceLine;
    return ConsolePanel(
      title: 'MIXAL Source',
      trailing: Text(controller.current.label,
          style: MixText.caption, overflow: TextOverflow.ellipsis),
      padding: const EdgeInsets.fromLTRB(10, 12, 6, 10),
      child: ScrollConfiguration(
        behavior:
            ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          itemCount: controller.sourceLines.length,
          itemExtent: 21,
          itemBuilder: (context, i) {
            final lineNo = i + 1;
            final text = controller.sourceLines[i];
            final addr = controller.addressForLine[lineNo];
            final isCurrent = lineNo == currentLine;
            final isComment = text.startsWith('*');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: isCurrent
                  ? BoxDecoration(
                      color: MixColors.amberSoft,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: MixColors.amber.withValues(alpha: 0.4)),
                    )
                  : null,
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      addr?.toString() ?? '',
                      textAlign: TextAlign.right,
                      style: MixText.monoDim.copyWith(
                        fontSize: 11,
                        color: isCurrent
                            ? MixColors.amber
                            : MixColors.labelDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: MixText.mono.copyWith(
                        fontSize: 12,
                        color: isComment
                            ? MixColors.labelDim
                            : isCurrent
                                ? MixColors.amber
                                : MixColors.data,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
