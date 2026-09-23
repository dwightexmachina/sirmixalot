import 'package:flutter/material.dart';
import 'package:mix_core/mix_core.dart';

import '../theme.dart';

/// Opens the MIX instruction-set reference as a modal overlay.
void showInstructionReference(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: const Color(0xB8060910),
    builder: (_) => const _ReferenceDialog(),
  );
}

class _ReferenceDialog extends StatefulWidget {
  const _ReferenceDialog();

  @override
  State<_ReferenceDialog> createState() => _ReferenceDialogState();
}

class _ReferenceDialogState extends State<_ReferenceDialog> {
  final _all = instructionReference();
  String _query = '';
  String? _open;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final rows = q.isEmpty
        ? _all
        : _all
            .where((r) =>
                r.mnemonic.toLowerCase().contains(q) ||
                r.name.toLowerCase().contains(q) ||
                r.family.toLowerCase().contains(q))
            .toList();

    // Group by family, preserving the opcode order within each group.
    final families = <String, List<InstructionRef>>{};
    for (final r in rows) {
      (families[r.family] ??= []).add(r);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 760,
        decoration: BoxDecoration(
          color: const Color(0xFF10151C),
          border: Border.all(color: MixColors.bezel),
          borderRadius: BorderRadius.circular(9),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            _searchBox(),
            Flexible(
              child: rows.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('No instructions match.',
                          style: MixText.monoDim),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 14),
                      children: [
                        for (final entry in families.entries) ...[
                          _familyLabel(entry.key),
                          for (final r in entry.value) _row(r),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 14, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MixColors.bezelSoft)),
      ),
      child: Row(
        children: [
          const Text('MIX INSTRUCTION SET', style: MixText.panelTitle),
          const SizedBox(width: 10),
          Text('${_all.length} forms · generated from the emulator',
              style: MixText.caption.copyWith(fontSize: 10.5)),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Text('✕',
                  style: TextStyle(color: MixColors.labelDim, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
        decoration: BoxDecoration(
          color: MixColors.panelDeep,
          border: Border.all(color: MixColors.bezel),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Text('⌕',
                style: TextStyle(color: MixColors.labelDim, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                autofocus: true,
                style: const TextStyle(
                    fontFamily: monoFamily, fontSize: 12.5, color: MixColors.data),
                cursorColor: MixColors.amber,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'filter by mnemonic or name — JG, load, shift, float',
                  hintStyle: TextStyle(
                      fontFamily: monoFamily,
                      fontSize: 12.5,
                      color: MixColors.labelDim),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyLabel(String family) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 5),
      child: Text(family.toUpperCase(),
          style: MixText.caption.copyWith(
              color: MixColors.amber, letterSpacing: 1.6, fontSize: 10)),
    );
  }

  Widget _row(InstructionRef r) {
    final open = _open == r.mnemonic;
    return InkWell(
      onTap: () => setState(() => _open = open ? null : r.mnemonic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: open ? MixColors.amberSoft : null,
          borderRadius: BorderRadius.circular(5),
          border: open
              ? Border.all(color: MixColors.amber.withValues(alpha: 0.35))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 78,
                  child: Text(r.mnemonic,
                      style: const TextStyle(
                          fontFamily: monoFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MixColors.amber)),
                ),
                SizedBox(
                  width: 74,
                  child: Text('C=${r.c} F=${r.f}',
                      style: MixText.monoDim.copyWith(fontSize: 10.5)),
                ),
                SizedBox(
                  width: 40,
                  child: Text('${r.cost}u',
                      style: MixText.monoDim.copyWith(
                          fontSize: 10.5, color: MixColors.dataDim)),
                ),
                Expanded(
                  child: Text(r.name,
                      style: const TextStyle(fontSize: 12, color: MixColors.data)),
                ),
              ],
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(78, 7, 4, 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.fields,
                        style: MixText.monoDim.copyWith(fontSize: 10)),
                    const SizedBox(height: 6),
                    Text(r.body,
                        style: const TextStyle(
                            fontSize: 12, height: 1.55, color: MixColors.data)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
