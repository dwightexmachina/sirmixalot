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
