import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A background texture layered behind the console for some skins.
enum SkinTexture { none, scanlines, grid }

/// A complete visual identity for the console: a palette, a UI typeface, and
/// an optional background texture. Data/monospace text always uses [monoFont]
/// so byte columns stay aligned regardless of skin.
class MixSkin {
  final String id;
  final String label;
  final String monoFont;

  /// Font for titles/labels/chrome (null = the system sans-serif).
  final String? uiFont;
  final SkinTexture texture;

  final Color ground, panel, panelDeep, bezel, bezelSoft;
  final Color label_, labelDim, data, dataDim;
  final Color accent, blue, green, stringData, lampRed, lampOff;
  final Color paper, paperBar, paperInk;

  const MixSkin({
    required this.id,
    required this.label,
    this.monoFont = 'JetBrains Mono',
    this.uiFont,
    this.texture = SkinTexture.none,
    required this.ground,
    required this.panel,
    required this.panelDeep,
    required this.bezel,
    required this.bezelSoft,
    required this.label_,
    required this.labelDim,
    required this.data,
    required this.dataDim,
    required this.accent,
    required this.blue,
    required this.green,
    required this.stringData,
    required this.lampRed,
    required this.lampOff,
    required this.paper,
    required this.paperBar,
    required this.paperInk,
  });

  Color get accentSoft => accent.withValues(alpha: 0.15);
  Color get blueSoft => blue.withValues(alpha: 0.15);
  Color get greenSoft => green.withValues(alpha: 0.15);
  Color get stringSoft => stringData.withValues(alpha: 0.12);

  /// Three representative colors for the picker's palette preview.
  List<Color> get swatch => [panel, accent, blue];
}

const MixSkin skinDefault = MixSkin(
  id: 'default',
  label: 'Default',
  ground: Color(0xFF14181F),
  panel: Color(0xFF1D242E),
  panelDeep: Color(0xFF171D26),
  bezel: Color(0xFF2E3947),
  bezelSoft: Color(0xFF263040),
  label_: Color(0xFF8394A7),
  labelDim: Color(0xFF5C6B7D),
  data: Color(0xFFDCE4EE),
  dataDim: Color(0xFF9FADBD),
  accent: Color(0xFFE5A13C),
  blue: Color(0xFF62A4DE),
  green: Color(0xFF7FC97A),
  stringData: Color(0xFF86C98A),
  lampRed: Color(0xFFD4593F),
  lampOff: Color(0xFF38424F),
  paper: Color(0xFFEEF3E2),
  paperBar: Color(0xFFDBE7CB),
  paperInk: Color(0xFF43523F),
);

const MixSkin skinArcade = MixSkin(
  id: 'arcade',
  label: 'Arcade',
  uiFont: 'JetBrains Mono',
  texture: SkinTexture.scanlines,
  ground: Color(0xFF05060A),
  panel: Color(0xFF070B12),
  panelDeep: Color(0xFF0A1420),
  bezel: Color(0xFF17324A),
  bezelSoft: Color(0xFF1C3A5A),
  label_: Color(0xFF5AA0FF),
  labelDim: Color(0xFF3F6EA0),
  data: Color(0xFFE8EAF0),
  dataDim: Color(0xFF9FB8D0),
  accent: Color(0xFF20F0C0),
  blue: Color(0xFF5AA0FF),
  green: Color(0xFF3DFF6E),
  stringData: Color(0xFFFFE100),
  lampRed: Color(0xFFFF2E88),
  lampOff: Color(0xFF12233A),
  paper: Color(0xFF071207),
  paperBar: Color(0xFF0C1E0C),
  paperInk: Color(0xFF3DFF6E),
);

const MixSkin skinSteampunk = MixSkin(
  id: 'steampunk',
  label: 'Steampunk',
  uiFont: 'Georgia',
  ground: Color(0xFF1E140A),
  panel: Color(0xFF2A1E12),
  panelDeep: Color(0xFF231810),
  bezel: Color(0xFF6B4A24),
  bezelSoft: Color(0xFF4A3418),
  label_: Color(0xFFB89050),
  labelDim: Color(0xFF8A6A3A),
  data: Color(0xFFEAD9B8),
  dataDim: Color(0xFFB8A078),
  accent: Color(0xFFD8B46A),
  blue: Color(0xFF7AA6C8),
  green: Color(0xFFA6B86A),
  stringData: Color(0xFFE0B878),
  lampRed: Color(0xFFC8613A),
  lampOff: Color(0xFF4A3418),
  paper: Color(0xFFF2E6CF),
  paperBar: Color(0xFFE4D3B0),
  paperInk: Color(0xFF3A2A14),
);

