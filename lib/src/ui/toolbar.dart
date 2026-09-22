import 'package:flutter/material.dart';

import '../controller/machine_controller.dart';
import '../programs/gallery.dart';
import '../theme.dart';

String withCommas(int n) {
  final s = n.abs().toString();
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
    sb.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}$sb';
}

class ConsoleToolbar extends StatelessWidget {
  final MachineController controller;

  const ConsoleToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final m = controller.machine;
    return Container(
      decoration: BoxDecoration(
        color: MixColors.panel,
        border: Border.all(color: MixColors.bezel),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          _Button(
            label: controller.running ? 'PAUSE' : 'RUN',
            glyph: controller.running ? '⏸' : '▶',
            accent: true,
            onTap: controller.canStep || controller.running
                ? controller.toggleRun
                : null,
          ),
          const SizedBox(width: 8),
          _Button(
            label: 'STEP',
            glyph: '⏭',
            onTap: controller.canStep && !controller.running
                ? controller.stepOnce
                : null,
          ),
          const SizedBox(width: 8),
          _Button(label: 'RESET', glyph: '↺', onTap: controller.reset),
          _divider(),
          const Text('SPEED', style: MixText.caption),
          SizedBox(
            width: 150,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: MixColors.amber,
                inactiveTrackColor: MixColors.bezel,
                thumbColor: MixColors.data,
                overlayColor: MixColors.amber.withValues(alpha: 0.1),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6.5),
              ),
              child: Slider(
                value: controller.speedKnob,
                onChanged: controller.setSpeed,
              ),
            ),
          ),
          SizedBox(
            width: 76,
            child: Text(controller.speedLabel,
                style: MixText.monoDim.copyWith(fontSize: 11)),
          ),
          _divider(),
          _ProgramPicker(controller: controller),
          const Spacer(),
          if (m.halted) ...[
            const _StatusChip(text: 'HALTED', color: MixColors.green),
            const SizedBox(width: 14),
          ] else if (controller.error != null) ...[
            const _StatusChip(text: 'ERROR', color: MixColors.lampRed),
            const SizedBox(width: 14),
          ],
          _Counter(value: '${withCommas(m.cycles)}u', caption: 'ELAPSED TIME'),
          const SizedBox(width: 18),
          _Counter(
              value: withCommas(m.instructions), caption: 'INSTRUCTIONS'),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: MixColors.bezel,
      );
}

class _Button extends StatelessWidget {
  final String label;
  final String glyph;
  final bool accent;
  final VoidCallback? onTap;

  const _Button({
    required this.label,
    required this.glyph,
    this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = !enabled
        ? MixColors.labelDim
        : accent
            ? MixColors.amber
            : MixColors.data;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: accent && enabled
              ? MixColors.amber.withValues(alpha: 0.14)
              : MixColors.bezelSoft,
          border: Border.all(
              color: accent && enabled
                  ? MixColors.amber.withValues(alpha: 0.55)
                  : MixColors.bezel),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(glyph, style: TextStyle(fontSize: 10, color: fg)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: fg)),
          ],
        ),
      ),
    );
  }
}

class _ProgramPicker extends StatelessWidget {
  final MachineController controller;

  const _ProgramPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: MixColors.panelDeep,
        border: Border.all(color: MixColors.bezel),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GalleryProgram>(
          value: controller.current,
          dropdownColor: MixColors.panel,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(fontSize: 12.5, color: MixColors.data),
          iconEnabledColor: MixColors.labelDim,
          items: [
            for (final p in gallery)
              DropdownMenuItem(
                value: p,
                child: Text(p.label,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (p) {
            if (p != null) controller.load(p);
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, letterSpacing: 1.2, color: color,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _Counter extends StatelessWidget {
  final String value;
  final String caption;

  const _Counter({required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontFamily: monoFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MixColors.amber)),
        Text(caption, style: MixText.caption.copyWith(fontSize: 8.5)),
      ],
    );
  }
}
