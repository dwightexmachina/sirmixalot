import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../theme.dart';

/// Shows [contentBuilder] in an overlay card after hovering [child] for
/// [delay]. The card flips above/below and shifts left as needed to stay
/// on screen.
class HoverCard extends StatefulWidget {
  final Widget child;
  final WidgetBuilder contentBuilder;
  final Duration delay;
  final double width;

  const HoverCard({
    super.key,
    required this.child,
    required this.contentBuilder,
    this.delay = const Duration(milliseconds: 400),
    this.width = 392,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  final _link = LayerLink();
  OverlayEntry? _entry;
  Timer? _timer;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  void _schedule(PointerEvent _) {
    _timer?.cancel();
    _timer = Timer(widget.delay, _show);
  }

  void _show() {
    if (!mounted || _entry != null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    final showAbove = origin.dy > screen.height * 0.62;
    var dx = 0.0;
    final overflowRight = origin.dx + widget.width - (screen.width - 12);
    if (overflowRight > 0) dx = -overflowRight;

    _entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        width: widget.width,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor:
              showAbove ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor:
              showAbove ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(dx, showAbove ? -6 : 6),
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: widget.contentBuilder(overlayContext),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hide([PointerEvent? _]) {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        onEnter: _schedule,
        onExit: _hide,
        child: widget.child,
      ),
    );
  }
}

/// Shared card chrome for tooltips.
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10151C),
        border: Border.all(color: MixColors.amber.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 34, offset: Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}

/// The instruction tooltip: mnemonic + book name, decoded fields, an
/// explanatory paragraph, an optional live prediction, and metadata chips.
class InstructionTooltipCard extends StatelessWidget {
  final InstructionExplanation explanation;

  const InstructionTooltipCard({super.key, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final e = explanation;
    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(e.mnemonic,
                  style: const TextStyle(
                      fontFamily: monoFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MixColors.amber)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('“${e.name}”',
                    style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: MixColors.dataDim)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(e.fields,
              style: const TextStyle(
                  fontFamily: monoFamily,
                  fontSize: 10.5,
                  color: MixColors.labelDim)),
          const SizedBox(height: 9),
          Text(e.body,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.6, color: MixColors.data)),
          if (e.rightNow != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: MixColors.panelDeep,
                border: Border(
                  left: BorderSide(color: MixColors.blue, width: 3),
                ),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(
                      text: 'Right now: ',
                      style: TextStyle(
                          color: MixColors.blue, fontWeight: FontWeight.w600)),
                  TextSpan(text: e.rightNow),
                ]),
                style: const TextStyle(
                    fontSize: 12, height: 1.55, color: MixColors.dataDim),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [for (final chip in e.chips) _chip(chip)],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MixColors.bezelSoft,
        border: Border.all(color: MixColors.bezel),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.0,
              color: MixColors.label)),
    );
  }
}

/// Tooltip for data words: the value as decimal, characters, and how it
/// would decode if executed.
class DataTooltipCard extends StatelessWidget {
  final MixWord word;

  const DataTooltipCard({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final chars = word.bytes.map(mixCodeChar).join();
    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DATA WORD',
              style: MixText.caption.copyWith(color: MixColors.label)),
          const SizedBox(height: 8),
          _row('decimal', '${word.value}'),
          _row('characters', '"$chars"'),
          _row('as instruction', disassemble(word)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 105,
            child: Text(label.toUpperCase(),
                style: MixText.caption.copyWith(fontSize: 9)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontFamily: monoFamily,
                    fontSize: 12,
                    color: MixColors.data)),
          ),
        ],
      ),
    );
  }
}
