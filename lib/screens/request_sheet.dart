import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pet.dart';
import '../services/api.dart';
import '../services/owner_data.dart';
import '../services/owner_service.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Opens the "Request a correction" sheet for [pet]. Owners can't edit their
/// records; this sends a request the office reviews. Only the five fields the
/// server accepts are offered.
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

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.pet});
  final Pet pet;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  _Field _field = _Field.petName;
  final _text = TextEditingController();
  final _reason = TextEditingController();
  String? _sex; // male | female | unknown
  DateTime? _birth;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _reason.dispose();
    super.dispose();
  }

  String get _current {
    final p = widget.pet;
    String or(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;
    return switch (_field) {
      _Field.petName => or(p.name),
      _Field.breed => or(p.breed),
      _Field.color => or(p.color),
      _Field.sex => or(p.sex),
      _Field.birthDate => p.birthDate == null ? '—' : formatDate(p.birthDate!),
    };
  }

  /// The value to send, or null when nothing has been entered yet.
  String? get _value => switch (_field) {
    _Field.sex => _sex,
    _Field.birthDate =>
      _birth == null
          ? null
          : '${_birth!.year.toString().padLeft(4, '0')}-'
                '${_birth!.month.toString().padLeft(2, '0')}-'
                '${_birth!.day.toString().padLeft(2, '0')}',
    _ => _text.text.trim().isEmpty ? null : _text.text.trim(),
  };

  void _pick(_Field f) => setState(() {
    _field = f;
    _error = null;
  });

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
    final value = _value;
    if (value == null || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await OwnerService.instance.submitRequest(
        petId: widget.pet.id,
        field: _field.key,
        value: value,
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
    final ready = _value != null && !_busy;
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
              'Tell the office what to fix on ${widget.pet.name}’s card. '
              'Staff will review it before anything changes.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Brand.inkSoft,
              ),
            ),
            const SizedBox(height: 18),
            const _Caption('WHAT NEEDS FIXING?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _Field.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _field == f,
                    onSelected: _busy ? null : (_) => _pick(f),
                    showCheckmark: false,
                    selectedColor: Brand.maroon700,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _field == f ? Brand.maroon700 : Brand.border,
                    ),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _field == f ? Colors.white : Brand.ink,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _Caption('CORRECT ${_field.label.toUpperCase()}'),
            const SizedBox(height: 8),
            _valueInput(),
            const SizedBox(height: 6),
            Text(
              'Currently: $_current',
              style: const TextStyle(fontSize: 12.5, color: Brand.inkSoft),
            ),
            const SizedBox(height: 18),
            const _Caption('REASON (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              enabled: !_busy,
              maxLines: 2,
              maxLength: 200,
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
                    : const Text('Send to the office'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    counterText: '',
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

  Widget _valueInput() {
    switch (_field) {
      case _Field.sex:
        return Wrap(
          spacing: 8,
          children: [
            for (final s in const ['male', 'female', 'unknown'])
              ChoiceChip(
                label: Text(s[0].toUpperCase() + s.substring(1)),
                selected: _sex == s,
                onSelected: _busy ? null : (_) => setState(() => _sex = s),
                showCheckmark: false,
                selectedColor: Brand.maroon100,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: _sex == s ? Brand.maroon700 : Brand.border,
                ),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _sex == s ? Brand.maroon900 : Brand.ink,
                ),
              ),
          ],
        );
      case _Field.birthDate:
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Brand.ink,
            alignment: Alignment.centerLeft,
            side: const BorderSide(color: Brand.border, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _busy ? null : _pickDate,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(_birth == null ? 'Choose a date' : formatDate(_birth!)),
        );
      default:
        return TextField(
          controller: _text,
          enabled: !_busy,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          decoration: _decoration('New ${_field.label.toLowerCase()}'),
        );
    }
  }
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
