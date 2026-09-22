import 'errors.dart';

/// A MIX word: a sign and five 6-bit bytes.
///
/// TAOCP only requires a byte to hold at least 64 values; this implementation
/// fixes the byte size at exactly 64 so words are concrete and visualizable.
/// MIX distinguishes +0 from -0, so [sign] is meaningful even at zero
/// magnitude, and numeric comparisons must go through [value].
class MixWord {
  static const int byteSize = 64;

  /// 64^5: one more than the maximum word magnitude.
  static const int wordModulus = 1073741824;

  /// +1 or -1.
  final int sign;

  /// Five bytes, each 0..63. `bytes[0]` is byte 1 (most significant).
  final List<int> bytes;

  MixWord(this.sign, List<int> byteList) : bytes = List.unmodifiable(byteList) {
    if (sign != 1 && sign != -1) {
      throw ArgumentError('sign must be +1 or -1, got $sign');
    }
    if (bytes.length != 5 || bytes.any((b) => b < 0 || b >= byteSize)) {
      throw ArgumentError('a word needs five bytes in 0..63, got $bytes');
    }
  }

  static final MixWord zero = MixWord(1, const [0, 0, 0, 0, 0]);

  factory MixWord.fromMagnitude(int sign, int magnitude) {
    if (magnitude < 0 || magnitude >= wordModulus) {
      throw ArgumentError('magnitude out of range: $magnitude');
    }
    final b = List<int>.filled(5, 0);
    var m = magnitude;
    for (var k = 4; k >= 0; k--) {
      b[k] = m % byteSize;
      m ~/= byteSize;
    }
    return MixWord(sign, b);
  }

  factory MixWord.fromValue(int value) =>
      MixWord.fromMagnitude(value < 0 ? -1 : 1, value.abs());

  int get magnitude =>
      (((bytes[0] * byteSize + bytes[1]) * byteSize + bytes[2]) * byteSize +
          bytes[3]) *
          byteSize +
      bytes[4];

  int get value => sign * magnitude;

  bool get isZero => magnitude == 0;

  /// Encodes field (L:R) as the F-byte 8L + R.
  static int fieldSpec(int l, int r) => 8 * l + r;

  /// Extracts field (L:R), right-justified, per MIX load semantics.
  ///
  /// L = 0 includes the sign; otherwise the result is positive.
  MixWord field(int f) {
    final l = f ~/ 8, r = f % 8;
    if (l > r || r > 5) {
      throw MixRuntimeError('bad field spec ($l:$r)');
    }
    var s = 1;
    var start = l;
    if (l == 0) {
      s = sign;
      start = 1;
    }
    final n = r - start + 1;
    final out = List<int>.filled(5, 0);
    for (var k = 0; k < n; k++) {
      out[5 - n + k] = bytes[start - 1 + k];
    }
    return MixWord(s, out);
  }

  /// Returns this word with field (L:R) replaced by the rightmost bytes of
  /// [source], per MIX store semantics. The sign is replaced only if L = 0.
  MixWord storing(MixWord source, int f) {
    final l = f ~/ 8, r = f % 8;
    if (l > r || r > 5) {
      throw MixRuntimeError('bad field spec ($l:$r)');
    }
    var s = sign;
    var start = l;
    if (l == 0) {
      s = source.sign;
      start = 1;
    }
    final n = r - start + 1;
    final out = List<int>.of(bytes);
    for (var k = 0; k < n; k++) {
      out[start - 1 + k] = source.bytes[5 - n + k];
    }
    return MixWord(s, out);
  }

  MixWord get negated => MixWord(-sign, bytes);

  @override
  bool operator ==(Object other) =>
      other is MixWord &&
      other.sign == sign &&
      other.bytes[0] == bytes[0] &&
      other.bytes[1] == bytes[1] &&
      other.bytes[2] == bytes[2] &&
      other.bytes[3] == bytes[3] &&
      other.bytes[4] == bytes[4];

  @override
  int get hashCode => Object.hash(sign, Object.hashAll(bytes));

  @override
  String toString() =>
      '${sign < 0 ? '-' : '+'} ${bytes.map((b) => b.toString().padLeft(2, '0')).join(' ')}';
}
