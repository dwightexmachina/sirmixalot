import 'char_code.dart';
import 'errors.dart';
import 'op_table.dart';
import 'word.dart';

/// The output of assembling MIXAL source.
class AssembledProgram {
  /// Assembled words by memory address.
  final Map<int, MixWord> words;

  /// Entry point (the END directive's operand).
  final int start;

  final Map<String, int> symbols;

  /// Memory address -> 1-based source line that produced it.
  final Map<int, int> sourceLines;

  AssembledProgram({
    required this.words,
    required this.start,
    required this.symbols,
    required this.sourceLines,
  });
}

/// Assembles MIXAL [source].
///
/// Supported: all machine ops, EQU/ORIG/CON/ALF/END, expressions with
/// + - * / // : evaluated left to right, `*` as the location counter, local
/// symbols (2H/2B/2F), literals (=W=), and future references (a future
/// reference must be a symbol standing alone, as in the book). Fields are
/// whitespace-separated; a line whose first column is `*` is a comment.
/// Text after the address field is a comment (an operand-less op cannot
/// carry a trailing comment).
AssembledProgram assembleMixal(String source) => _Assembler(source).assemble();

class _FutureRef implements Exception {
  final String symbol;
  _FutureRef(this.symbol);
}

class _Fixup {
  final int address;
  final String symbol;
  final int seq;
  final int line;
  _Fixup(this.address, this.symbol, this.seq, this.line);
}

class _LocalDef {
  final int seq;
  final int value;
  _LocalDef(this.seq, this.value);
}

class _Literal {
  final String expr;
  final int line;
  final List<int> refs = [];
  _Literal(this.expr, this.line);
}

final _symbolPattern = RegExp(r'^[A-Za-z0-9]*[A-Za-z][A-Za-z0-9]*$');
final _alnum = RegExp(r'[A-Za-z0-9]');

class _Assembler {
  final List<String> _lines;
  _Assembler(String source) : _lines = source.split('\n');

  final Map<String, int> _symbols = {};
  final Map<int, MixWord> _words = {};
  final Map<int, int> _sourceLines = {};
  final List<List<_LocalDef>> _locals = List.generate(10, (_) => []);
  final List<_Fixup> _fixups = [];
  final List<_Literal> _literals = [];
  int _loc = 0;
  int _seq = 0;
  int? _start;

  AssembledProgram assemble() {
    for (var n = 1; n <= _lines.length && _start == null; n++) {
      var raw = _lines[n - 1];
      if (raw.endsWith('\r')) raw = raw.substring(0, raw.length - 1);
      _statement(raw, n);
      _seq++;
    }
    if (_start == null) {
      throw MixAssemblyError('missing END directive', _lines.length);
    }
    return AssembledProgram(
      words: _words,
      start: _start!,
      symbols: _symbols,
      sourceLines: _sourceLines,
    );
  }

  void _statement(String raw, int line) {
    if (raw.trim().isEmpty) return;
    if (raw.startsWith('*')) return;

    var p = 0;
    String? label;
    if (!_isSpace(raw[0])) {
      final e = _scanToken(raw, 0);
      label = raw.substring(0, e);
      p = e;
    }
    p = _skipSpaces(raw, p);
    if (p >= raw.length) throw MixAssemblyError('missing operation', line);
    final opEnd = _scanToken(raw, p);
    final op = raw.substring(p, opEnd);

    if (op == 'ALF') {
      _defineHere(label, line);
      _emit(_alfWord(raw, opEnd, line), line);
      return;
    }

    final q = _skipSpaces(raw, opEnd);
    final operandEnd = q < raw.length ? _scanToken(raw, q) : q;
    final operand = raw.substring(q, operandEnd);

    switch (op) {
      case 'EQU':
        if (label == null) {
          throw MixAssemblyError('EQU requires a label', line);
        }
        _defineSymbol(label, _wValue(operand, line), line);
        return;
      case 'ORIG':
        _defineHere(label, line);
        final v = _wValue(operand, line);
        if (v < 0 || v >= 4000) {
          throw MixAssemblyError('ORIG out of range: $v', line);
        }
        _loc = v;
        return;
      case 'CON':
        _defineHere(label, line);
        final v = _wValue(operand, line);
        if (v.abs() >= MixWord.wordModulus) {
          throw MixAssemblyError('constant does not fit in a word: $v', line);
        }
        _emit(MixWord.fromValue(v), line);
        return;
      case 'END':
        _defineHere(label, line);
        _placeLiterals();
        _resolveFixups();
        _start = _wValue(operand, line);
        return;
    }

    final info = mixalOps[op];
    if (info == null) {
      throw MixAssemblyError("unknown operation '$op'", line);
    }
    _defineHere(label, line);
    _emit(_instructionWord(operand, info, line), line);
  }

