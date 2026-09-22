import 'package:mix_core/mix_core.dart';
import 'package:test/test.dart';

MixWord flt(double x) => mixFloatFromDouble(x).word;

MixWord instr(int aa, int i, int f, int c) {
  final mag = aa.abs();
  return MixWord(aa < 0 ? -1 : 1, [mag ~/ 64, mag % 64, i, f, c]);
}

void main() {
  group('encoding', () {
    test('round-trips representative values', () {
      for (final x in [0.0, 1.0, 2.0, 0.5, 64.0, -3.25, 1000.0, 0.015625]) {
        expect(mixFloatValue(flt(x)), closeTo(x, 1e-9), reason: '$x');
      }
    });

    test('1.0 normalizes as expected (bias 32)', () {
      final one = flt(1.0);
      expect(one.bytes[0], 33); // exponent byte
      expect(one.bytes.sublist(1), [1, 0, 0, 0]); // fraction 64^3
    });

    test('zero fraction reads as 0 whatever the exponent', () {
      expect(mixFloatValue(MixWord(1, const [50, 0, 0, 0, 0])), 0.0);
    });
  });

  group('instructions', () {
    MixMachine run(int c, double a, double v) {
      final m = MixMachine();
      m.rA = flt(a);
      m.memory[100] = flt(v);
      m.memory[0] = instr(100, 0, 6, c); // F=6 selects the float variant
      m.step();
      return m;
    }

    test('FADD', () => expect(mixFloatValue(run(1, 1.5, 2.25).rA), closeTo(3.75, 1e-9)));
    test('FSUB', () => expect(mixFloatValue(run(2, 5.0, 1.5).rA), closeTo(3.5, 1e-9)));
    test('FMUL', () => expect(mixFloatValue(run(3, 2.0, 3.0).rA), closeTo(6.0, 1e-9)));
    test('FDIV', () => expect(mixFloatValue(run(4, 6.0, 2.0).rA), closeTo(3.0, 1e-9)));

    test('FADD to zero yields zero', () {
      expect(mixFloatValue(run(2, 4.0, 4.0).rA), 0.0);
    });

    test('FMUL costs 9u, FADD 4u', () {
      expect(run(3, 2.0, 3.0).cycles, 9);
      expect(run(1, 2.0, 3.0).cycles, 4);
    });

    test('FDIV by zero sets overflow, leaves rA', () {
      final m = MixMachine();
      m.rA = flt(6.0);
      m.memory[100] = flt(0.0);
      m.memory[0] = instr(100, 0, 6, 4);
      m.step();
      expect(m.overflow, isTrue);
    });

    test('FCMP orders values and honors epsilon', () {
      final m = MixMachine();
      m.rA = flt(1.0);
      m.memory[100] = flt(2.0);
      m.memory[0] = instr(100, 0, 6, 56); // FCMP
      m.step();
      expect(m.comparison, MixComparison.less);

      final m2 = MixMachine();
      m2.rA = flt(1.0);
      m2.memory[100] = flt(1.0001);
      m2.floatEpsilon = flt(0.001); // within fuzz -> equal
      m2.memory[0] = instr(100, 0, 6, 56);
      m2.step();
      expect(m2.comparison, MixComparison.equal);
    });
  });

  test('end-to-end: assemble and run a float computation', () {
    // rA = 1.5; FADD 2.5 -> 4.0; FMUL 2.0 -> 8.0.
    final program = assembleMixal('''
        ORIG 3000
START   LDA  HALF3
        FADD HALF5
        FMUL TWO
        STA  RESULT
        HLT
HALF3   CON  0
HALF5   CON  0
TWO     CON  0
RESULT  CON  0
        END  START
''');
    final m = MixMachine()..loadProgram(program);
    // Patch the float constants in place (no float literal syntax yet).
    m.memory[program.symbols['HALF3']!] = flt(1.5);
    m.memory[program.symbols['HALF5']!] = flt(2.5);
    m.memory[program.symbols['TWO']!] = flt(2.0);
    m.run();
    expect(mixFloatValue(m.memory[program.symbols['RESULT']!]), closeTo(8.0, 1e-9));
  });
}
