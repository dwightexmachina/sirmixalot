import 'char_code.dart';
import 'errors.dart';
import 'machine.dart';
import 'word.dart';

/// A MIX peripheral. Unit numbers by convention: tapes 0-7, disks 8-15,
/// card reader 16, card punch 17, line printer 18, typewriter 19,
/// paper tape 20.
///
/// In this first version devices complete transfers instantly and are never
/// busy, so JBUS falls through and JRED always jumps.
abstract class MixDevice {
  int get blockSize;
  bool get busy => false;

  void input(MixMachine machine, int address) {
    throw MixRuntimeError('device does not support input');
  }

  void output(MixMachine machine, int address) {
    throw MixRuntimeError('device does not support output');
  }

  void control(MixMachine machine, int m) {}
}

/// Units 0–7: magnetic tape. A sequential list of fixed-size blocks with a
/// read/write head. MIX tapes use 100-word blocks; the size is configurable
/// here so demos can use smaller blocks. IOC controls the head: M = 0
/// rewinds, M < 0 skips back |M| blocks, M > 0 skips forward M blocks.
class MixTape extends MixDevice {
  MixTape({this.blockSize = 100});

  @override
  final int blockSize;

  /// Stored blocks, each exactly [blockSize] words.
  final List<List<MixWord>> blocks = [];

  /// The read/write head, in blocks from the start.
  int position = 0;

  @override
  void input(MixMachine machine, int address) {
    if (position < 0 || position >= blocks.length) {
      throw MixRuntimeError('tape read past end at block $position');
    }
    final block = blocks[position++];
    for (var k = 0; k < blockSize; k++) {
      machine.memory[address + k] = block[k];
    }
  }

  @override
  void output(MixMachine machine, int address) {
    final block = [
      for (var k = 0; k < blockSize; k++) machine.memory[address + k],
    ];
    if (position < blocks.length) {
      blocks[position] = block;
    } else {
      while (blocks.length < position) {
        blocks.add(List<MixWord>.filled(blockSize, MixWord.zero));
      }
      blocks.add(block);
    }
    position++;
  }

  @override
  void control(MixMachine machine, int m) {
    if (m == 0) {
      position = 0;
    } else {
      position = (position + m).clamp(0, blocks.length);
    }
  }
}

/// Unit 18: prints blocks of 24 words as 120-character lines.
class LinePrinter extends MixDevice {
  /// Marker line recorded when IOC 0(18) skips to a new page.
  static const String pageBreak = '\u000C';

  @override
  int get blockSize => 24;

  final List<String> lines = [];

  @override
  void output(MixMachine machine, int address) {
    final sb = StringBuffer();
    for (var k = 0; k < blockSize; k++) {
      for (final b in machine.memory[address + k].bytes) {
        sb.write(mixCodeChar(b));
      }
    }
    lines.add(sb.toString().trimRight());
  }

  @override
  void control(MixMachine machine, int m) {
    if (m == 0) lines.add(pageBreak);
  }
}

/// Unit 16: reads 80-character cards as blocks of 16 words.
class CardReader extends MixDevice {
  @override
  int get blockSize => 16;

  final List<String> cards = [];
  int _position = 0;

  int get remaining => cards.length - _position;

  @override
  void input(MixMachine machine, int address) {
    if (_position >= cards.length) {
      throw MixRuntimeError('card reader is empty');
    }
    final raw = cards[_position++];
    if (raw.length > 80) {
      throw MixRuntimeError('card longer than 80 characters');
    }
    final card = raw.padRight(80);
    for (var k = 0; k < blockSize; k++) {
      final chunk = card.substring(k * 5, k * 5 + 5);
      final codes = <int>[];
      for (final ch in chunk.split('')) {
        final code = mixCharCode(ch);
        if (code == null) {
          throw MixRuntimeError(
              "character '$ch' is not in the MIX character set");
        }
        codes.add(code);
      }
      machine.memory[address + k] = MixWord(1, codes);
    }
  }
}

/// Unit 17: punches blocks of 16 words as 80-character cards.
class CardPunch extends MixDevice {
  @override
  int get blockSize => 16;

  final List<String> cards = [];

  @override
  void output(MixMachine machine, int address) {
    final sb = StringBuffer();
    for (var k = 0; k < blockSize; k++) {
      for (final b in machine.memory[address + k].bytes) {
        sb.write(mixCodeChar(b));
      }
    }
    cards.add(sb.toString().trimRight());
  }
}
