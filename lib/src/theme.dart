import 'package:flutter/material.dart';

/// The console palette from the design mock: dark slate panels, engraved
/// labels, amber for execution/writes, blue for reads, greenbar paper.
abstract class MixColors {
  static const ground = Color(0xFF14181F);
  static const panel = Color(0xFF1D242E);
  static const panelDeep = Color(0xFF171D26);
  static const bezel = Color(0xFF2E3947);
  static const bezelSoft = Color(0xFF263040);
  static const label = Color(0xFF8394A7);
  static const labelDim = Color(0xFF5C6B7D);
  static const data = Color(0xFFDCE4EE);
  static const dataDim = Color(0xFF9FADBD);
  static const amber = Color(0xFFE5A13C);
  static const amberSoft = Color(0x26E5A13C);
  static const blue = Color(0xFF62A4DE);
  static const blueSoft = Color(0x2662A4DE);
  static const green = Color(0xFF7FC97A);
  static const greenSoft = Color(0x267FC97A);
  static const stringData = Color(0xFF86C98A);
  static const stringSoft = Color(0x1F86C98A);
  static const lampRed = Color(0xFFD4593F);
  static const lampOff = Color(0xFF38424F);
  static const paper = Color(0xFFEEF3E2);
  static const paperBar = Color(0xFFDBE7CB);
  static const paperInk = Color(0xFF43523F);
}

const String monoFamily = 'JetBrains Mono';

abstract class MixText {
  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12.5,
    color: MixColors.data,
    height: 1.0,
  );
  static const monoDim = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12.5,
    color: MixColors.labelDim,
    height: 1.0,
  );
  static const panelTitle = TextStyle(
    fontSize: 10.5,
    letterSpacing: 1.6,
    color: MixColors.label,
    fontWeight: FontWeight.w600,
  );
  static const caption = TextStyle(
    fontSize: 10,
    letterSpacing: 1.2,
    color: MixColors.labelDim,
  );
}

/// Panel chrome shared by every console section.
class ConsolePanel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ConsolePanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MixColors.panel,
        border: Border.all(color: MixColors.bezel),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title.toUpperCase(), style: MixText.panelTitle),
              const SizedBox(width: 8),
              if (trailing != null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
