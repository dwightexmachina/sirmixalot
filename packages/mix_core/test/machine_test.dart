import 'package:mix_core/mix_core.dart';
import 'package:test/test.dart';

/// Builds an instruction word from its parts.
MixWord instr(int aa, int i, int f, int c) {
  final mag = aa.abs();
  return MixWord(aa < 0 ? -1 : 1, [mag ~/ 64, mag % 64, i, f, c]);
}

void main() {
  group('loads and stores', () {
    test('LDA loads a full word and costs 2u', () {
      final m = MixMachine();
      m.memory[2000] = MixWord(-1, const [1, 16, 3, 5, 4]);
      m.memory[0] = instr(2000, 0, 5, 8);
      final r = m.step();
      expect(m.rA, MixWord(-1, const [1, 16, 3, 5, 4]));
      expect(m.cycles, 2);
      expect(m.pc, 1);
      expect(r.memReads, [2000]);
    });

    test('LDA with index register', () {
      final m = MixMachine();
      m.rI[2] = MixWord.fromValue(5); // rI3
      m.memory[1005] = MixWord.fromValue(999);
      m.memory[0] = instr(1000, 3, 5, 8);
      m.step();
      expect(m.rA.value, 999);
    });

    test('LD1 throws when the value does not fit two bytes', () {
      final m = MixMachine();
      m.memory[10] = MixWord.fromValue(4096);
      m.memory[0] = instr(10, 0, 5, 9);
      expect(() => m.step(), throwsA(isA<MixRuntimeError>()));
    });

    test('LDAN negates', () {
      final m = MixMachine();
      m.memory[10] = MixWord.fromValue(7);
      m.memory[0] = instr(10, 0, 5, 16);
      m.step();
      expect(m.rA.value, -7);
    });

    test('STJ stores into (0:2) by default field', () {
      final m = MixMachine();
      m.memory[0] = instr(100, 0, 0, 39); // JMP 100 -> rJ = 1
      m.memory[100] = instr(50, 0, 2, 32); // STJ 50
      m.memory[50] = instr(999, 0, 0, 39); // JMP 999 (to be patched)
      m.step();
      m.step();
      expect(m.memory[50], instr(1, 0, 0, 39)); // now JMP 1 (= rJ)
    });

    test('STZ zeroes a field', () {
      final m = MixMachine();
      m.memory[20] = MixWord(-1, const [1, 2, 3, 4, 5]);
      m.memory[0] = instr(20, 0, MixWord.fieldSpec(1, 5), 33);
      m.step();
      expect(m.memory[20], MixWord(-1, const [0, 0, 0, 0, 0]));
    });
  });

  group('arithmetic', () {
    test('ADD wraps and sets overflow', () {
      final m = MixMachine();
      m.rA = MixWord.fromValue(MixWord.wordModulus - 1);
      m.memory[10] = MixWord.fromValue(1);
      m.memory[0] = instr(10, 0, 5, 1);
      m.step();
      expect(m.overflow, isTrue);
      expect(m.rA.value, 0);
    });

    test('SUB reaching zero keeps the old sign of rA', () {
      final m = MixMachine();
      m.rA = MixWord.fromValue(-5);
      m.memory[10] = MixWord.fromValue(-5);
      m.memory[0] = instr(10, 0, 5, 2);
      m.step();
      expect(m.rA.magnitude, 0);
      expect(m.rA.sign, -1);
      expect(m.overflow, isFalse);
    });

    test('MUL spreads the product over rA:rX with the product sign', () {
      final m = MixMachine();
      m.rA = MixWord.fromValue(-112);
      m.memory[10] = MixWord.fromValue(109);
      m.memory[0] = instr(10, 0, 5, 3);
      m.step();
      expect(m.rA.sign, -1);
      expect(m.rA.magnitude, 0);
      expect(m.rX.value, -12208);
      expect(m.cycles, 10);
    });

    test('big MUL crosses into rA', () {
      final m = MixMachine();
      final big = MixWord.wordModulus - 1;
      m.rA = MixWord.fromValue(big);
      m.memory[10] = MixWord.fromValue(big);
      m.memory[0] = instr(10, 0, 5, 3);
      m.step();
      final product = big * big;
      expect(m.rA.magnitude, product ~/ MixWord.wordModulus);
      expect(m.rX.magnitude, product % MixWord.wordModulus);
    });

    test('DIV: quotient in rA, remainder in rX with old rA sign', () {
      final m = MixMachine();
      m.rA = MixWord(-1, const [0, 0, 0, 0, 0]); // -0
      m.rX = MixWord.fromValue(17);
      m.memory[10] = MixWord.fromValue(3);
      m.memory[0] = instr(10, 0, 5, 4);
      m.step();
      expect(m.rA.value, -5); // (-0):17 / 3, quotient sign = -1 * +1
      expect(m.rX.value, -2); // remainder keeps old rA sign
      expect(m.cycles, 12);
    });

    test('DIV by zero sets overflow and leaves registers alone', () {
      final m = MixMachine();
      m.rA = MixWord.fromValue(5);
      m.memory[0] = instr(10, 0, 5, 4);
      m.step();
      expect(m.overflow, isTrue);
      expect(m.rA.value, 5);
      expect(m.halted, isFalse);
    });
  });

  group('NUM, CHAR, HLT', () {
    test('NUM converts character digits, CHAR converts back', () {
      final m = MixMachine();
      m.rA = MixWord(-1, const [30, 30, 31, 32, 39]); // "00129"
      m.rX = MixWord(1, const [37, 37, 37, 37, 37]); // "77777"
      m.memory[0] = instr(0, 0, 0, 5); // NUM
      m.step();
      expect(m.rA.value, -12977777);
      expect(m.rX, MixWord(1, const [37, 37, 37, 37, 37])); // unchanged

      m.memory[1] = instr(0, 0, 1, 5); // CHAR round-trips
      m.step();
      expect(m.rA, MixWord(-1, const [30, 30, 31, 32, 39]));
      expect(m.rX, MixWord(1, const [37, 37, 37, 37, 37]));
    });

    test('NUM too large wraps and sets overflow', () {
      final m = MixMachine();
      m.rA = MixWord(1, const [39, 39, 39, 39, 39]); // "99999"
      m.rX = MixWord(1, const [39, 39, 39, 39, 39]); // "99999"
      m.memory[0] = instr(0, 0, 0, 5);
      m.step();
      expect(m.overflow, isTrue);
      expect(m.rA.magnitude, 9999999999 % MixWord.wordModulus);
    });

    test('HLT halts; pc points past it', () {
      final m = MixMachine();
      m.memory[0] = instr(0, 0, 2, 5);
      m.step();
      expect(m.halted, isTrue);
      expect(m.pc, 1);
      expect(() => m.step(), throwsA(isA<MixRuntimeError>()));
    });
  });

  group('shifts', () {
    MixMachine setUpAX() {
      final m = MixMachine();
      m.rA = MixWord(1, const [1, 2, 3, 4, 5]);
      m.rX = MixWord(-1, const [6, 7, 8, 9, 10]);
      return m;
    }

    test('SRAX 1', () {
      final m = setUpAX();
      m.memory[0] = instr(1, 0, 3, 6);
      m.step();
      expect(m.rA, MixWord(1, const [0, 1, 2, 3, 4]));
      expect(m.rX, MixWord(-1, const [5, 6, 7, 8, 9]));
    });

    test('SLA 2 shifts only rA, keeping its sign', () {
      final m = setUpAX();
      m.memory[0] = instr(2, 0, 0, 6);
      m.step();
      expect(m.rA, MixWord(1, const [3, 4, 5, 0, 0]));
      expect(m.rX, MixWord(-1, const [6, 7, 8, 9, 10]));
    });

    test('SRC 4 circulates right across both registers', () {
      final m = setUpAX();
      m.memory[0] = instr(4, 0, 5, 6);
      m.step();
      expect(m.rA, MixWord(1, const [7, 8, 9, 10, 1]));
      expect(m.rX, MixWord(-1, const [2, 3, 4, 5, 6]));
    });

    test('SLC wraps its count modulo 10', () {
      final m = setUpAX();
      m.memory[0] = instr(10, 0, 4, 6);
      m.step();
      expect(m.rA, MixWord(1, const [1, 2, 3, 4, 5]));
    });

    test('oversized non-circular shift clears everything', () {
      final m = setUpAX();
      m.memory[0] = instr(99, 0, 2, 6); // SLAX 99
      m.step();
      expect(m.rA.magnitude, 0);
      expect(m.rX.magnitude, 0);
    });
  });

  group('MOVE', () {
    test('moves words and advances rI1; cost 1+2F', () {
      final m = MixMachine();
      for (var k = 0; k < 3; k++) {
        m.memory[1000 + k] = MixWord.fromValue(k + 1);
      }
      m.rI[0] = MixWord.fromValue(2500);
      m.memory[0] = instr(1000, 0, 3, 7);
      m.step();
      expect(m.memory[2500].value, 1);
      expect(m.memory[2502].value, 3);
      expect(m.rI[0].value, 2503);
      expect(m.cycles, 7);
    });
  });

  group('jumps and comparisons', () {
    test('JMP sets rJ to the following address', () {
      final m = MixMachine();
      m.memory[5] = instr(300, 0, 0, 39);
      m.pc = 5;
      m.step();
      expect(m.pc, 300);
      expect(m.rJ.value, 6);
    });

    test('JSJ leaves rJ alone', () {
      final m = MixMachine();
      m.memory[0] = instr(300, 0, 1, 39);
      m.step();
      expect(m.pc, 300);
      expect(m.rJ.value, 0);
    });

    test('JOV jumps and clears; JNOV clears without jumping', () {
      final m = MixMachine();
      m.overflow = true;
      m.memory[0] = instr(100, 0, 2, 39);
      m.step();
      expect(m.pc, 100);
      expect(m.overflow, isFalse);

      m.overflow = true;
      m.memory[100] = instr(200, 0, 3, 39); // JNOV
      m.step();
      expect(m.pc, 101); // no jump
      expect(m.overflow, isFalse);
    });

    test('CMPA drives JL/JE/JG; -0 equals +0', () {
      final m = MixMachine();
      m.rA = MixWord(-1, const [0, 0, 0, 0, 0]);
      m.memory[10] = MixWord.zero;
      m.memory[0] = instr(10, 0, 5, 56);
      m.step();
      expect(m.comparison, MixComparison.equal);

      m.rA = MixWord.fromValue(907);
      m.memory[10] = MixWord.fromValue(999);
      m.memory[1] = instr(10, 0, 5, 56);
      m.step();
      expect(m.comparison, MixComparison.less);
    });

    test('register jumps test sign of the register', () {
      final m = MixMachine();
      m.rX = MixWord.fromValue(-3);
      m.memory[0] = instr(77, 0, 0, 47); // JXN
      m.step();
      expect(m.pc, 77);

      final m2 = MixMachine();
      m2.rI[0] = MixWord(-1, const [0, 0, 0, 0, 0]); // -0 counts as zero
      m2.memory[0] = instr(77, 0, 1, 41); // J1Z
      m2.step();
      expect(m2.pc, 77);
    });
  });

  group('address transfers', () {
    test('ENTA and ENNA, including the minus-zero instruction sign', () {
      final m = MixMachine();
      m.memory[0] = instr(45, 0, 2, 48);
      m.step();
      expect(m.rA.value, 45);

      m.memory[1] = MixWord(-1, const [0, 0, 0, 2, 48]); // ENTA -0
      m.step();
      expect(m.rA.sign, -1);
      expect(m.rA.magnitude, 0);

      m.memory[2] = instr(45, 0, 3, 48); // ENNA 45
      m.step();
      expect(m.rA.value, -45);
    });

    test('ENT3 with index copies another register', () {
      final m = MixMachine();
      m.rI[0] = MixWord.fromValue(10); // rI1
      m.memory[0] = instr(0, 1, 2, 51); // ENT3 0,1
      m.step();
      expect(m.rI[2].value, 10);
    });

    test('INCA overflow behaves like ADD; index overflow throws', () {
      final m = MixMachine();
      m.rA = MixWord.fromValue(MixWord.wordModulus - 1);
      m.memory[0] = instr(1, 0, 0, 48);
      m.step();
      expect(m.overflow, isTrue);
      expect(m.rA.value, 0);

      final m2 = MixMachine();
      m2.rI[3] = MixWord.fromValue(4095);
      m2.memory[0] = instr(1, 0, 0, 52); // INC4 1
      expect(() => m2.step(), throwsA(isA<MixRuntimeError>()));
    });

    test('DEC to zero keeps the register sign', () {
      final m = MixMachine();
      m.rI[2] = MixWord.fromValue(1);
      m.memory[0] = instr(1, 0, 1, 51); // DEC3 1
      m.step();
      expect(m.rI[2].value, 0);
      expect(m.rI[2].sign, 1);
    });
  });

  group('guards', () {
    test('out-of-range memory access throws', () {
      final m = MixMachine();
      m.memory[0] = instr(4000, 0, 5, 8);
      expect(() => m.step(), throwsA(isA<MixRuntimeError>()));
    });

    test('floating point ops now execute (FADD 1.0 + 1.0 = 2.0)', () {
      final m = MixMachine();
      m.rA = mixFloatFromDouble(1.0).word;
      m.memory[10] = mixFloatFromDouble(1.0).word;
      m.memory[0] = instr(10, 0, 6, 1); // FADD
      m.step();
      expect(mixFloatValue(m.rA), closeTo(2.0, 1e-9));
    });
  });
}