  MixWord _instructionWord(String operand, OpInfo info, int line) {
    var aa = 0;
    var i = 0;
    var f = info.defaultF;
    String? future;
    _Literal? literal;
    var s = operand;
    if (s.isNotEmpty) {
      if (s.endsWith(')')) {
        final open = s.lastIndexOf('(');
        if (open < 0) throw MixAssemblyError('mismatched parenthesis', line);
        f = _wValue(s.substring(open + 1, s.length - 1), line);
        s = s.substring(0, open);
      }
      final comma = s.indexOf(',');
      if (comma >= 0) {
        i = _wValue(s.substring(comma + 1), line);
        s = s.substring(0, comma);
      }
      if (s.isEmpty) {
        // Bare ",1" or "(0:5)": address part defaults to 0.
      } else if (s.length >= 3 && s.startsWith('=') && s.endsWith('=')) {
        final expr = s.substring(1, s.length - 1);
        literal = _literals.where((l) => l.expr == expr).firstOrNull;
        if (literal == null) {
          literal = _Literal(expr, line);
          _literals.add(literal);
        }
      } else {
        try {
          aa = _eval(s, line);
        } on _FutureRef catch (fr) {
          if (_symbolPattern.hasMatch(s) || RegExp(r'^[0-9]F$').hasMatch(s)) {
            future = s;
          } else {
            throw MixAssemblyError(
                "undefined symbol '${fr.symbol}' in expression "
                '(a future reference must stand alone)',
                line);
          }
        }
      }
    }
    if (i < 0 || i > 63) throw MixAssemblyError('index out of range: $i', line);
    if (f < 0 || f > 63) throw MixAssemblyError('field out of range: $f', line);
    if (aa.abs() > 4095) {
      throw MixAssemblyError('address does not fit in two bytes: $aa', line);
    }
    if (future != null) _fixups.add(_Fixup(_loc, future, _seq, line));
    literal?.refs.add(_loc);
    final mag = aa.abs();
    return MixWord(aa < 0 ? -1 : 1, [mag ~/ 64, mag % 64, i, f, info.c]);
  }

  MixWord _alfWord(String raw, int opEnd, int line) {
    var s = opEnd < raw.length ? raw.substring(opEnd) : '';
    if (s.startsWith(' ')) s = s.substring(1);
    String content;
    final quoted = s.trimLeft();
    if (quoted.startsWith('"')) {
      final close = quoted.indexOf('"', 1);
      if (close < 0) throw MixAssemblyError('unterminated ALF string', line);
      content = quoted.substring(1, close);
      if (content.length > 5) {
        throw MixAssemblyError('ALF takes at most five characters', line);
      }
    } else {
      // Knuth's convention: the constant begins two spaces after ALF when
      // its first character would otherwise be a blank.
      if (s.startsWith(' ')) s = s.substring(1);
      content = s.length > 5 ? s.substring(0, 5) : s;
    }
    content = content.padRight(5);
    final codes = <int>[];
    for (final ch in content.split('')) {
      final code = mixCharCode(ch);
      if (code == null) {
        throw MixAssemblyError(
            "character '$ch' is not in the MIX character set", line);
      }
      codes.add(code);
    }
    return MixWord(1, codes);
  }

  void _placeLiterals() {
    for (final lit in _literals) {
      final v = _wValue(lit.expr, lit.line);
      if (v.abs() >= MixWord.wordModulus) {
        throw MixAssemblyError('literal does not fit in a word: $v', lit.line);
      }
      final addr = _loc;
      _emit(MixWord.fromValue(v), lit.line);
      for (final ref in lit.refs) {
        _patchAddress(ref, addr, lit.line);
      }
    }
  }

  void _resolveFixups() {
    for (final fx in _fixups) {
      int value;
      final local = RegExp(r'^([0-9])F$').firstMatch(fx.symbol);
      if (local != null) {
        final d = int.parse(local.group(1)!);
        final def =
            _locals[d].where((def) => def.seq > fx.seq).firstOrNull;
        if (def == null) {
          throw MixAssemblyError(
              "no ${d}H after this line for '${fx.symbol}'", fx.line);
        }
        value = def.value;
      } else {
        final v = _symbols[fx.symbol];
        if (v == null) {
          throw MixAssemblyError("undefined symbol '${fx.symbol}'", fx.line);
        }
        value = v;
      }
      _patchAddress(fx.address, value, fx.line);
    }
  }

  void _patchAddress(int wordAddr, int value, int line) {
    final old = _words[wordAddr]!;
    if (value.abs() > 4095) {
      throw MixAssemblyError('address does not fit in two bytes: $value', line);
    }
    final mag = value.abs();
    _words[wordAddr] = MixWord(value < 0 ? -1 : 1,
        [mag ~/ 64, mag % 64, old.bytes[2], old.bytes[3], old.bytes[4]]);
  }

