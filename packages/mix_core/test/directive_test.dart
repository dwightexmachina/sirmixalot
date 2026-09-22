import 'package:mix_core/mix_core.dart';
import 'package:test/test.dart';

void main() {
  test('EQU resolves the symbol value', () {
    final e = explainDirective('EQU',
        label: 'X', operand: '1000', symbols: {'X': 1000})!;
    expect(e.op, 'EQU');
    expect(e.name, contains('equate'));
    expect(e.body, contains('X'));
    expect(e.detail, 'X = 1000');
  });

  test('ORIG mentions the target address', () {
    final e = explainDirective('ORIG', operand: '3000')!;
    expect(e.body, contains('3000'));
    expect(e.detail, isNull);
  });

  test('END reports the entry point', () {
    final e = explainDirective('END', operand: 'START', start: 3010)!;
    expect(e.detail, contains('3010'));
  });

  test('non-directives return null', () {
    expect(explainDirective('LDA'), isNull);
    expect(explainDirective('CON'), isNull);
    expect(explainDirective(''), isNull);
  });

  test('EQU without a resolvable symbol still explains, minus the detail', () {
    final e = explainDirective('EQU', label: 'Y', symbols: const {})!;
    expect(e.detail, isNull);
    expect(e.body, isNotEmpty);
  });
}
