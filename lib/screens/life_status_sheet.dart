import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pet.dart';
import '../services/api.dart';
import '../services/owner_data.dart';
import '../services/owner_service.dart';
import '../theme.dart';
import '../utils/format.dart';

/// "Update status": mark [pet] passed away or lost. Out of respect nothing is
/// required — the date and note are optional. The owner can undo their own
/// mark for 7 days (the server decides; see [Pet.canChangeStatus]).
Future<void> showLifeStatusSheet(BuildContext context, Pet pet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LifeStatusSheet(pet: pet),
  );
}

class _LifeStatusSheet extends StatefulWidget {
  const _LifeStatusSheet({required this.pet});
  final Pet pet;

  @override
  State<_LifeStatusSheet> createState() => _LifeStatusSheetState();
}

class _LifeStatusSheetState extends State<_LifeStatusSheet> {
  String _status = 'deceased'; // deceased | lost
  DateTime? _date;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: Brand.maroon700),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await OwnerService.instance.setLifeStatus(
        petId: widget.pet.id,
        status: _status,
        date: _date,
        note: _note.text.trim(),
      );
      HapticFeedback.lightImpact();
      if (!mounted) return;
      Navigator.of(context).pop();
      OwnerData.instance.refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.pet.name;
    final passed = _status == 'deceased';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 4, 22, 22 + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update $name’s status',
              style: const TextStyle(fontFamily: Brand.serif, fontSize: 26, fontWeight: FontWeight.w700, color: Brand.maroon900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (value, label) in const [('deceased', 'Passed away'), ('lost', 'Lost or missing')]) ...[
                  Expanded(
                    child: ChoiceChip(
                      label: SizedBox(width: double.infinity, child: Text(label, textAlign: TextAlign.center)),
                      selected: _status == value,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _status = value),
                      selectedColor: Brand.maroon100,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _status == value ? Brand.maroon700 : Brand.inkSoft,
                      ),
                    ),
                  ),
                  if (value == 'deceased') const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF6F3EE), borderRadius: BorderRadius.circular(14)),
              child: Text(
                passed
                    ? 'We’re so sorry for your loss. $name’s vaccination records will be kept, and reminders will stop.'
                    : 'We hope $name comes home soon. Reminders will pause. You can change this back within 7 days, or ask LCVO after that.',
                style: const TextStyle(fontSize: 14.5, height: 1.5, color: Brand.ink),
              ),
            ),
            const SizedBox(height: 16),
            Text(passed ? 'DATE (OPTIONAL)' : 'MISSING SINCE (OPTIONAL)', style: _caption),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(_date == null ? 'Pick a date' : formatDate(_date!)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Brand.ink,
                alignment: Alignment.centerLeft,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Brand.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('NOTE (OPTIONAL)', style: _caption),
            const SizedBox(height: 6),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: passed ? 'Anything you would like to share' : 'Where or when they were last seen',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: Brand.maroon700,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: Text(_busy ? 'Saving…' : 'Confirm'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Brand.inkSoft)),
            ),
          ],
        ),
      ),
    );
  }
}

const _caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: Brand.inkSoft);
