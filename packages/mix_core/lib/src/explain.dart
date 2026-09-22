import 'instruction.dart';
import 'machine.dart';
import 'word.dart';

/// A human-readable explanation of one instruction word, for tooltips.
class InstructionExplanation {
  /// Disassembled form, e.g. 'JGE 3007'.
  final String mnemonic;

  /// The book's English name, e.g. 'jump if greater or equal'.
  final String name;

  /// One-line decode, e.g. 'C=39 (jump family) · F=7, selects JGE · A=3007 · no index'.
  final String fields;

  /// A paragraph explaining what this specific instruction does.
  final String body;

  /// Prediction for this very execution; only set when the explained cell is
  /// the one the machine will execute next.
  final String? rightNow;

  final int cost;
  final List<String> chips;

  InstructionExplanation({
    required this.mnemonic,
    required this.name,
    required this.fields,
    required this.body,
    this.rightNow,
    required this.cost,
    required this.chips,
  });
}

/// A plain-English explanation of an assembler directive (EQU/ORIG/END),
/// which produces no instruction word.
class DirectiveExplanation {
  final String op;
  final String name;
  final String body;

  /// A resolved fact, e.g. 'X = 1000' or 'execution starts at 3010'.
  final String? detail;

  DirectiveExplanation({
    required this.op,
    required this.name,
    required this.body,
    this.detail,
  });
}

/// Explains an assembler directive line. Returns null for anything that is
/// not a word-less directive (machine ops and CON/ALF emit words and are
/// explained by [explainInstruction] / shown as data instead).
DirectiveExplanation? explainDirective(
  String op, {
  String? label,
  String? operand,
  Map<String, int> symbols = const {},
  int? start,
}) {
  switch (op) {
    case 'EQU':
      final v = label == null ? null : symbols[label];
      return DirectiveExplanation(
        op: 'EQU',
        name: 'equate — an assembly-time definition',
        body:
            'Binds the symbol${label == null ? '' : ' $label'} to a constant '
            'value while the program is being assembled. It emits no '
            'instruction and takes up no memory — every later use of the '
            'symbol is simply shorthand for this number.',
        detail: (label != null && v != null) ? '$label = $v' : null,
      );
    case 'ORIG':
      return DirectiveExplanation(
        op: 'ORIG',
        name: 'set the origin',
        body:
            'Moves the assembler\'s location counter${operand == null ? '' : ' to $operand'}, '
            'so the lines that follow are placed into memory starting at that '
            'address. Programs use it to separate code from data.',
      );
    case 'END':
      return DirectiveExplanation(
        op: 'END',
        name: 'end of assembly',
        body:
            'Marks the end of the source and names the entry point where the '
            'machine begins executing. Any =literal= constants used anywhere '
            'in the program are assembled into memory just past this point.',
        detail: start != null ? 'execution starts at $start' : null,
      );
    default:
      return null;
  }
}

const _regNames = ['rA', 'rI1', 'rI2', 'rI3', 'rI4', 'rI5', 'rI6', 'rX'];

String _deviceName(int f) {
  if (f <= 7) return 'tape $f';
  if (f <= 15) return 'disk ${f - 8}';
  return switch (f) {
    16 => 'the card reader',
    17 => 'the card punch',
    18 => 'the line printer',
    19 => 'the typewriter',
    20 => 'the paper tape',
    _ => 'unit $f',
  };
}

