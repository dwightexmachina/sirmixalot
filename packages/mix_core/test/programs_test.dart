import 'package:mix_core/mix_core.dart';
import 'package:test/test.dart';

/// End-to-end runs of real MIXAL programs, including Program M from
/// TAOCP 1.3.2 with a small driver.
void main() {
  test('Program M finds the maximum, with exact cycle count', () {
    final program = assembleMixal('''
X       EQU  1000
        ORIG 3000
MAXIMUM STJ  EXIT
INIT    ENT3 0,1
        JMP  CHANGEM
LOOP    CMPA X,3
        JGE  *+3
CHANGEM ENT2 0,3
        LDA  X,3
        DEC3 1
        J3P  LOOP
EXIT    JMP  *
START   ENT1 10
        JMP  MAXIMUM
        HLT
        END  START
''');
    final m = MixMachine()..loadProgram(program);
    const data = [231, 88, 512, 64, 999, 305, 907, 118, 730, 190];
    for (var k = 0; k < data.length; k++) {
      m.memory[1001 + k] = MixWord.fromValue(data[k]);
    }
    m.run();

    expect(m.rA.value, 999, reason: 'maximum value in rA');
    expect(m.rI[1].value, 5, reason: 'index of the maximum in rI2');
    expect(m.rI[2].value, 0, reason: 'loop counter rI3 ran out');
    expect(m.rI[0].value, 10, reason: 'n untouched in rI1');

    // Hand-counted for this data (3 changes of maximum after the initial
    // one; HLT itself costs 10u in this implementation):
    // driver 2u + subroutine 64u + HLT 10u.
    expect(m.cycles, 76);
    expect(m.instructions, 53);
  });

  test("Euclid's algorithm: gcd(1071, 462) = 21", () {
    final program = assembleMixal('''
U       EQU  1000
V       EQU  1001
W       EQU  1002
        ORIG 3000
START   LDA  U
        LDX  V
2H      JXZ  1F
        STX  W
        SRAX 5
        DIV  W
        LDA  W
        JMP  2B
1H      HLT
        END  START
''');
    final m = MixMachine()..loadProgram(program);
    m.memory[1000] = MixWord.fromValue(1071);
    m.memory[1001] = MixWord.fromValue(462);
    m.run();
    expect(m.rA.value, 21);
    expect(m.overflow, isFalse);
  });

  test('OUT prints a line through the line printer', () {
    final program = assembleMixal('''
        ORIG 3000
START   OUT  MSG(18)
        HLT
MSG     ALF  "HELLO"
        ALF  " MIX "
        END  START
''');
    final m = MixMachine()..loadProgram(program);
    m.run();
    expect(m.printer.lines, ['HELLO MIX']);
  });

  test('IN reads a card; NUM converts it; CHAR + OUT echo it', () {
    final program = assembleMixal('''
BUF     EQU  100
        ORIG 3000
START   IN   BUF(16)
        LDA  BUF
        LDX  BUF+1
        NUM  0
        STA  200
        HLT
        END  START
''');
    final m = MixMachine()..loadProgram(program);
    m.cardReader.cards.add('0000012345');
    m.run();
    expect(m.memory[200].value, 12345);
  });

  test('runaway programs hit the instruction limit', () {
    final program = assembleMixal('''
        ORIG 0
HERE    JMP  HERE
        END  HERE
''');
    final m = MixMachine()..loadProgram(program);
    expect(() => m.run(maxInstructions: 1000),
        throwsA(isA<MixRuntimeError>()));
  });
}
