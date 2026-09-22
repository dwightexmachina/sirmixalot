import 'assembler.dart';
import 'devices.dart';
import 'errors.dart';
import 'float.dart';
import 'instruction.dart';
import 'word.dart';

enum MixComparison { less, equal, greater }

/// What one executed instruction did — the event trace the UI animates from.
class StepResult {
  /// Address of the executed instruction.
  final int address;
  final MixWord word;

  /// Time this instruction took, in u.
  final int cost;
  final bool jumped;
  final List<int> memReads;
  final List<int> memWrites;

  StepResult({
    required this.address,
    required this.word,
    required this.cost,
    required this.jumped,
    required this.memReads,
    required this.memWrites,
  });
}

class MixMachine {
  static const int memorySize = 4000;

  /// 64^2: one more than the maximum magnitude of rI1-rI6 and rJ.
  static const int indexModulus = 4096;

  final List<MixWord> memory = List.filled(memorySize, MixWord.zero);
  MixWord rA = MixWord.zero;
  MixWord rX = MixWord.zero;

  /// rI1..rI6 (index 0 is rI1), stored as full words whose top three bytes
  /// are always zero.
  final List<MixWord> rI = List.filled(6, MixWord.zero);

  /// Jump register: sign always +, magnitude < 4096.
  MixWord rJ = MixWord.zero;

  bool overflow = false;
  MixComparison comparison = MixComparison.equal;

  /// Fuzz used by FCMP (a floating-point word); +0 means exact comparison.
  MixWord floatEpsilon = MixWord.zero;
  int pc = 0;
  bool halted = false;

  /// Elapsed simulated time in u (MIX time units).
  int cycles = 0;
  int instructions = 0;

  final Map<int, MixDevice> devices = {};

  /// Words per tape block. MIX uses 100; a smaller value keeps tape-sorting
  /// demos legible (the multi-pass merge algorithm is identical either way).
  MixMachine({int tapeBlock = 1}) {
    for (var t = 0; t < 8; t++) {
      devices[t] = MixTape(blockSize: tapeBlock);
    }
    devices[16] = CardReader();
    devices[17] = CardPunch();
    devices[18] = LinePrinter();
  }

  LinePrinter get printer => devices[18] as LinePrinter;
  CardReader get cardReader => devices[16] as CardReader;
  CardPunch get cardPunch => devices[17] as CardPunch;
  MixTape tape(int n) => devices[n] as MixTape;

  void loadProgram(AssembledProgram program) {
    program.words.forEach((addr, w) => memory[addr] = w);
    pc = program.start;
    halted = false;
  }

  /// Runs until HLT; throws if the limit is exceeded (runaway program).
  void run({int maxInstructions = 1000000}) {
    var n = 0;
    while (!halted) {
      if (n++ >= maxInstructions) {
        throw MixRuntimeError(
            'exceeded $maxInstructions instructions without halting');
      }
      step();
    }
  }

