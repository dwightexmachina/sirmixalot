import 'dart:math' as math;

import 'word.dart';

/// MIX floating-point support (TAOCP 4.2), for byte size 64.
///
/// A floating-point word is `± e f f f f`: byte 1 is the exponent `e`
/// (stored excess-[expBias]), bytes 2–5 are a 4-byte fraction. The value is
/// `± (fraction / 64^4) · 64^(e − expBias)`, with the fraction normalized so
/// its leading byte is nonzero (1/64 ≤ f < 1). A fraction of zero means the
/// value 0 regardless of the exponent.
///
/// The arithmetic here computes results at full MIX precision (the 4-byte
/// fraction is only 24 bits, exactly representable in a Dart double), then
/// renormalizes and rounds. This matches MIX numerically; it does not promise
/// bit-identical tie-breaking with a specific hardware MIX, and the exponent
/// bias below is an explicit, documented convention.
const int floatExpBias = 32;

/// 64^4 — one past the largest 4-byte fraction.
const int _fracUnit = 16777216;
const int _fracMin = _fracUnit ~/ 64; // 64^3: smallest normalized fraction

/// The numeric value of [w] read as a MIX floating-point word.
double mixFloatValue(MixWord w) {
  final e = w.bytes[0];
  final frac =
      ((w.bytes[1] * 64 + w.bytes[2]) * 64 + w.bytes[3]) * 64 + w.bytes[4];
  if (frac == 0) return 0.0;
  return w.sign * frac * math.pow(64, e - floatExpBias - 4).toDouble();
}

/// The outcome of a floating-point operation: the result word plus whether it
/// overflowed the exponent range (the caller lights the overflow toggle).
class MixFloatResult {
  final MixWord word;
  final bool overflow;
  const MixFloatResult(this.word, this.overflow);
}

/// Encodes [x] as a normalized MIX floating-point word. Values too large for
/// the exponent range set [MixFloatResult.overflow]; values too small
/// underflow quietly to +0.
MixFloatResult mixFloatFromDouble(double x) {
  if (x == 0 || x.isNaN) return MixFloatResult(MixWord.zero, false);
  final sign = x < 0 ? -1 : 1;
  var m = x.abs();
  var eTrue = 0;
  while (m >= 1.0) {
    m /= 64;
    eTrue++;
  }
  while (m < 1.0 / 64) {
    m *= 64;
    eTrue--;
  }
  var frac = (m * _fracUnit).round();
  if (frac >= _fracUnit) {
    // Rounded up to 1.0 — renormalize.
    frac = _fracMin;
    eTrue++;
  }
  var e = eTrue + floatExpBias;
  var overflow = false;
  if (e > 63) {
    overflow = true;
    e = 63;
    frac = _fracUnit - 1;
  } else if (e < 0) {
    // Exponent underflow: flush to zero.
    return MixFloatResult(MixWord.zero, false);
  }
  final b4 = frac % 64;
  frac ~/= 64;
  final b3 = frac % 64;
  frac ~/= 64;
  final b2 = frac % 64;
  frac ~/= 64;
  final b1 = frac % 64;
  return MixFloatResult(MixWord(sign, [e, b1, b2, b3, b4]), overflow);
}

MixFloatResult mixFloatAdd(MixWord u, MixWord v, {bool subtract = false}) {
  final b = mixFloatValue(v);
  return mixFloatFromDouble(mixFloatValue(u) + (subtract ? -b : b));
}

MixFloatResult mixFloatMul(MixWord u, MixWord v) =>
    mixFloatFromDouble(mixFloatValue(u) * mixFloatValue(v));

MixFloatResult mixFloatDiv(MixWord u, MixWord v) {
  final d = mixFloatValue(v);
  if (d == 0) return MixFloatResult(MixWord.zero, true); // divide by zero
  return mixFloatFromDouble(mixFloatValue(u) / d);
}

/// Compares two floating-point words within a fuzz of [epsilon] (itself a
/// floating-point word; +0 means an exact comparison). Returns -1, 0, or 1.
int mixFloatCompare(MixWord u, MixWord v, MixWord epsilon) {
  final a = mixFloatValue(u);
  final b = mixFloatValue(v);
  final eps = mixFloatValue(epsilon).abs();
  if ((a - b).abs() <= eps) return 0;
  return a < b ? -1 : 1;
}
