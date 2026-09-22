/// Base class for all errors raised by the MIX emulator.
class MixError implements Exception {
  final String message;
  MixError(this.message);

  @override
  String toString() => 'MixError: $message';
}

/// An error raised while the machine is executing (bad address, invalid
/// opcode, index register overflow, ...). Where TAOCP says behavior is
/// "undefined", this emulator throws instead of guessing.
class MixRuntimeError extends MixError {
  MixRuntimeError(super.message);

  @override
  String toString() => 'MixRuntimeError: $message';
}

/// An error in MIXAL source, tagged with its 1-based line number.
class MixAssemblyError extends MixError {
  final int line;
  MixAssemblyError(String message, this.line) : super('line $line: $message');

  @override
  String toString() => 'MixAssemblyError: $message';
}
