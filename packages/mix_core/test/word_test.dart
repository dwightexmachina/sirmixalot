import 'package:mix_core/mix_core.dart';
import 'package:test/test.dart';

void main() {
  group('MixWord basics', () {
    test('value/magnitude round-trips', () {
      expect(MixWord.fromValue(0).value, 0);
      expect(MixWord.fromValue(1234).value, 1234);
      expect(MixWord.fromValue(-1234).value, -1234);
      expect(MixWord.fromValue(MixWord.wordModulus - 1).value,
          MixWord.wordModulus - 1);
      expect(MixWord.fromValue(1000).bytes, [0, 0, 0, 15, 40]);
    });

    test('minus zero keeps its sign but compares as zero via value', () {
      final minusZero = MixWord(-1, const [0, 0, 0, 0, 0]);
      expect(minusZero.value, 0);
      expect(minusZero.sign, -1);
      expect(minusZero.isZero, isTrue);
    });

    test('equality and toString', () {
      expect(MixWord.fromValue(907), MixWord(1, const [0, 0, 0, 14, 11]));
      expect(MixWord.fromValue(-907).toString(), '- 00 00 00 14 11');
    });

    test('rejects out-of-range bytes and magnitudes', () {
      expect(() => MixWord(1, const [64, 0, 0, 0, 0]), throwsArgumentError);
      expect(() => MixWord.fromMagnitude(1, MixWord.wordModulus),
          throwsArgumentError);
    });
  });

  group('field extraction (the LDA examples from TAOCP 1.3.1)', () {
    // Word at 2000: - | 80 | 3 | 5 | 4 |, where 80 spans bytes 1-2.
    final w = MixWord(-1, const [1, 16, 3, 5, 4]);

    test('(0:5) is the whole word', () {
      expect(w.field(MixWord.fieldSpec(0, 5)), w);
    });
    test('(1:5) drops the sign', () {
      expect(w.field(MixWord.fieldSpec(1, 5)),
          MixWord(1, const [1, 16, 3, 5, 4]));
    });
    test('(3:5) takes the right three bytes', () {
      expect(w.field(MixWord.fieldSpec(3, 5)),
          MixWord(1, const [0, 0, 3, 5, 4]));
    });
    test('(0:3) keeps sign, right-justifies bytes 1-3', () {
      expect(w.field(MixWord.fieldSpec(0, 3)),
          MixWord(-1, const [0, 0, 1, 16, 3]));
    });
    test('(4:4) is a single byte', () {
      expect(w.field(MixWord.fieldSpec(4, 4)),
          MixWord(1, const [0, 0, 0, 0, 5]));
    });
    test('(0:0) is just the sign: minus zero', () {
      final r = w.field(MixWord.fieldSpec(0, 0));
      expect(r.sign, -1);
      expect(r.magnitude, 0);
    });
    test('bad specs throw', () {
      expect(() => w.field(MixWord.fieldSpec(3, 2)),
          throwsA(isA<MixRuntimeError>()));
      expect(() => w.field(MixWord.fieldSpec(1, 6)),
          throwsA(isA<MixRuntimeError>()));
    });
  });

  group('field storing (the STA examples from TAOCP 1.3.1)', () {
    // Memory cell: - | 1 | 2 | 3 | 4 | 5 |, rA: + | 6 | 7 | 8 | 9 | 0 |.
    final cell = MixWord(-1, const [1, 2, 3, 4, 5]);
    final ra = MixWord(1, const [6, 7, 8, 9, 0]);

    test('STA replaces everything', () {
      expect(cell.storing(ra, MixWord.fieldSpec(0, 5)), ra);
    });
    test('STA(1:5) keeps the cell sign', () {
      expect(cell.storing(ra, MixWord.fieldSpec(1, 5)),
          MixWord(-1, const [6, 7, 8, 9, 0]));
    });
    test('STA(5:5) stores the rightmost byte', () {
      expect(cell.storing(ra, MixWord.fieldSpec(5, 5)),
          MixWord(-1, const [1, 2, 3, 4, 0]));
    });
    test('STA(2:2) puts the rightmost byte into byte 2', () {
      expect(cell.storing(ra, MixWord.fieldSpec(2, 2)),
          MixWord(-1, const [1, 0, 3, 4, 5]));
    });
    test('STA(2:3) stores two bytes', () {
      expect(cell.storing(ra, MixWord.fieldSpec(2, 3)),
          MixWord(-1, const [1, 9, 0, 4, 5]));
    });
    test('STA(0:1) replaces sign and byte 1', () {
      expect(cell.storing(ra, MixWord.fieldSpec(0, 1)),
          MixWord(1, const [0, 2, 3, 4, 5]));
    });
  });
}
