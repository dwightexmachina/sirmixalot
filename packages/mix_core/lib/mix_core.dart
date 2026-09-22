/// Pure-Dart emulator for Donald Knuth's MIX 1009 machine (TAOCP).
///
/// No Flutter dependencies: this package models the machine (words,
/// registers, memory, devices), executes the full MIX instruction set with
/// cycle-accurate timing, and assembles MIXAL source.
library;

export 'src/assembler.dart';
export 'src/char_code.dart';
export 'src/devices.dart';
export 'src/errors.dart';
export 'src/explain.dart';
export 'src/instruction.dart';
export 'src/machine.dart';
export 'src/op_table.dart';
export 'src/word.dart';