/// Explains [word] as an instruction. When [machine] and [address] are given
/// and `address == machine.pc`, a "right now" prediction is added using the
/// live machine state.
InstructionExplanation explainInstruction(
  MixWord word, {
  MixMachine? machine,
  int? address,
}) {
  final ins = Instruction(word);
  final c = ins.c;
  final f = ins.f;
  final l = ins.fieldL;
  final r = ins.fieldR;

  // Non-null exactly when this cell is the next instruction to execute:
  // only then are live-state predictions truthful.
  final MixMachine? mm = (machine != null &&
          address != null &&
          address == machine.pc &&
          !machine.halted)
      ? machine
      : null;

  // How to talk about M.
  final indexed = ins.i >= 1 && ins.i <= 6;
  int? m;
  String mText;
  if (!indexed) {
    m = ins.aa;
    mText = '${ins.aa}';
  } else if (mm != null) {
    m = ins.aa + mm.rI[ins.i - 1].value;
    mText = '${ins.aa} + rI${ins.i} (${mm.rI[ins.i - 1].value}) = $m';
  } else {
    mText = '${ins.aa} + rI${ins.i}';
  }

  final fieldWhole = l == 0 && r == 5;
  final fieldDesc = fieldWhole ? 'the whole word' : 'field ($l:$r)';
  final next = address != null ? '${address + 1}' : 'the next address';

  String family;
  String fMeaning;
  String name = '';
  String body;
  String? rightNow;
  final chips = <String>[];

  // Reads memory[m] safely for predictions.
  MixWord? cellAtM() {
    if (mm == null || m == null) return null;
    final a = m;
    if (a < 0 || a >= MixMachine.memorySize) return null;
    return mm.memory[a];
  }

  String outOfRange() =>
      'M = $m is outside memory (0–3999): executing this will stop with an error.';

  switch (c) {
    case 0:
      family = 'no-op';
      fMeaning = 'ignored';
      name = 'no operation';
      body = 'Does nothing at all for one cycle. '
          'Sometimes used to reserve a cell that will be patched later.';

    case 1 || 2:
      family = 'arithmetic';
      final add = c == 1;
      if (f == 6) {
        name = add ? 'floating add' : 'floating subtract';
        fMeaning = 'selects the floating-point variant';
        body = 'The floating-point variant of ${add ? 'ADD' : 'SUB'} '
            '(TAOCP 4.2): reads the word at $mText as a MIX floating-point '
            'number and ${add ? 'adds it to' : 'subtracts it from'} rA, '
            'normalizing and rounding the result. Exponent overflow lights '
            'the overflow lamp.';
      } else {
        name = add ? 'add' : 'subtract';
        fMeaning = 'field ($l:$r)';
        body =
            'Fetches $fieldDesc of the word at address $mText and ${add ? 'adds it to' : 'subtracts it from'} rA. '
            'If the result needs more than five bytes, the overflow lamp '
            'lights and only the low five bytes are kept; a result of zero '
            'keeps rA\'s old sign.';
        chips.add('may set overflow');
        if (mm != null) {
          final cell = cellAtM();
          if (cell == null) {
            rightNow = outOfRange();
          } else {
            final v = cell.field(f).value;
            final sum = mm.rA.value + (add ? v : -v);
            final wraps = sum.abs() >= MixWord.wordModulus;
            rightNow =
                'rA (${mm.rA.value}) ${add ? '+' : '−'} $v → rA will become '
                '${wraps ? '${sum.abs() % MixWord.wordModulus} with the overflow lamp lit' : '$sum'}.';
          }
        }
      }

    case 3:
      family = 'arithmetic';
      if (f == 6) {
        name = 'floating multiply';
        fMeaning = 'selects the floating-point variant';
        body = 'Multiplies rA by the MIX floating-point number at $mText '
            '(TAOCP 4.2), leaving the normalized product in rA.';
      } else {
        name = 'multiply';
        fMeaning = 'field ($l:$r)';
        body =
            'Multiplies rA by $fieldDesc of the word at $mText. The ten-byte '
            'product fills rA (high half) and rX (low half), both taking the '
            'product\'s sign. At 10u it costs five times an ADD — which is '
            'why Knuth\'s programs work so hard to avoid it.';
        chips.add('writes rA and rX');
        if (mm != null) {
          final cell = cellAtM();
          if (cell == null) {
            rightNow = outOfRange();
          } else {
            final v = cell.field(f);
            final p = mm.rA.magnitude * v.magnitude;
            final s = mm.rA.sign * v.sign < 0 ? '-' : '+';
            rightNow = 'rA (${mm.rA.value}) × ${v.value} → '
                'rA:rX will hold $s$p.';
          }
        }
      }

    case 4:
      family = 'arithmetic';
      if (f == 6) {
        name = 'floating divide';
        fMeaning = 'selects the floating-point variant';
        body = 'Divides rA by the MIX floating-point number at $mText '
            '(TAOCP 4.2), leaving the normalized quotient in rA. Division by '
            'zero lights the overflow lamp.';
      } else {
        name = 'divide';
        fMeaning = 'field ($l:$r)';
        body =
            'Divides the ten-byte value rA:rX by $fieldDesc of the word at '
            '$mText: the quotient lands in rA, the remainder in rX (keeping '
            'rA\'s old sign). Dividing by zero, or a quotient too big for '
            'rA, lights the overflow lamp instead of storing anything.';
        chips.add('writes rA and rX');
        chips.add('may set overflow');
        if (mm != null) {
          final cell = cellAtM();
          if (cell == null) {
            rightNow = outOfRange();
          } else {
            final v = cell.field(f);
            if (v.magnitude == 0 || mm.rA.magnitude >= v.magnitude) {
              rightNow = v.magnitude == 0
                  ? 'The divisor is zero — only the overflow lamp will light.'
                  : 'The quotient would not fit in rA — only the overflow '
                      'lamp will light.';
            } else {
              final dividend =
                  mm.rA.magnitude * MixWord.wordModulus + mm.rX.magnitude;
              rightNow =
                  '$dividend ÷ ${v.magnitude} → quotient ${dividend ~/ v.magnitude} '
                  'in rA, remainder ${dividend % v.magnitude} in rX.';
            }
          }
        }
      }

    case 5:
      family = 'conversion / control';
      switch (f) {
        case 0:
          name = 'convert to numeric';
          fMeaning = 'selects NUM';
          body =
              'Reads the ten bytes of rA:rX as decimal digit characters '
              '(each byte mod 10 is a digit) and packs their numeric value '
              'into rA. The inverse of CHAR — how MIX turns typed-in text '
              'into a number it can do arithmetic on.';
        case 1:
          name = 'convert to characters';
          fMeaning = 'selects CHAR';
          body =
              'Spreads |rA| out as ten decimal digits in MIX character code '
              '(codes 30–39), filling rA and rX. This is how a number gets '
              'ready for the line printer.';
          chips.add('writes rA and rX');
        case 2:
          name = 'halt';
          fMeaning = 'selects HLT';
          body =
              'Stops the machine. The counters freeze where they are; RESET '
              'reloads the program from scratch.';
        default:
          name = 'invalid';
          fMeaning = 'unrecognized';
          body = 'F=$f is not a valid variant for C=5 — executing this '
              'stops with an error.';
      }

    case 6:
      family = 'shift';
      const shiftNames = [
        'shift rA left',
        'shift rA right',
        'shift rA:rX left',
        'shift rA:rX right',
        'circulate rA:rX left',
        'circulate rA:rX right',
      ];
      if (f > 5) {
        name = 'invalid shift';
        fMeaning = 'unrecognized';
        body =
            'F=$f is not a valid shift — executing this stops with an error.';
      } else {
        name = shiftNames[f];
        fMeaning = 'selects ${['SLA', 'SRA', 'SLAX', 'SRAX', 'SLC', 'SRC'][f]}';
        final both = f >= 2;
        final circular = f >= 4;
        body =
            'Slides the bytes of ${both ? 'rA and rX together (ten bytes)' : 'rA (five bytes)'} '
            '${f.isEven ? 'left' : 'right'} by M = $mText positions. '
            '${circular ? 'Bytes pushed off one end reappear at the other.' : 'Vacated positions fill with zeros; bytes pushed off the end are lost.'} '
            'The signs never move.';
      }

    case 7:
      family = 'block move';
      fMeaning = 'word count';
      name = 'move words';
      body =
          'Copies F = $f consecutive words, starting at address $mText, to '
          'the address held in rI1, one word at a time, and advances rI1 '
          'past the copied block. Cost grows with the count: 1 + 2F u.';
      if (mm != null) {
        rightNow =
            'Will copy $f word${f == 1 ? '' : 's'} from $m to ${mm.rI[0].value}, '
            'leaving rI1 = ${mm.rI[0].value + f}.';
      }

    case >= 8 && <= 23:
      final negate = c >= 16;
      final reg = _regNames[c - (negate ? 16 : 8)];
      family = negate ? 'load negative' : 'load';
      fMeaning = 'field ($l:$r)';
      name = 'load $reg${negate ? ', negated' : ''}';
      body =
          'Copies $fieldDesc of the word at address $mText into $reg'
          '${negate ? ' with the sign reversed' : ''}, replacing its old '
          'contents.'
          '${!fieldWhole && l >= 1 ? ' Because the field excludes the sign, the value arrives positive and right-justified.' : ''}'
          '${reg.startsWith('rI') ? ' Index registers hold only a sign and two bytes, so the value must fit in ±4095.' : ''}';
      if (mm != null) {
        final cell = cellAtM();
        if (cell == null) {
          rightNow = outOfRange();
        } else {
          final v = cell.field(f);
          final value = negate ? -v.value : v.value;
          final tooBig = reg.startsWith('rI') && value.abs() > 4095;
          rightNow = tooBig
              ? 'Cell $m holds $value — too large for $reg, so this will '
                  'stop with an error.'
              : 'Cell $m holds ${cell.value}, so $reg will become $value.';
        }
      }

    case >= 24 && <= 31:
      final reg = _regNames[c - 24];
      family = 'store';
      fMeaning = 'field ($l:$r)';
      name = 'store $reg';
      body =
          'Writes $reg into $fieldDesc of memory cell $mText. Only those '
          'bytes change — the rest of the word keeps its old contents'
          '${l >= 1 ? ', including the sign' : ''}. When the field is '
          'narrower than the register, the rightmost bytes are used.';
      if (mm != null) {
        final cell = cellAtM();
        if (cell == null) {
          rightNow = outOfRange();
        } else {
          final regWord = switch (c - 24) {
            0 => mm.rA,
            7 => mm.rX,
            final i => mm.rI[i - 1],
          };
          rightNow =
              'Cell $m [$cell] will become [${cell.storing(regWord, f)}].';
        }
      }

    case 32:
      family = 'store';
      fMeaning = 'field ($l:$r)';
      name = 'store the jump register';
      body =
          'Writes rJ — the return address saved by the most recent jump — '
          'into field ($l:$r) of cell $mText. This is the classic MIX '
          'subroutine idiom: aimed at the address field of an exit JMP, it '
          'rewrites that instruction so the subroutine knows where to '
          'return. Self-modifying code, by design.';
      chips.add('self-modifying idiom');
      if (mm != null) {
        final cell = cellAtM();
        rightNow = cell == null
            ? outOfRange()
            : 'rJ = ${mm.rJ.value}, so cell $m will become '
                '[${cell.storing(mm.rJ, f)}].';
      }

    case 33:
      family = 'store';
      fMeaning = 'field ($l:$r)';
      name = 'store zero';
      body =
          'Clears $fieldDesc of cell $mText to +0, leaving the rest of the '
          'word untouched.';

    case 34 || 38:
      final busySense = c == 34;
      family = 'I/O';
      fMeaning = 'unit ${ins.f}';
      name = busySense ? 'jump if device busy' : 'jump if device ready';
      body =
          'Checks whether ${_deviceName(ins.f)} is still working on its last '
          'transfer and jumps to $mText if it is ${busySense ? 'busy' : 'ready'}. '
          'In this simulator devices finish instantly, so '
          '${busySense ? 'JBUS never jumps — the classic "JBUS *" wait-loop falls straight through' : 'JRED always jumps'}.';

    case 35:
      family = 'I/O';
      fMeaning = 'unit ${ins.f}';
      name = 'device control';
      body =
          'Sends a control command to ${_deviceName(ins.f)}. For the line '
          'printer, M = 0 skips the paper to the top of the next page; for '
          'tapes it would rewind or skip blocks.';

    case 36 || 37:
      final input = c == 36;
      family = 'I/O';
      fMeaning = 'unit ${ins.f}';
      name = input ? 'input one block' : 'output one block';
      body = input
          ? 'Reads one block from ${_deviceName(ins.f)} into memory starting '
              'at address $mText (16 words for cards, 24 for a printer line, '
              '100 for tape).'
          : 'Writes one block of memory, starting at address $mText, to '
              '${_deviceName(ins.f)} (a card is 16 words; a printed line is '
              '24 words = 120 characters).';

    case 39:
      family = 'jump family';
      const jumpInfo = [
        ('JMP', 'jump', ''),
        ('JSJ', 'jump, saving nothing', ''),
        ('JOV', 'jump on overflow', ''),
        ('JNOV', 'jump on no overflow', ''),
        ('JL', 'jump if less', 'LESS'),
        ('JE', 'jump if equal', 'EQUAL'),
        ('JG', 'jump if greater', 'GREATER'),
        ('JGE', 'jump if greater or equal', 'GREATER or EQUAL'),
        ('JNE', 'jump if not equal', 'anything but EQUAL'),
        ('JLE', 'jump if less or equal', 'LESS or EQUAL'),
      ];
      if (f > 9) {
        name = 'invalid jump';
        fMeaning = 'unrecognized';
        body =
            'F=$f is not a valid jump — executing this stops with an error.';
      } else {
        final (mn, longName, cond) = jumpInfo[f];
        name = longName;
        fMeaning = 'selects $mn';
        if (f == 0) {
          body =
              'Jumps to address $mText unconditionally, saving the address '
              'of the next instruction ($next) in rJ so a subroutine can '
              'find its way back.';
          chips.add('sets rJ');
        } else if (f == 1) {
          body =
              'Jumps to address $mText WITHOUT touching rJ — used to leave '
              'a subroutine sideways while keeping its return address intact.';
        } else if (f == 2 || f == 3) {
          body =
              'Checks the overflow lamp. ${f == 2 ? 'If it is on' : 'If it is off'}, '
              'jumps to $mText (saving $next in rJ)'
              '${f == 2 ? ' and switches the lamp off' : '; if the lamp is on it is switched off and execution continues'}. '
              'Either way the lamp ends up off.';
          chips.add('sets rJ on jump');
          if (mm != null) {
            final taken = f == 2 ? mm.overflow : !mm.overflow;
            rightNow = 'The overflow lamp is ${mm.overflow ? 'ON' : 'OFF'} — '
                'this jump will ${taken ? '' : 'not '}be taken.';
          }
        } else {
          body =
              'Checks the comparison indicator — the L / E / G lamp set by '
              'the most recent compare instruction. If it reads $cond, the '
              'machine jumps to address $mText and records the return '
              'address $next in rJ. Otherwise nothing happens and execution '
              'falls through to $next.';
          chips.add('sets rJ on jump');
          if (mm != null) {
            final ind = mm.comparison;
            final taken = switch (f) {
              4 => ind == MixComparison.less,
              5 => ind == MixComparison.equal,
              6 => ind == MixComparison.greater,
              7 => ind != MixComparison.less,
              8 => ind != MixComparison.equal,
              _ => ind != MixComparison.greater,
            };
            rightNow =
                'The indicator reads ${ind.name.toUpperCase()} — this jump '
                'will ${taken ? '' : 'not '}be taken.';
          }
        }
      }

    case >= 40 && <= 47:
      final reg = _regNames[c - 40];
      family = 'register jump';
      const conds = [
        ('negative', 'is negative'),
        ('zero', 'is zero'),
        ('positive', 'is positive'),
        ('nonnegative', 'is zero or positive'),
        ('nonzero', 'is anything but zero'),
        ('nonpositive', 'is zero or negative'),
      ];
      if (f > 5) {
        name = 'invalid jump';
        fMeaning = 'unrecognized';
        body =
            'F=$f is not a valid condition — executing this stops with an error.';
      } else {
        name = 'jump if $reg ${conds[f].$1}';
        fMeaning = 'selects the "${conds[f].$1}" test';
        body =
            'Examines $reg: if its value ${conds[f].$2}, jumps to address '
            '$mText (saving $next in rJ); otherwise execution continues. '
            'Note that −0 counts as zero here.';
        chips.add('sets rJ on jump');
        if (mm != null) {
          final v = (c == 40
                  ? mm.rA
                  : c == 47
                      ? mm.rX
                      : mm.rI[c - 41])
              .value;
          final taken = switch (f) {
            0 => v < 0,
            1 => v == 0,
            2 => v > 0,
            3 => v >= 0,
            4 => v != 0,
            _ => v <= 0,
          };
          rightNow =
              '$reg = $v — this jump will ${taken ? '' : 'not '}be taken.';
        }
      }

    case >= 48 && <= 55:
      final reg = _regNames[c - 48];
      family = 'address transfer';
      const ops = ['INC', 'DEC', 'ENT', 'ENN'];
      if (f > 3) {
        name = 'invalid';
        fMeaning = 'unrecognized';
        body =
            'F=$f is not a valid variant — executing this stops with an error.';
      } else {
        fMeaning = 'selects ${ops[f]}${reg.substring(1)}';
        switch (f) {
          case 0 || 1:
            final inc = f == 0;
            name = '${inc ? 'increase' : 'decrease'} $reg';
            body =
                '${inc ? 'Adds' : 'Subtracts'} M = $mText ${inc ? 'to' : 'from'} $reg. '
                'No memory is touched — the address itself is the operand. '
                '${reg == 'rA' || reg == 'rX' ? 'Overflow wraps and lights the lamp, like ADD.' : 'Index registers must stay within ±4095.'}';
            if (mm != null && m != null) {
              final v = (c == 48
                      ? mm.rA
                      : c == 55
                          ? mm.rX
                          : mm.rI[c - 49])
                  .value;
              rightNow =
                  '$reg = $v, so it will become ${inc ? v + m : v - m}.';
            }
          default:
            final negate = f == 3;
            name = 'enter${negate ? ' negative' : ''} into $reg';
            body =
                'Sets $reg to ${negate ? '−M' : 'M'} directly — the address '
                'value $mText simply becomes the register\'s contents, with '
                'no memory access.'
                '${indexed ? ' With an index register in play, this doubles as a register-to-register copy.' : ''}';
            if (mm != null && m != null) {
              rightNow = '$reg will become ${negate ? -m : m}.';
            }
        }
      }

    default: // 56-63: comparisons
      final reg = _regNames[c - 56];
      family = 'comparison';
      if (f == 6) {
        name = 'floating compare';
        fMeaning = 'selects the floating-point variant';
        body = 'Compares $reg with the MIX floating-point number at $mText '
            '(TAOCP 4.2) and sets the L/E/G indicator. Numbers within the '
            'floating fuzz count as equal.';
      } else {
        name = 'compare $reg';
        fMeaning = 'field ($l:$r)';
        body =
            'Compares $fieldDesc of $reg with the same field of the word at '
            'address $mText and sets the L / E / G indicator accordingly. '
            'Neither the register nor memory changes, and +0 equals −0. '
            'A conditional jump usually follows to act on the result.';
        chips.add('sets L/E/G');
        if (mm != null) {
          final cell = cellAtM();
          if (cell == null) {
            rightNow = outOfRange();
          } else {
            final regWord = switch (c - 56) {
              0 => mm.rA,
              7 => mm.rX,
              final i => mm.rI[i - 1],
            };
            final a = regWord.field(f).value;
            final b = cell.field(f).value;
            final res = a < b ? 'LESS' : (a > b ? 'GREATER' : 'EQUAL');
            rightNow =
                '$reg ($a) vs cell $m ($b) → the indicator will read $res.';
          }
        }
      }
  }

  final cost = instructionCost(c, f);
  final indexPart = indexed
      ? 'index rI${ins.i}'
      : ins.i == 0
          ? 'no index'
          : 'invalid index ${ins.i}';

  return InstructionExplanation(
    mnemonic: disassemble(word),
    name: name,
    fields: 'C=$c ($family) · F=$f, $fMeaning · A=${ins.aa} · $indexPart',
    body: body,
    rightNow: rightNow,
    cost: cost,
    chips: ['cost ${cost}u', family, ...chips],
  );
}
