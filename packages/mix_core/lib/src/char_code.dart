/// The MIX character code (TAOCP 1.3.1): codes 0..55 map to characters,
/// 56..63 are undefined.
const String mixCharacters =
    " ABCDEFGHIΔJKLMNOPQRΣΠSTUVWXYZ0123456789.,()+-*/=\$<>@;:'";

/// The MIX code for [ch], or null if the character is not in the set.
int? mixCharCode(String ch) {
  final i = mixCharacters.indexOf(ch);
  return i < 0 ? null : i;
}

/// The character for MIX code [code]; undefined codes render as '□'.
String mixCodeChar(int code) =>
    code >= 0 && code < mixCharacters.length ? mixCharacters[code] : '□';
