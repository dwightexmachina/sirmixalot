import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mix_core/mix_core.dart';

import '../programs/gallery.dart';

/// Drives one MixMachine for the UI: load/reset, single-step, and a
/// speed-controlled run loop. Panels listen to this and repaint per notify
/// (at most once per timer tick while running).
class MachineController extends ChangeNotifier {
  MixMachine machine = MixMachine();
  AssembledProgram? program;
  GalleryProgram current;
  List<String> sourceLines = const [];

  /// 1-based source line -> memory address, for the source gutter.
  Map<int, int> addressForLine = const {};

  StepResult? lastStep;
  Set<String> changedRegs = const {};
  String? error;
  bool running = false;

  /// Slider position 0..1; instructions/second = 10^(4 * value), 1..10k.
  double speedKnob = 0.2;

  Timer? _timer;
  double _carry = 0;

  MachineController({GalleryProgram? initial})
      : current = initial ??
            gallery.firstWhere((p) => p.id == 'program-m',
                orElse: () => gallery.first) {
    load(current);
  }

  double get speed => math.pow(10, 4 * speedKnob).toDouble();

  String get speedLabel {
    final s = speed;
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(s >= 10000 ? 0 : 1)}k/s';
    if (s >= 10) return '${s.round()} instr/s';
    return '${s.toStringAsFixed(1)} instr/s';
  }

  bool get canStep => program != null && !machine.halted && error == null;

  /// 1-based source line of the next instruction, or null.
  int? get currentSourceLine =>
      canStep ? program!.sourceLines[machine.pc] : null;

  void load(GalleryProgram p) {
    _stopTimer();
    running = false;
    current = p;
    error = null;
    lastStep = null;
    changedRegs = const {};
    machine = MixMachine();
    sourceLines = p.source.trimRight().split('\n');
    try {
      program = assembleMixal(p.source);
      addressForLine = {
        for (final e in program!.sourceLines.entries) e.value: e.key,
      };
      machine.loadProgram(program!);
    } on MixError catch (e) {
      program = null;
      addressForLine = const {};
      error = e.message;
    }
    notifyListeners();
  }

  void reset() => load(current);

  void stepOnce() {
    if (!canStep) return;
    _step();
    notifyListeners();
  }

  void toggleRun() {
    if (running) {
      pause();
    } else {
      start();
    }
  }

  void start() {
    if (!canStep || running) return;
    running = true;
    _carry = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
    notifyListeners();
  }

  void pause() {
    _stopTimer();
    running = false;
    notifyListeners();
  }

  void setSpeed(double knob) {
    speedKnob = knob.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _tick(Timer _) {
    _carry += speed * 0.016;
    var n = _carry.floor();
    _carry -= n;
    while (n-- > 0 && canStep) {
      _step();
    }
    if (!canStep) {
      _stopTimer();
      running = false;
    }
    notifyListeners();
  }

  void _step() {
    final beforeA = machine.rA;
    final beforeX = machine.rX;
    final beforeJ = machine.rJ;
    final beforeI = List.of(machine.rI);
    try {
      lastStep = machine.step();
    } on MixError catch (e) {
      error = e.message;
      return;
    }
    changedRegs = {
      if (machine.rA != beforeA) 'A',
      if (machine.rX != beforeX) 'X',
      if (machine.rJ != beforeJ) 'J',
      for (var i = 0; i < 6; i++)
        if (machine.rI[i] != beforeI[i]) 'I${i + 1}',
    };
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