const MixSkin skinCyberpunk = MixSkin(
  id: 'cyberpunk',
  label: 'Cyberpunk',
  uiFont: 'JetBrains Mono',
  texture: SkinTexture.grid,
  ground: Color(0xFF080611),
  panel: Color(0xFF0F0B1E),
  panelDeep: Color(0xFF0D0A1C),
  bezel: Color(0xFF2A1550),
  bezelSoft: Color(0xFF3A2270),
  label_: Color(0xFF6A7CFF),
  labelDim: Color(0xFF4A5AB0),
  data: Color(0xFFD7E6FF),
  dataDim: Color(0xFF9AAEE0),
  accent: Color(0xFF00EAFF),
  blue: Color(0xFF6A7CFF),
  green: Color(0xFFC6FF3D),
  stringData: Color(0xFFC6FF3D),
  lampRed: Color(0xFFFF2BD6),
  lampOff: Color(0xFF1A1030),
  paper: Color(0xFF0A0A14),
  paperBar: Color(0xFF12122A),
  paperInk: Color(0xFF00EAFF),
);

const MixSkin skinArtDeco = MixSkin(
  id: 'artdeco',
  label: 'Art Deco',
  uiFont: 'Futura',
  ground: Color(0xFF0A1512),
  panel: Color(0xFF12241F),
  panelDeep: Color(0xFF0E1C18),
  bezel: Color(0xFFC8A24A),
  bezelSoft: Color(0xFF6E5A2A),
  label_: Color(0xFFC0A048),
  labelDim: Color(0xFF8A6D2A),
  data: Color(0xFFE9DFC2),
  dataDim: Color(0xFFB0A480),
  accent: Color(0xFFE6C877),
  blue: Color(0xFF6FA0C0),
  green: Color(0xFF9AC07A),
  stringData: Color(0xFFE6C877),
  lampRed: Color(0xFFC8623A),
  lampOff: Color(0xFF3A3018),
  paper: Color(0xFFF2EAD2),
  paperBar: Color(0xFFE4D8B8),
  paperInk: Color(0xFF2A2410),
);

const List<MixSkin> allSkins = [
  skinDefault,
  skinArcade,
  skinSteampunk,
  skinCyberpunk,
  skinArtDeco,
];

/// The currently active skin. Widgets rebuild off this via a
/// ValueListenableBuilder near the app root.
final ValueNotifier<MixSkin> activeSkin = ValueNotifier<MixSkin>(skinDefault);

const String _skinPrefsKey = 'mix.skin';

/// Loads the persisted skin choice (if any) into [activeSkin]. Call once at
/// startup before the app is built.
Future<void> loadSavedSkin() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_skinPrefsKey);
    if (id != null) {
      final saved = allSkins.where((s) => s.id == id);
      if (saved.isNotEmpty) activeSkin.value = saved.first;
    }
  } catch (_) {
    // No persistence available (e.g. private mode): keep the default skin.
  }
}

/// Sets the active skin and persists the choice across sessions.
Future<void> setSkin(MixSkin skin) async {
  activeSkin.value = skin;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skinPrefsKey, skin.id);
  } catch (_) {
    // Persistence unavailable: the in-session change still applies.
  }
}

/// The console palette — resolves to the active skin so every existing
/// `MixColors.x` reference restyles when the skin changes.
abstract class MixColors {
  static MixSkin get _s => activeSkin.value;
  static Color get ground => _s.ground;
  static Color get panel => _s.panel;
  static Color get panelDeep => _s.panelDeep;
  static Color get bezel => _s.bezel;
  static Color get bezelSoft => _s.bezelSoft;
  static Color get label => _s.label_;
  static Color get labelDim => _s.labelDim;
  static Color get data => _s.data;
  static Color get dataDim => _s.dataDim;
  static Color get amber => _s.accent;
  static Color get amberSoft => _s.accentSoft;
  static Color get blue => _s.blue;
  static Color get blueSoft => _s.blueSoft;
  static Color get green => _s.green;
  static Color get greenSoft => _s.greenSoft;
  static Color get stringData => _s.stringData;
  static Color get stringSoft => _s.stringSoft;
  static Color get lampRed => _s.lampRed;
  static Color get lampOff => _s.lampOff;
  static Color get paper => _s.paper;
  static Color get paperBar => _s.paperBar;
  static Color get paperInk => _s.paperInk;
}

/// The monospace family (byte cells, memory) — constant across skins so
/// columns stay aligned.
String get monoFamily => activeSkin.value.monoFont;

