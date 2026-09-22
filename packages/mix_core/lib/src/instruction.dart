import 'op_table.dart';
import 'word.dart';

/// A decoded view of a word interpreted as an instruction:
/// sign+AA (address), I (index), F (field/modifier), C (opcode).
class Instruction {
  final MixWord word;
  Instruction(this.word);

  int get c => word.bytes[4];
  int get f => word.bytes[3];
  int get i => word.bytes[2];
  int get aa => word.sign * (word.bytes[0] * MixWord.byteSize + word.bytes[1]);
  int get fieldL => f ~/ 8;
  int get fieldR => f % 8;
}

final Map<int, Map<int, String>> _byCF = _buildByCF();

Map<int, Map<int, String>> _buildByCF() {
  final out = <int, Map<int, String>>{};
  mixalOps.forEach((name, info) {
    (out[info.c] ??= {}).putIfAbsent(info.defaultF, () => name);
  });
  return out;
}

/// Best-effort disassembly of [w] as an instruction, for display.
///
/// Uses the exact (C, F) mnemonic when F selects the operation (jumps,
/// shifts, ENT/INC, ...) and appends an explicit (L:R) suffix when F is a
/// non-default field spec.
String disassemble(MixWord w) {
  final ins = Instruction(w);
  final family = _byCF[ins.c];
  if (family == null || family.isEmpty) return '??? $w';
  var name = family[ins.f];
  var suffix = '';
  if (name == null) {
    name = family[5] ?? family[2] ?? family.values.first;
    suffix = '(${ins.fieldL}:${ins.fieldR})';
  }
  final index = ins.i == 0 ? '' : ',${ins.i}';
  return '$name ${ins.aa}$index$suffix';
}