  void _defineHere(String? label, int line) {
    if (label != null) _defineSymbol(label, _loc, line);
  }

  void _defineSymbol(String name, int value, int line) {
    if (RegExp(r'^[0-9]H$').hasMatch(name)) {
      _locals[int.parse(name[0])].add(_LocalDef(_seq, value));
      return;
    }
    if (RegExp(r'^[0-9][BF]$').hasMatch(name)) {
      throw MixAssemblyError("'$name' cannot be used as a label", line);
    }
    if (!_symbolPattern.hasMatch(name)) {
      throw MixAssemblyError("invalid symbol '$name'", line);
    }
    if (_symbols.containsKey(name)) {
      throw MixAssemblyError("symbol '$name' defined twice", line);
    }
    _symbols[name] = value;
  }

  int _wValue(String s, int line) {
    if (s.isEmpty) throw MixAssemblyError('missing operand', line);
    try {
      return _eval(s, line);
    } on _FutureRef catch (e) {
      throw MixAssemblyError("undefined symbol '${e.symbol}'", line);
    }
  }

  int _eval(String s, int line) {
    final toks = _tokens(s, line);
    if (toks.isEmpty) throw MixAssemblyError('empty expression', line);
    var idx = 0;
    var sign = 1;
    if (toks[0] == '+' || toks[0] == '-') {
      sign = toks[0] == '-' ? -1 : 1;
      idx = 1;
    }
    if (idx >= toks.length) {
      throw MixAssemblyError('malformed expression: $s', line);
    }
    var acc = sign * _atom(toks[idx++], line);
    while (idx < toks.length) {
      final op = toks[idx++];
      if (idx >= toks.length) {
        throw MixAssemblyError("dangling operator '$op'", line);
      }
      final rhs = _atom(toks[idx++], line);
      acc = switch (op) {
        '+' => acc + rhs,
        '-' => acc - rhs,
        '*' => acc * rhs,
        '/' => acc ~/ rhs,
        '//' => (acc * MixWord.wordModulus) ~/ rhs,
        ':' => 8 * acc + rhs,
        _ => throw MixAssemblyError("unexpected token '$op'", line),
      };
    }
    return acc;
  }

  int _atom(String t, int line) {
    if (t == '*') return _loc;
    if (RegExp(r'^[0-9]+$').hasMatch(t)) {
      if (t.length > 10) {
        throw MixAssemblyError('number too long: $t', line);
      }
      return int.parse(t);
    }
    final local = RegExp(r'^([0-9])([HBF])$').firstMatch(t);
    if (local != null) {
      final d = int.parse(local.group(1)!);
      switch (local.group(2)!) {
        case 'H':
          throw MixAssemblyError(
              "local label '$t' cannot appear in an expression", line);
        case 'B':
          final defs = _locals[d].where((def) => def.seq < _seq);
          if (defs.isEmpty) {
            throw MixAssemblyError("no ${d}H before this line for '$t'", line);
          }
          return defs.last.value;
        default: // 'F' — resolved after the whole source is read.
          throw _FutureRef(t);
      }
    }
    final v = _symbols[t];
    if (v == null) throw _FutureRef(t);
    return v;
  }

  List<String> _tokens(String s, int line) {
    final out = <String>[];
    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (_alnum.hasMatch(ch)) {
        var j = i;
        while (j < s.length && _alnum.hasMatch(s[j])) {
          j++;
        }
        out.add(s.substring(i, j));
        i = j;
      } else if (ch == '/') {
        if (i + 1 < s.length && s[i + 1] == '/') {
          out.add('//');
          i += 2;
        } else {
          out.add('/');
          i++;
        }
      } else if ('+-*:'.contains(ch)) {
        out.add(ch);
        i++;
      } else {
        throw MixAssemblyError("unexpected character '$ch' in expression", line);
      }
    }
    return out;
  }

  void _emit(MixWord w, int line) {
    if (_loc < 0 || _loc >= 4000) {
      throw MixAssemblyError('location counter out of range: $_loc', line);
    }
    _words[_loc] = w;
    _sourceLines[_loc] = line;
    _loc++;
  }

  static bool _isSpace(String ch) => ch == ' ' || ch == '\t';

  int _skipSpaces(String s, int p) {
    var q = p;
    while (q < s.length && _isSpace(s[q])) {
      q++;
    }
    return q;
  }

  int _scanToken(String s, int p) {
    var q = p;
    while (q < s.length && !_isSpace(s[q])) {
      q++;
    }
    return q;
  }
}
