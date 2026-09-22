import 'package:mix_core/mix_core.dart';
import 'package:test/test.dart';

MixWord instr(int aa, int i, int f, int c) {
  final mag = aa.abs();
  return MixWord(aa < 0 ? -1 : 1, [mag ~/ 64, mag % 64, i, f, c]);
}

void main() {
  test('JGE explains the comparison indicator and predicts not-taken', () {
    final m = MixMachine();
    m.pc = 3004;
    m.memory[3004] = instr(3007, 0, 7, 39);
    m.comparison = MixComparison.less;

    final e = explainInstruction(m.memory[3004], machine: m, address: 3004);
    expect(e.mnemonic, 'JGE 3007');
    expect(e.name, 'jump if greater or equal');
    expect(e.fields, contains('C=39'));
    expect(e.fields, contains('selects JGE'));
    expect(e.body, contains('comparison indicator'));
    expect(e.body, contains('3007'));
    expect(e.body, contains('3005')); // fall-through / return address
    expect(e.rightNow, contains('LESS'));
    expect(e.rightNow, contains('will not be taken'));
    expect(e.cost, 1);
  });

  test('LDA with index resolves M and predicts the loaded value', () {
    final m = MixMachine();
    m.pc = 0;
    m.rI[2] = MixWord.fromValue(5); // rI3
    m.memory[1005] = MixWord.fromValue(999);
    m.memory[0] = instr(1000, 3, 5, 8);

    final e = explainInstruction(m.memory[0], machine: m, address: 0);
    expect(e.name, 'load rA');
    expect(e.body, contains('1000 + rI3 (5) = 1005'));
    expect(e.rightNow, contains('999'));
  });

  test('no prediction when the cell is not the next instruction', () {
    final m = MixMachine();
    m.pc = 50; // hovering elsewhere
    final e = explainInstruction(instr(1000, 3, 5, 8), machine: m, address: 7);
    expect(e.rightNow, isNull);
    expect(e.body, contains('1000 + rI3')); // symbolic, unresolved
  });

  test('STJ mentions the self-modifying return-address idiom', () {
    final e = explainInstruction(instr(3009, 0, 2, 32));
    expect(e.name, 'store the jump register');
    expect(e.body, contains('return'));
    expect(e.chips, contains('self-modifying idiom'));
  });

  test('register jump predicts from the register value', () {
    final m = MixMachine();
    m.pc = 10;
    m.rI[2] = MixWord.fromValue(5);
    m.memory[10] = instr(3003, 0, 2, 43); // J3P

    final e = explainInstruction(m.memory[10], machine: m, address: 10);
    expect(e.name, 'jump if rI3 positive');
    expect(e.rightNow, contains('rI3 = 5'));
    expect(e.rightNow, contains('will be taken'));
  });

  test('CMPA predicts the indicator result', () {
    final m = MixMachine();
    m.pc = 0;
    m.rA = MixWord.fromValue(907);
    m.memory[1005] = MixWord.fromValue(999);
    m.memory[0] = instr(1005, 0, 5, 56);

    final e = explainInstruction(m.memory[0], machine: m, address: 0);
    expect(e.rightNow, contains('LESS'));
  });

  test('every C value produces a sane explanation without throwing', () {
    for (var c = 0; c < 64; c++) {
      for (final f in [0, 1, 2, 5, 6, 7, 13]) {
        final e = explainInstruction(instr(100, 0, f, c));
        expect(e.body, isNotEmpty, reason: 'C=$c F=$f');
        expect(e.chips, isNotEmpty);
      }
    }
  });

  test('bad addresses and DIV by zero explain the failure', () {
    final m = MixMachine();
    m.pc = 0;
    m.memory[0] = instr(4000 - 4096, 0, 5, 8); // negative M
    final e = explainInstruction(m.memory[0], machine: m, address: 0);
    expect(e.rightNow, contains('outside memory'));

    final m2 = MixMachine();
    m2.pc = 0;
    m2.memory[0] = instr(10, 0, 5, 4); // DIV by memory[10] == +0
    final e2 = explainInstruction(m2.memory[0], machine: m2, address: 0);
    expect(e2.rightNow, contains('divisor is zero'));
  });
}
