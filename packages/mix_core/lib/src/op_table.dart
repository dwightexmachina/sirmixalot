/// The MIXAL operation table: mnemonic -> opcode byte C and default F.
class OpInfo {
  final int c;
  final int defaultF;
  const OpInfo(this.c, this.defaultF);
}

final Map<String, OpInfo> mixalOps = _buildOpTable();

Map<String, OpInfo> _buildOpTable() {
  final t = <String, OpInfo>{
    'NOP': const OpInfo(0, 0),
    'ADD': const OpInfo(1, 5),
    'FADD': const OpInfo(1, 6),
    'SUB': const OpInfo(2, 5),
    'FSUB': const OpInfo(2, 6),
    'MUL': const OpInfo(3, 5),
    'FMUL': const OpInfo(3, 6),
    'DIV': const OpInfo(4, 5),
    'FDIV': const OpInfo(4, 6),
    'NUM': const OpInfo(5, 0),
    'CHAR': const OpInfo(5, 1),
    'HLT': const OpInfo(5, 2),
    'SLA': const OpInfo(6, 0),
    'SRA': const OpInfo(6, 1),
    'SLAX': const OpInfo(6, 2),
    'SRAX': const OpInfo(6, 3),
    'SLC': const OpInfo(6, 4),
    'SRC': const OpInfo(6, 5),
    'MOVE': const OpInfo(7, 1),
    'STJ': const OpInfo(32, 2),
    'STZ': const OpInfo(33, 5),
    'JBUS': const OpInfo(34, 0),
    'IOC': const OpInfo(35, 0),
    'IN': const OpInfo(36, 0),
    'OUT': const OpInfo(37, 0),
    'JRED': const OpInfo(38, 0),
    'JMP': const OpInfo(39, 0),
    'JSJ': const OpInfo(39, 1),
    'JOV': const OpInfo(39, 2),
    'JNOV': const OpInfo(39, 3),
    'JL': const OpInfo(39, 4),
    'JE': const OpInfo(39, 5),
    'JG': const OpInfo(39, 6),
    'JGE': const OpInfo(39, 7),
    'JNE': const OpInfo(39, 8),
    'JLE': const OpInfo(39, 9),
    'FCMP': const OpInfo(56, 6),
  };
  const regs = ['A', '1', '2', '3', '4', '5', '6', 'X'];
  const jumpConds = ['N', 'Z', 'P', 'NN', 'NZ', 'NP'];
  const addrOps = ['INC', 'DEC', 'ENT', 'ENN'];
  for (var r = 0; r < 8; r++) {
    final n = regs[r];
    t['LD$n'] = OpInfo(8 + r, 5);
    t['LD${n}N'] = OpInfo(16 + r, 5);
    t['ST$n'] = OpInfo(24 + r, 5);
    t['CMP$n'] = OpInfo(56 + r, 5);
    for (var f = 0; f < jumpConds.length; f++) {
      t['J$n${jumpConds[f]}'] = OpInfo(40 + r, f);
    }
    for (var f = 0; f < addrOps.length; f++) {
      t['${addrOps[f]}$n'] = OpInfo(48 + r, f);
    }
  }
  return t;
}