/// Formats a MIX float value compactly: 9.0 -> "9", 3.6 -> "3.6".
String formatMixFloat(double v) {
  if (v == 0) return '0';
  final s = v.toStringAsPrecision(7);
  if (s.contains('e') || s.contains('E')) return s;
  if (!s.contains('.')) return s;
  return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

abstract class MixText {
  static TextStyle get mono => TextStyle(
        fontFamily: monoFamily,
        fontSize: 12.5,
        color: MixColors.data,
        height: 1.0,
      );
  static TextStyle get monoDim => TextStyle(
        fontFamily: monoFamily,
        fontSize: 12.5,
        color: MixColors.labelDim,
        height: 1.0,
      );
  static TextStyle get panelTitle => TextStyle(
        fontFamily: activeSkin.value.uiFont,
        fontSize: 10.5,
        letterSpacing: 1.6,
        color: MixColors.label,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get caption => TextStyle(
        fontFamily: activeSkin.value.uiFont,
        fontSize: 10,
        letterSpacing: 1.2,
        color: MixColors.labelDim,
      );
}

/// Paints the active skin's background texture across the whole viewport:
/// CRT scanlines for Arcade, a faint neon grid for Cyberpunk, nothing for the
/// rest. Kept very low-contrast so the console panels stay readable on top.
class SkinTexturePainter extends CustomPainter {
  final MixSkin skin;

  const SkinTexturePainter(this.skin);

  @override
  void paint(Canvas canvas, Size size) {
    switch (skin.texture) {
      case SkinTexture.none:
        return;
      case SkinTexture.scanlines:
        final paint = Paint()
          ..color = skin.accent.withValues(alpha: 0.045)
          ..strokeWidth = 1;
        for (double y = 0; y < size.height; y += 3) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case SkinTexture.grid:
        final paint = Paint()
          ..color = skin.accent.withValues(alpha: 0.05)
          ..strokeWidth = 1;
        const step = 34.0;
        for (double x = 0; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = 0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
    }
  }

  @override
  bool shouldRepaint(SkinTexturePainter old) => old.skin.id != skin.id;
}

/// The header control that switches skins: a compact chip showing the active
/// skin's name and palette, opening a menu of all skins with palette previews
/// and a check on the active one. Persists the choice via [setSkin].
class SkinPicker extends StatelessWidget {
  const SkinPicker({super.key});

  @override
  Widget build(BuildContext context) {
    // Reactive on its own so the chip's label/swatch always tracks the active
    // skin, even if the parent reuses this (const) widget without rebuilding.
    return ValueListenableBuilder<MixSkin>(
      valueListenable: activeSkin,
      builder: (context, active, _) => _build(context, active),
    );
  }

  Widget _build(BuildContext context, MixSkin active) {
    return PopupMenuButton<MixSkin>(
      tooltip: 'Change skin',
      color: MixColors.panel,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: MixColors.bezel),
      ),
      onSelected: setSkin,
      itemBuilder: (context) => [
        for (final skin in allSkins)
          PopupMenuItem<MixSkin>(
            value: skin,
            height: 40,
            child: Row(
              children: [
                _SwatchStrip(skin: skin),
                const SizedBox(width: 10),
                Text(
                  skin.label,
                  style: TextStyle(
                    fontFamily: monoFamily,
                    fontSize: 12.5,
                    color: MixColors.data,
                    fontWeight: skin.id == active.id
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                const Spacer(),
                if (skin.id == active.id)
                  Text('✓',
                      style: TextStyle(
                          fontSize: 12, color: MixColors.amber)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MixColors.panelDeep,
          border: Border.all(color: MixColors.bezel),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SKIN',
                style: TextStyle(
                    fontFamily: active.uiFont,
                    fontSize: 9,
                    letterSpacing: 1.4,
                    color: MixColors.labelDim)),
            const SizedBox(width: 8),
            _SwatchStrip(skin: active),
            const SizedBox(width: 8),
            Text(active.label.toUpperCase(),
                style: TextStyle(
                    fontFamily: monoFamily,
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                    color: MixColors.data)),
            const SizedBox(width: 6),
            Text('▾',
                style: TextStyle(fontSize: 10, color: MixColors.labelDim)),
          ],
        ),
      ),
    );
  }
}

/// The three-color palette preview used in the skin picker.
class _SwatchStrip extends StatelessWidget {
  final MixSkin skin;

  const _SwatchStrip({required this.skin});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MixColors.bezel),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in skin.swatch)
              Container(width: 9, height: 14, color: c),
          ],
        ),
      ),
    );
  }
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
