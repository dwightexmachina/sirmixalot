import 'package:flutter_test/flutter_test.dart';
import 'package:mix_core/mix_core.dart';
import 'package:sirmixalot/src/programs/gallery.dart';

GalleryProgram byId(String id) => gallery.firstWhere((p) => p.id == id);

MixMachine runProgram(String id, {int maxInstructions = 5000000}) {
  final program = assembleMixal(byId(id).source);
  final m = MixMachine()..loadProgram(program);
  m.run(maxInstructions: maxInstructions);
  return m;
}

void main() {
  test('every gallery program assembles', () {
    for (final p in gallery) {
      expect(() => assembleMixal(p.source), returnsNormally,
          reason: 'assembling ${p.id}');
    }
  });

  test('Program P computes the first 500 primes and prints 50 lines', () {
    final m = runProgram('primes');
    const prime = 2000;
    expect(m.memory[prime + 1].value, 2);
    expect(m.memory[prime + 2].value, 3);
    expect(m.memory[prime + 3].value, 5);
    expect(m.memory[prime + 25].value, 97); // 25th prime
    expect(m.memory[prime + 500].value, 3571); // the 500th prime
    expect(m.printer.lines.length, 50);
    // First line holds the first ten primes, space-separated five-wide.
    expect(m.printer.lines.first.replaceAll(RegExp(r'\s+'), ' ').trim(),
        '00002 00003 00005 00007 00011 00013 00017 00019 00023 00029');
  });

  test('permutation inverse: (2 3 1)(5 6 4) -> [3 1 2 6 4 5]', () {
    final m = runProgram('perm-inverse');
    final got = [for (var i = 1; i <= 6; i++) m.memory[1000 + i].value];
    expect(got, [3, 1, 2, 6, 4, 5]);
  });

  test('permutation product Z[i] = A[B[i]] -> [4 6 5 1 3 2]', () {
    final m = runProgram('perm-product');
    final z = [for (var i = 1; i <= 6; i++) m.memory[1020 + i].value];
    expect(z, [4, 6, 5, 1, 3, 2]);
  });

  test('coroutines sum 1..5 into SUM = 15', () {
    final m = runProgram('coroutine');
    expect(m.memory[1001].value, 15);
  });

  test('Program A composes (ABC)(AB): A->A, B->C, C->B', () {
    final m = runProgram('program-a');
    // Q at 700 indexed by MIX char code (A=1, B=2, C=3).
    expect(m.memory[701].value, 1);
    expect(m.memory[702].value, 3);
    expect(m.memory[703].value, 2);
  });

  test('Horner evaluates 2x^3-3x^2+5 at x=2 to 9.0', () {
    final program = assembleMixal(byId('float-horner').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    expect(mixFloatValue(m.memory[program.symbols['RESULT']!]),
        closeTo(9.0, 1e-4));
  });

  test('float average of 1.5..6.0 is 3.6', () {
    final program = assembleMixal(byId('float-average').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    expect(mixFloatValue(m.memory[program.symbols['RESULT']!]),
        closeTo(3.6, 1e-4));
  });

  test('LCG matches X = (aX + c) mod 2^30 for 8 values', () {
    final m = runProgram('lcg');
    const a = 1664525, c = 1013904223, mod = 1 << 30;
    var x = 1;
    for (var i = 0; i < 8; i++) {
      x = (a * x + c) % mod;
      expect(m.memory[1000 + i].value, x, reason: 'value $i');
    }
  });

  test('range technique rolls dice in 1..6 = floor(6X/m)+1', () {
    final m = runProgram('random-range');
    const a = 1664525, c = 1013904223, mod = 1 << 30;
    var x = 1;
    for (var i = 0; i < 10; i++) {
      x = (a * x + c) % mod;
      final roll = (6 * x) ~/ mod + 1;
      expect(m.memory[1000 + i].value, roll, reason: 'roll $i');
      expect(roll, inInclusiveRange(1, 6));
    }
  });

  test('shuffle produces the Fisher-Yates permutation for the seed', () {
    final m = runProgram('shuffle');
    const a = 1664525, c = 1013904223, mod = 1 << 30;
    final arr = List.generate(9, (i) => i);
    var x = 1;
    for (var j = 8; j >= 2; j--) {
      x = (a * x + c) % mod;
      final k = (x * j) ~/ mod + 1;
      final t = arr[j];
      arr[j] = arr[k];
      arr[k] = t;
    }
    for (var i = 1; i <= 8; i++) {
      expect(m.memory[1000 + i].value, arr[i], reason: 'A[$i]');
    }
    // Still a permutation of 1..8.
    expect({for (var i = 1; i <= 8; i++) m.memory[1000 + i].value},
        {1, 2, 3, 4, 5, 6, 7, 8});
  });

  test('multiple-precision add rolls b^4-1 + 1 over to a carry', () {
    final program = assembleMixal(byId('mp-add').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    for (var i = 0; i < 4; i++) {
      expect(m.memory[1020 + i].value, 0, reason: 'W[$i]');
    }
    expect(m.memory[program.symbols['CARRY']!].value, 1);
  });

  test('binary GCD of 1071 and 462 is 21', () {
    final program = assembleMixal(byId('binary-gcd').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    expect(m.memory[program.symbols['RESULT']!].value, 21);
  });

  test('power computes 3^13 = 1594323', () {
    final program = assembleMixal(byId('power').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    expect(m.memory[program.symbols['RESULT']!].value, 1594323);
  });

  for (final id in [
    'insertion-sort',
    'bubble-sort',
    'shellsort',
    'heapsort',
    'quicksort',
    'radix-sort',
    'merge-two-way',
    'natural-merge',
    'selection-sort',
    'list-insertion',
  ]) {
    test('$id fills and sorts 100 values into non-decreasing order', () {
      final m = runProgram(id);
      final out = [for (var i = 0; i < 100; i++) m.memory[1001 + i].value];
      for (var i = 1; i < out.length; i++) {
        expect(out[i] >= out[i - 1], isTrue, reason: '$id at $i');
      }
      // The fill really produced a spread of values (not all identical).
      expect(out.toSet().length, greaterThan(1), reason: '$id filled');
    });
  }

  for (final id in ['sequential-search', 'binary-search', 'uniform-search']) {
    test('$id finds key 73 at index 73', () {
      final program = assembleMixal(byId(id).source);
      final m = MixMachine()..loadProgram(program);
      m.run();
      expect(m.memory[program.symbols['RESULT']!].value, 73);
    });
  }

  for (final id in ['tree-search', 'hash-chaining', 'hash-linear']) {
    test('$id finds the present key (FOUND=1)', () {
      final program = assembleMixal(byId(id).source);
      final m = MixMachine()..loadProgram(program);
      m.run();
      expect(m.memory[program.symbols['FOUND']!].value, 1);
    });
  }

  int fromBig(MixMachine m, int base, int n, int r) {
    var v = 0;
    for (var i = 0; i < n; i++) {
      v = v * r + m.memory[base + i].value;
    }
    return v;
  }

  int fromLittle(MixMachine m, int base, int n, int r) {
    var v = 0;
    for (var i = n - 1; i >= 0; i--) {
      v = v * r + m.memory[base + i].value;
    }
    return v;
  }

  test('mp subtraction: 10^12 - 1', () {
    final m = runProgram('mp-sub');
    expect(fromBig(m, 1200, 4, 10000), 1000000000000 - 1);
  });

  test('mp multiplication', () {
    final m = runProgram('mp-mul');
    expect(fromLittle(m, 1200, 4, 10000), 12345678 * 87654321);
  });

  test('mp short division of 123456789 by 7', () {
    final program = assembleMixal(byId('mp-div').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    expect(fromBig(m, 1100, 3, 10000), 123456789 ~/ 7);
    expect(m.memory[program.symbols['REMOUT']!].value, 123456789 % 7);
  });

  test('radix conversion of 12345 to decimal digits', () {
    final program = assembleMixal(byId('radix-conversion').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    final base = program.symbols['DIG']!;
    final n = m.memory[program.symbols['NDIG']!].value;
    expect([for (var i = 0; i < n; i++) m.memory[base + i].value],
        [5, 4, 3, 2, 1]);
  });

  test('polynomial derivative of 3x^3+2x^2+5x+7', () {
    final m = runProgram('poly-derivative');
    expect([for (var i = 0; i < 3; i++) m.memory[1100 + i].value], [5, 4, 9]);
  });

  test('polynomial division (x^3-6x^2+11x-6)/(x-1)', () {
    final m = runProgram('poly-division');
    expect([for (var i = 0; i < 3; i++) m.memory[1200 + i].value], [6, -5, 1]);
    expect(m.memory[1300].value, 0);
  });

  test('maximum subroutine returns 999 at index 5', () {
    final program = assembleMixal(byId('max-subroutine').source);
    final m = MixMachine()..loadProgram(program);
    m.run();
    final ans = program.symbols['ANS']!;
    final ansi = program.symbols['ANSI']!;
    expect(m.memory[ans].value, 999);
    expect(m.memory[ansi].value, 5);
  });
}
