import 'package:flutter/material.dart';

import '../models/owner_profile.dart';
import '../models/pet.dart';
import '../theme.dart';
import '../utils/format.dart';

/// The pet's vaccination record laid out like LCVO's paper "Rabies
/// Vaccination Record" card, with the same Filipino labels the office and
/// owners already know (Pangalan, Alaga, Petsa, Bakuna…).
///
/// Everything sits on one column grid so edges line up: owner and pet details
/// share a three-column grid, and each vaccination entry is a tinted block of
/// full-width or two-column lines (vaccine; Petsa | Susunod; Lot No. |
/// Beterinaryo; Approval ID) — no value ever has to wrap to fit a narrow cell.
class VaccineCard extends StatelessWidget {
  const VaccineCard({super.key, required this.pet, required this.owner});
  final Pet pet;
  final OwnerProfile? owner;

  String _or(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;

  String _cap(String? v) {
    final t = _or(v);
    return t == '—' ? t : t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final shots = pet.vaccinations.reversed.toList(); // newest first
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: Brand.maroon100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'LCVO · RABIES\nVACCINATION RECORD',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: Brand.maroon900,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'REG. NO.',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Brand.maroon700,
                      ),
                    ),
                    Text(
                      _or(pet.registrationNo),
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: Brand.maroon900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Owner and pet share one three-column grid.
                _Grid3([
                  [(3, _Field('Pangalan', _or(owner?.fullName)))],
                  [
                    (1, _Field('Contact No.', _or(owner?.contactNo))),
                    (2, _Field('Tirahan', _or(owner?.address))),
                  ],
                ]),
                const _Rule(),
                _Grid3([
                  [
                    (1, _Field('Alaga', _or(pet.name))),
                    (1, _Field('Uri', _cap(pet.species))),
                    (1, _Field('Lahi', _or(pet.breed))),
                  ],
                  [
                    (1, _Field('Kasarian', _cap(pet.sex))),
                    (1, _Field('Kulay', _or(pet.color))),
                    (1, _Field('Edad', _or(pet.age))),
                  ],
                ]),
                const _Rule(),
                const Text(
                  'MGA BAKUNA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: Brand.maroon700,
                  ),
                ),
                const SizedBox(height: 10),
                if (shots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No vaccinations recorded yet.',
                      style: TextStyle(fontSize: 14, color: Brand.inkSoft),
                    ),
                  )
                else
                  for (var i = 0; i < shots.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ShotEntry(shot: shots[i]),
                  ],
              ],
            ),
          ),
          // Disclaimer, same wording as the printed card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Brand.surfaceAlt,
              border: Border(top: BorderSide(color: Brand.border)),
            ),
            child: const Text(
              'For reference only — not a legal or official veterinary document. '
              'Not valid without LCVO’s official signed/stamped record.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: Brand.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: Divider(height: 1, color: Brand.border),
  );
}

/// Rows of fields on a fixed three-column grid; each entry is (span, widget).
/// A span of 2 or 3 covers that many columns plus the gaps between them, so
/// every row's edges match the columns above and below it.
class _Grid3 extends StatelessWidget {
  const _Grid3(this.rows);
  final List<List<(int, Widget)>> rows;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final col = (c.maxWidth - 2 * _gap) / 3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: rows[r][i].$1 * col + (rows[r][i].$1 - 1) * _gap,
                      child: rows[r][i].$2,
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A small caps label with its value underneath.
class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.size = 14, this.bold = false});
  final String label;
  final String value;
  final double size;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Brand.inkSoft,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            height: 1.25,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: Brand.ink,
          ),
        ),
      ],
    );
  }
}

/// One vaccination as a tinted entry:
///   BAKUNA (full width, the headline)
///   PETSA | SUSUNOD          — two equal columns
///   LOT NO. | BETERINARYO    — the same two columns
///   APPROVAL ID (full width, selectable for copying)
class _ShotEntry extends StatelessWidget {
  const _ShotEntry({required this.shot});
  final Vaccination shot;

  String _or(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;

  Widget _pair(Widget left, Widget right) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final vaccine =
        shot.vaccineName + ((shot.dose ?? 1) > 1 ? ' (dose ${shot.dose})' : '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field('Bakuna', vaccine, size: 16, bold: true),
          const SizedBox(height: 12),
          _pair(
            _Field('Petsa', formatDate(shot.date)),
            _Field(
              'Susunod',
              shot.nextDue == null ? '—' : formatDate(shot.nextDue!),
            ),
          ),
          const SizedBox(height: 12),
          _pair(
            _Field('Lot No.', _or(shot.lotNo)),
            _Field('Beterinaryo', _or(shot.vetName)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Brand.border),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'APPROVAL ID',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Brand.inkSoft,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                _or(shot.approvalCode),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: Brand.maroon700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
