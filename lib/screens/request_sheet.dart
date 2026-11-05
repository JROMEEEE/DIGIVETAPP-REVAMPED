import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pet.dart';
import '../services/api.dart';
import '../services/owner_data.dart';
import '../services/owner_service.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Opens the "Request a correction" sheet for [pet]. Owners can't edit their
/// records; this sends a request the office reviews. Same as the web portal:
/// every field the server accepts is listed with what LCVO has now, and only
/// the ones the owner changes are sent, together, as one request.
Future<void> showRequestSheet(BuildContext context, Pet pet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RequestSheet(pet: pet),
  );
}

enum _Field { petName, breed, color, sex, birthDate }

extension on _Field {
  String get key => switch (this) {
    _Field.petName => 'pet_name',
    _Field.breed => 'breed',
    _Field.color => 'color_markings',
    _Field.sex => 'sex',
    _Field.birthDate => 'birth_date',
  };

  String get label => switch (this) {
    _Field.petName => 'Pet name',
    _Field.breed => 'Breed',
    _Field.color => 'Color / markings',
    _Field.sex => 'Sex',
    _Field.birthDate => 'Birth date',
  };
}

// The server stores sex as 'male' / 'female' and dates as YYYY-MM-DD, so the
// app sends exactly those (a typed "Male" would make the staff's Approve fail).
const _sexLabel = {'male': 'Male', 'female': 'Female', 'unknown': 'Unknown'};

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.pet});
  final Pet pet;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _text = {
    _Field.petName: TextEditingController(),
    _Field.breed: TextEditingController(),
    _Field.color: TextEditingController(),
  };
  final _reason = TextEditingController();
  String? _sex; // male | female
  DateTime? _birth;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    _reason.dispose();
    super.dispose();
  }

  /// What LCVO has on record now, in the server's format ('' when empty).
  String _currentRaw(_Field f) {
    final p = widget.pet;
    return switch (f) {
      _Field.petName => p.name,
      _Field.breed => p.breed ?? '',
      _Field.color => p.color ?? '',
      _Field.sex => (p.sex ?? '').toLowerCase(),
      _Field.birthDate => p.birthDate == null ? '' : _iso(p.birthDate!),
    }.trim();
  }

  String _currentShown(_Field f) {
    final raw = _currentRaw(f);
    if (raw.isEmpty) return 'not on record';
    return switch (f) {
      _Field.sex => _sexLabel[raw] ?? raw,
      _Field.birthDate => formatDate(widget.pet.birthDate!),
      _ => raw,
    };
  }

  String _entered(_Field f) => switch (f) {
    _Field.sex => _sex ?? '',
    _Field.birthDate => _birth == null ? '' : _iso(_birth!),
    _ => _text[f]!.text.trim(),
  };

  /// Only fields that were filled in and differ from the record are sent.
  Map<String, String> get _changes => {
    for (final f in _Field.values)
      if (_entered(f).isNotEmpty &&
          _entered(f).toLowerCase() != _currentRaw(f).toLowerCase())
        f.key: _entered(f),
  };

  bool _isChanged(_Field f) => _changes.containsKey(f.key);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? widget.pet.birthDate ?? DateTime(now.year - 1),
      firstDate: DateTime(1990),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: Brand.maroon700),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _submit() async {
    final changes = _changes;
    if (changes.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await OwnerService.instance.submitRequest(
        petId: widget.pet.id,
        changes: changes,
        reason: _reason.text.trim(),
      );
      HapticFeedback.lightImpact();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Sent to the office for review.')),
      );
      // Pull the new request in so it shows as Pending everywhere.
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
    final count = _changes.length;
    final ready = count > 0 && !_busy;
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          4,
          22,
          22 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Request a correction',
              style: TextStyle(
                fontFamily: Brand.serif,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Brand.maroon900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in only what needs correcting on ${widget.pet.name}’s '
              'record. Blank fields stay as they are, and staff review the '
              'request before anything changes.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Brand.inkSoft,
              ),
            ),
            const SizedBox(height: 16),
            for (final f in _Field.values) ...[
              _fieldBlock(f),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            const _Caption('REASON (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              enabled: !_busy,
              maxLines: 2,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('e.g. Spelling mistake'),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE6B3B3)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.maroon700,
                  disabledBackgroundColor: Brand.maroon700.withValues(
                    alpha: 0.35,
                  ),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: ready ? _submit : null,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        count > 1
                            ? 'Send $count corrections'
                            : count == 1
                            ? 'Send correction'
                            : 'Fill in a field to correct',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One field: its name and what is on record now, then the input. A field
  /// that will be sent gets a maroon edge, like the web form's highlight.
  Widget _fieldBlock(_Field f) {
    final changed = _isChanged(f);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: changed
            ? Brand.maroon100.withValues(alpha: 0.45)
            : Brand.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: changed ? Brand.maroon700 : Brand.border,
          width: changed ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                f.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Brand.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Now: ${_currentShown(f)}',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Brand.inkSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _input(f),
        ],
      ),
    );
  }

  Widget _input(_Field f) {
    switch (f) {
      case _Field.sex:
        return Wrap(
          spacing: 8,
          children: [
            for (final s in const ['male', 'female'])
              ChoiceChip(
                label: Text(_sexLabel[s]!),
                selected: _sex == s,
                // Tapping the chosen one again clears it ("keep as is").
                onSelected: _busy
                    ? null
                    : (_) => setState(() => _sex = _sex == s ? null : s),
                showCheckmark: false,
                selectedColor: Brand.maroon700,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: _sex == s ? Brand.maroon700 : Brand.border,
                ),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _sex == s ? Colors.white : Brand.ink,
                ),
              ),
          ],
        );
      case _Field.birthDate:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _birth == null ? Brand.inkSoft : Brand.ink,
                  backgroundColor: Colors.white,
                  alignment: Alignment.centerLeft,
                  side: const BorderSide(color: Brand.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _busy ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  _birth == null ? 'Keep as is' : formatDate(_birth!),
                ),
              ),
            ),
            if (_birth != null)
              IconButton(
                tooltip: 'Keep as is',
                onPressed: _busy ? null : () => setState(() => _birth = null),
                icon: const Icon(Icons.close_rounded, color: Brand.inkSoft),
              ),
          ],
        );
      default:
        return TextField(
          controller: _text[f],
          enabled: !_busy,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: _decoration('Keep as is'),
        );
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: _border(Brand.border),
    enabledBorder: _border(Brand.border),
    disabledBorder: _border(Brand.border),
    focusedBorder: _border(Brand.maroon700, 1.8),
  );

  OutlineInputBorder _border(Color c, [double w = 1.2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.9,
      color: Brand.inkSoft,
    ),
  );
}