  /// Executes one instruction and returns its event trace.
  StepResult step() {
    if (halted) throw MixRuntimeError('machine is halted');
    if (pc < 0 || pc >= memorySize) {
      throw MixRuntimeError('program counter out of range: $pc');
    }
    final at = pc;
    final w = memory[at];
    final ins = Instruction(w);
    final c = ins.c;
    final f = ins.f;
    var m = ins.aa;
    if (ins.i != 0) {
      if (ins.i > 6) {
        throw MixRuntimeError('invalid index byte ${ins.i} at $at');
      }
      m += rI[ins.i - 1].value;
    }

    var next = at + 1;
    var jumped = false;
    var cost = instructionCost(c, f);
    final reads = <int>[];
    final writes = <int>[];

    void checkMem(int a) {
      if (a < 0 || a >= memorySize) {
        throw MixRuntimeError('memory address out of range: $a (at $at)');
      }
    }

    MixWord readMem() {
      checkMem(m);
      reads.add(m);
      return memory[m];
    }

    void writeField(MixWord source) {
      checkMem(m);
      writes.add(m);
      memory[m] = memory[m].storing(source, f);
    }

    void jumpTo(int target, {bool saveJ = true}) {
      checkMem(target);
      if (saveJ) rJ = _jWord(next, at);
      next = target;
      jumped = true;
    }

    if (c == 0) {
      // NOP
    } else if (c >= 1 && c <= 4) {
      if (f == 6) {
        // Floating point: FADD / FSUB / FMUL / FDIV operate on whole words.
        final vword = readMem();
        final r = switch (c) {
          1 => mixFloatAdd(rA, vword),
          2 => mixFloatAdd(rA, vword, subtract: true),
          3 => mixFloatMul(rA, vword),
          _ => mixFloatDiv(rA, vword),
        };
        rA = r.word;
        if (r.overflow) overflow = true;
      } else {
        final v = readMem().field(f);
        switch (c) {
          case 1: // ADD
            rA = _added(rA, v.value);
          case 2: // SUB
            rA = _added(rA, -v.value);
          case 3: // MUL: 10-byte product in rA:rX, both get the product sign.
            final s = rA.sign * v.sign;
            final p = rA.magnitude * v.magnitude;
            rA = MixWord.fromMagnitude(s, p ~/ MixWord.wordModulus);
            rX = MixWord.fromMagnitude(s, p % MixWord.wordModulus);
          case 4: // DIV: rA:rX / V -> quotient rA, remainder rX.
            if (v.magnitude == 0 || rA.magnitude >= v.magnitude) {
              // Quotient would not fit; TAOCP leaves the registers undefined.
              overflow = true;
            } else {
              final dividend =
                  rA.magnitude * MixWord.wordModulus + rX.magnitude;
              final quotientSign = rA.sign * v.sign;
              final remainderSign = rA.sign;
              final q = dividend ~/ v.magnitude;
              final r = dividend % v.magnitude;
              rA = MixWord.fromMagnitude(quotientSign, q);
              rX = MixWord.fromMagnitude(remainderSign, r);
            }
        }
      }
    } else if (c == 5) {
      switch (f) {
        case 0: // NUM: rA:rX character digits -> number in rA.
          var val = 0;
          for (final b in [...rA.bytes, ...rX.bytes]) {
            val = val * 10 + (b % 10);
          }
          if (val >= MixWord.wordModulus) {
            overflow = true;
            val %= MixWord.wordModulus;
          }
          rA = MixWord.fromMagnitude(rA.sign, val);
        case 1: // CHAR: |rA| -> 10 digit characters in rA:rX.
          final digits = rA.magnitude.toString().padLeft(10, '0');
          List<int> codes(String s) =>
              s.split('').map((d) => 30 + int.parse(d)).toList();
          rA = MixWord(rA.sign, codes(digits.substring(0, 5)));
          rX = MixWord(rX.sign, codes(digits.substring(5)));
        case 2: // HLT
          halted = true;
        default:
          throw MixRuntimeError('invalid F=$f for C=5 at $at');
      }
    } else if (c == 6) {
      if (m < 0) throw MixRuntimeError('negative shift count $m at $at');
      switch (f) {
        case 0: // SLA
          final k = m > 5 ? 5 : m;
          rA = MixWord(rA.sign, [...rA.bytes.sublist(k), ...List.filled(k, 0)]);
        case 1: // SRA
          final k = m > 5 ? 5 : m;
          rA = MixWord(
              rA.sign, [...List.filled(k, 0), ...rA.bytes.sublist(0, 5 - k)]);
        case 2: // SLAX
        case 3: // SRAX
        case 4: // SLC
        case 5: // SRC
          final both = [...rA.bytes, ...rX.bytes];
          List<int> res;
          if (f == 2) {
            final k = m > 10 ? 10 : m;
            res = [...both.sublist(k), ...List.filled(k, 0)];
          } else if (f == 3) {
            final k = m > 10 ? 10 : m;
            res = [...List.filled(k, 0), ...both.sublist(0, 10 - k)];
          } else if (f == 4) {
            final k = m % 10;
            res = [...both.sublist(k), ...both.sublist(0, k)];
          } else {
            final k = m % 10;
            res = [...both.sublist(10 - k), ...both.sublist(0, 10 - k)];
          }
          rA = MixWord(rA.sign, res.sublist(0, 5));
          rX = MixWord(rX.sign, res.sublist(5));
        default:
          throw MixRuntimeError('invalid F=$f for C=6 at $at');
      }
    } else if (c == 7) {
      // MOVE F words from M to the address in rI1; copies one word at a
      // time, so overlapping moves repeat words (as the book specifies).
      final count = f;
      final dest = rI[0].value;
      for (var k = 0; k < count; k++) {
        checkMem(m + k);
        checkMem(dest + k);
        reads.add(m + k);
        writes.add(dest + k);
        memory[dest + k] = memory[m + k];
      }
      if (count > 0) _setIndexValue(0, dest + count, at);
    } else if (c <= 15) {
      _setReg(c - 8, readMem().field(f), at);
    } else if (c <= 23) {
      _setReg(c - 16, readMem().field(f).negated, at);
    } else if (c <= 31) {
      writeField(_getReg(c - 24));
    } else if (c == 32) {
      writeField(rJ);
    } else if (c == 33) {
      writeField(MixWord.zero);
    } else if (c == 34) {
      if (_device(f, at).busy) jumpTo(m);
    } else if (c == 35) {
      _device(f, at).control(this, m);
    } else if (c == 36) {
      final d = _device(f, at);
      checkMem(m);
      checkMem(m + d.blockSize - 1);
      d.input(this, m);
      for (var k = 0; k < d.blockSize; k++) {
        writes.add(m + k);
      }
    } else if (c == 37) {
      final d = _device(f, at);
      checkMem(m);
      checkMem(m + d.blockSize - 1);
      d.output(this, m);
      for (var k = 0; k < d.blockSize; k++) {
        reads.add(m + k);
      }
    } else if (c == 38) {
      if (!_device(f, at).busy) jumpTo(m);
    } else if (c == 39) {
      switch (f) {
        case 0:
          jumpTo(m);
        case 1: // JSJ: jump without touching rJ.
          jumpTo(m, saveJ: false);
        case 2: // JOV
          if (overflow) {
            overflow = false;
            jumpTo(m);
          }
        case 3: // JNOV
          if (overflow) {
            overflow = false;
          } else {
            jumpTo(m);
          }
        case 4:
          if (comparison == MixComparison.less) jumpTo(m);
        case 5:
          if (comparison == MixComparison.equal) jumpTo(m);
        case 6:
          if (comparison == MixComparison.greater) jumpTo(m);
        case 7:
          if (comparison != MixComparison.less) jumpTo(m);
        case 8:
          if (comparison != MixComparison.equal) jumpTo(m);
        case 9:
          if (comparison != MixComparison.greater) jumpTo(m);
        default:
          throw MixRuntimeError('invalid F=$f for C=39 at $at');
      }
    } else if (c <= 47) {
      final v = _getReg(c - 40).value;
      final go = switch (f) {
        0 => v < 0,
        1 => v == 0,
        2 => v > 0,
        3 => v >= 0,
        4 => v != 0,
        5 => v <= 0,
        _ => throw MixRuntimeError('invalid F=$f for C=$c at $at'),
      };
      if (go) jumpTo(m);
    } else if (c <= 55) {
      final r = c - 48;
      switch (f) {
        case 0: // INC
          _incReg(r, m, at);
        case 1: // DEC
          _incReg(r, -m, at);
        case 2: // ENT: M = 0 takes the sign of the instruction itself.
          final s = m > 0 ? 1 : (m < 0 ? -1 : w.sign);
          _setReg(r, MixWord.fromMagnitude(s, m.abs()), at);
        case 3: // ENN
          final s = m > 0 ? -1 : (m < 0 ? 1 : -w.sign);
          _setReg(r, MixWord.fromMagnitude(s, m.abs()), at);
        default:
          throw MixRuntimeError('invalid F=$f for C=$c at $at');
      }
    } else {
      if (f == 6) {
        // FCMP: floating-point comparison within the fuzz [floatEpsilon].
        final cmp = mixFloatCompare(_getReg(c - 56), readMem(), floatEpsilon);
        comparison = cmp < 0
            ? MixComparison.less
            : (cmp > 0 ? MixComparison.greater : MixComparison.equal);
      } else {
        final a = _getReg(c - 56).field(f).value;
        final b = readMem().field(f).value;
        comparison = a < b
            ? MixComparison.less
            : (a > b ? MixComparison.greater : MixComparison.equal);
      }
    }

    cycles += cost;
    instructions++;
    pc = next;
    return StepResult(
      address: at,
      word: w,
      cost: cost,
      jumped: jumped,
      memReads: reads,
      memWrites: writes,
    );
  }

