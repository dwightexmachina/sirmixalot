import 'package:mix_core/mix_core.dart';
import 'package:test/test.dart';

const programM = '''
* Program M (TAOCP 1.3.2): find the maximum of X[1..n].
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
        END  MAXIMUM
''';

MixWord w(int sign, List<int> bytes) => MixWord(sign, bytes);

void main() {
  group('Program M assembles to the book listing', () {
    final p = assembleMixal(programM);

    test('every word matches its known encoding', () {
      expect(p.words, {
        3000: w(1, [47, 1, 0, 2, 32]), // STJ  3009(0:2)
        3001: w(1, [0, 0, 1, 2, 51]), //  ENT3 0,1
        3002: w(1, [46, 61, 0, 0, 39]), // JMP  3005
        3003: w(1, [15, 40, 3, 5, 56]), // CMPA 1000,3
        3004: w(1, [46, 63, 0, 7, 39]), // JGE  3007
        3005: w(1, [0, 0, 3, 2, 50]), //  ENT2 0,3
        3006: w(1, [15, 40, 3, 5, 8]), // LDA  1000,3
        3007: w(1, [0, 1, 0, 1, 51]), //  DEC3 1
        3008: w(1, [46, 59, 0, 2, 43]), // J3P  3003
        3009: w(1, [47, 1, 0, 0, 39]), // JMP  3009
      });
    });

    test('start address, symbols, and source-line map', () {
      expect(p.start, 3000);
      expect(p.symbols['X'], 1000);
      expect(p.symbols['MAXIMUM'], 3000);
      expect(p.symbols['CHANGEM'], 3005);
      expect(p.sourceLines[3000], 4); // MAXIMUM STJ EXIT
      expect(p.sourceLines[3009], 13); // EXIT JMP *
    });
  });

  group('directives and operand forms', () {
    test('CON, EQU with expressions, ORIG', () {
      final p = assembleMixal('''
L       EQU  500
        ORIG L*2+10
A       CON  -1234
B       CON  L/4:1
        END  A
''');
      expect(p.words[1010], MixWord.fromValue(-1234));
      // L/4:1 evaluates left to right: (500/4):1 = 8*125+1.
      expect(p.words[1011], MixWord.fromValue(1001));
      expect(p.symbols['A'], 1010);
    });

    test('default fields: STJ gets (0:2), LDA gets (0:5)', () {
      final p = assembleMixal('''
        ORIG 100
        STJ  200
        LDA  200
        LDA  200(1:3)
        END  100
''');
      expect(p.words[100]!.bytes[3], MixWord.fieldSpec(0, 2));
      expect(p.words[101]!.bytes[3], MixWord.fieldSpec(0, 5));
      expect(p.words[102]!.bytes[3], MixWord.fieldSpec(1, 3));
    });

    test('ALF: quoted, blank-padded, and the two-space convention', () {
      final p = assembleMixal('''
        ORIG 10
        ALF  "HI"
        ALF  WORLD
        ALF   MIX
        END  10
''');
      int code(String c) => mixCharCode(c)!;
      expect(p.words[10]!.bytes, ['H', 'I', ' ', ' ', ' '].map(code));
      expect(p.words[11]!.bytes, ['W', 'O', 'R', 'L', 'D'].map(code));
      // Two spaces after ALF: the constant starts with a blank.
      expect(p.words[12]!.bytes, [' ', 'M', 'I', 'X', ' '].map(code));
    });

    test('data words are classified by origin (CON / ALF / literal)', () {
      final p = assembleMixal('''
        ORIG 100
N       CON  231
MSG     ALF  "HELLO"
S       LDA  =42=
        HLT
        END  100
''');
      expect(p.dataKinds[100], DataKind.number); // CON 231
      expect(p.dataKinds[101], DataKind.string); // ALF "HELLO"
      // The literal =42= is placed just after END (past HLT at 104).
      final litAddr =
          p.dataKinds.entries.firstWhere((e) => e.value == DataKind.literal).key;
      expect(p.words[litAddr], MixWord.fromValue(42));
      // Instruction addresses are not data.
      expect(p.dataKinds.containsKey(102), isFalse); // LDA
      expect(p.dataKinds.containsKey(103), isFalse); // HLT
      // Back-compat getter still reports all data addresses.
      expect(p.dataAddresses, containsAll([100, 101, litAddr]));
    });

    test('literals are placed after END and deduplicated', () {
      final p = assembleMixal('''
        ORIG 3000
START   LDA  =1234=
        ADD  =1234=
        SUB  =99=
        HLT
        END  START
''');
      // Two distinct literals directly after the HLT at 3003.
      expect(p.words[3004], MixWord.fromValue(1234));
      expect(p.words[3005], MixWord.fromValue(99));
      final lda = Instruction(p.words[3000]!);
      final add = Instruction(p.words[3001]!);
      final sub = Instruction(p.words[3002]!);
      expect(lda.aa, 3004);
      expect(add.aa, 3004);
      expect(sub.aa, 3005);
    });

    test('local symbols resolve backward and forward', () {
      final p = assembleMixal('''
        ORIG 0
2H      NOP
        JMP  2B
        JMP  2F
2H      NOP
        END  0
''');
      expect(Instruction(p.words[1]!).aa, 0);
      expect(Instruction(p.words[2]!).aa, 3);
    });
  });

  group('errors', () {
    test('unknown operation', () {
      expect(() => assembleMixal('  FOO 1\n  END 0\n'),
          throwsA(isA<MixAssemblyError>()));
    });
    test('duplicate symbol', () {
      expect(
          () => assembleMixal('A NOP\nA NOP\n END 0\n'),
          throwsA(isA<MixAssemblyError>()
              .having((e) => e.message, 'message', contains('twice'))));
    });
    test('missing END', () {
      expect(() => assembleMixal(' NOP\n'),
          throwsA(isA<MixAssemblyError>()));
    });
    test('future reference must stand alone', () {
      expect(() => assembleMixal(' JMP LATER+1\nLATER NOP\n END 0\n'),
          throwsA(isA<MixAssemblyError>()));
    });
    test('undefined symbol at END', () {
      expect(() => assembleMixal(' JMP NOWHERE\n END 0\n'),
          throwsA(isA<MixAssemblyError>()));
    });
  });

  group('disassembler', () {
    test('renders common shapes', () {
      expect(disassemble(w(1, [15, 40, 3, 5, 8])), 'LDA 1000,3');
      expect(disassemble(w(1, [47, 1, 0, 2, 32])), 'STJ 3009');
      expect(disassemble(w(1, [31, 16, 0, 3, 8])), 'LDA 2000(0:3)');
      expect(disassemble(w(1, [0, 1, 0, 1, 51])), 'DEC3 1');
    });
  });
}
