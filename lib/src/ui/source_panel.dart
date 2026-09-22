import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../controller/machine_controller.dart';
import '../theme.dart';
import 'hover_card.dart';

/// MIXAL listing with assembled addresses in the gutter and the next
/// instruction highlighted. Hovering a line explains it: instructions and
/// data reuse the memory-panel cards; EQU/ORIG/END get a directive card.
///
/// The source view is deliberately static — it explains what the program
/// *says*, so instruction cards carry no live "right now" prediction (that
/// lives in the Memory and Current Instruction panels).
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
            final hover = _hoverContent(text, addr, isComment);

            final lineText = Text(
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
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                decoration:
                    hover != null ? TextDecoration.underline : null,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: (isCurrent
                        ? MixColors.amber
                        : MixColors.labelDim)
                    .withValues(alpha: 0.45),
              ),
            );

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
                        color:
                            isCurrent ? MixColors.amber : MixColors.labelDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: hover == null
                          ? lineText
                          : HoverCard(
                              contentBuilder: (_) => hover,
                              child: lineText,
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

  /// The tooltip widget for a source line, or null if it has no explanation
  /// (comments, blank lines, unrecognized directives).
  Widget? _hoverContent(String text, int? addr, bool isComment) {
    if (isComment || text.trim().isEmpty) return null;
    final program = controller.program;
    if (program == null) return null;

    if (addr != null) {
      final word = program.words[addr];
      if (word == null) return null;
      // Static: explain the originally-assembled word, no machine state.
      return program.dataAddresses.contains(addr)
          ? DataTooltipCard(word: word)
          : InstructionTooltipCard(explanation: explainInstruction(word));
    }

    // No address: a word-less directive (EQU/ORIG/END).
    final parsed = _parseLine(text);
    final directive = explainDirective(
      parsed.op,
      label: parsed.label,
      operand: parsed.operand,
      symbols: program.symbols,
      start: program.start,
    );
    return directive == null
        ? null
        : DirectiveTooltipCard(explanation: directive);
  }

  /// Splits a MIXAL line into optional label, operation, and operand,
  /// following the assembler's fixed-order fields.
  ({String? label, String op, String operand}) _parseLine(String text) {
    bool isSpace(String c) => c == ' ' || c == '\t';
    var p = 0;
    String? label;
    if (text.isNotEmpty && !isSpace(text[0])) {
      var e = 0;
      while (e < text.length && !isSpace(text[e])) {
        e++;
      }
      label = text.substring(0, e);
      p = e;
    }
    String next() {
      while (p < text.length && isSpace(text[p])) {
        p++;
      }
      var e = p;
      while (e < text.length && !isSpace(text[e])) {
        e++;
      }
      final tok = text.substring(p, e);
      p = e;
      return tok;
    }

    final op = next();
    final operand = next();
    return (label: label, op: op, operand: operand);
  }
}