  MixWord _getReg(int r) => r == 0 ? rA : (r == 7 ? rX : rI[r - 1]);

  void _setReg(int r, MixWord w, int at) {
    if (r == 0) {
      rA = w;
    } else if (r == 7) {
      rX = w;
    } else {
      if (w.bytes[0] != 0 || w.bytes[1] != 0 || w.bytes[2] != 0) {
        throw MixRuntimeError('value too large for index register I$r at $at');
      }
      rI[r - 1] = w;
    }
  }

  void _setIndexValue(int i, int value, int at) {
    if (value.abs() >= indexModulus) {
      throw MixRuntimeError('index register I${i + 1} overflow at $at');
    }
    rI[i] = MixWord.fromValue(value);
  }

  void _incReg(int r, int delta, int at) {
    final reg = _getReg(r);
    if (r == 0 || r == 7) {
      final w = _added(reg, delta);
      _setReg(r, w, at);
    } else {
      final sum = reg.value + delta;
      if (sum.abs() >= indexModulus) {
        // TAOCP calls this undefined; failing loudly beats silent wrap.
        throw MixRuntimeError('index register I$r overflow at $at');
      }
      final s = sum == 0 ? reg.sign : (sum < 0 ? -1 : 1);
      _setReg(r, MixWord.fromMagnitude(s, sum.abs()), at);
    }
  }

  /// Adds [v] to [reg] with MIX overflow semantics: wrap modulo 64^5 setting
  /// the overflow toggle; a zero result keeps the register's old sign.
  MixWord _added(MixWord reg, int v) {
    final sum = reg.value + v;
    var mag = sum.abs();
    if (mag >= MixWord.wordModulus) {
      overflow = true;
      mag %= MixWord.wordModulus;
    }
    final s = sum == 0 ? reg.sign : (sum < 0 ? -1 : 1);
    return MixWord.fromMagnitude(s, mag);
  }

  MixWord _jWord(int addr, int at) {
    if (addr < 0 || addr >= indexModulus) {
      throw MixRuntimeError('rJ value out of range: $addr (at $at)');
    }
    return MixWord.fromMagnitude(1, addr);
  }

  MixDevice _device(int n, int at) {
    final d = devices[n];
    if (d == null) throw MixRuntimeError('no device $n (at $at)');
    return d;
  }

}
