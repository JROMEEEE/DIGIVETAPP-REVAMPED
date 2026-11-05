import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Home's "Vaccination status" card, the phone version of the web
/// dashboard's 12-month timeline: Today on the left, a year out on the right,
/// one dot per due date, with pet faces above. Pets due the same day share a
/// spot (one trip to LCVO); overdue pets sit in a "Late" zone left of Today.
/// The list under the rail says the same in words. Tapping a face or a row
/// calls [onPick] so Home can show that pet on its big card.
class VaccinationTimeline extends StatelessWidget {
  const VaccinationTimeline({super.key, required this.pets, this.onPick});
  final List<Pet> pets;
  final ValueChanged<Pet>? onPick;

  static const _yearDays = 365;
  static const _lateZone = 0.12; // share of the rail kept for overdue pets
  static const _maxRows = 5;

  @override
  Widget build(BuildContext context) {
    final tl = _Timeline.from(pets);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vaccination status',
            style: TextStyle(
              fontFamily: Brand.serif,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Brand.maroon900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tl.summary,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: tl.summaryColor,
            ),
          ),
          if (tl.groups.isNotEmpty) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, c) =>
                  _Rail(tl: tl, width: c.maxWidth, onPick: onPick),
            ),
          ],
          if (tl.rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            for (final r in tl.rows.take(
              tl.rows.length <= _maxRows ? _maxRows : _maxRows - 1,
            ))
              _Row(row: r, onPick: onPick),
            if (tl.rows.length > _maxRows)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${tl.rows.skip(_maxRows - 1).fold<int>(0, (n, r) => n + r.pets.length)} more pets on My Pets',
                  style: const TextStyle(fontSize: 12.5, color: Brand.inkSoft),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── data ───────────────────────────────────────────────────────────────────

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

const _rank = {
  DueStatus.overdue: 0,
  DueStatus.dueSoon: 1,
  DueStatus.upToDate: 2,
};
DueStatus _worst(List<Pet> ps) =>
    (ps.map((p) => p.status).toList()
          ..sort((a, b) => (_rank[a] ?? 3).compareTo(_rank[b] ?? 3)))
        .first;

Color _statusColor(DueStatus s) => switch (s) {
  DueStatus.overdue => const Color(0xFFB3261E),
  DueStatus.dueSoon => const Color(0xFFC89B2A),
  DueStatus.upToDate => Brand.green700,
  _ => Brand.inkSoft,
};

String _plural(int n, String w) => '$n $w${n == 1 ? '' : 's'}';

String _relative(int days) {
  if (days < 0) return '${_plural(-days, 'day')} late';
  if (days == 0) return 'today';
  if (days <= 45) return 'in ${_plural(days, 'day')}';
  return 'in ${_plural((days / 30.44).round(), 'month')}';
}

class _Group {
  _Group(this.date, this.pets)
    : days = date.difference(_today()).inDays,
      status = _worst(pets);
  final DateTime date;
  final List<Pet> pets;
  final int days;
  final DueStatus status;
}

class _ListRow {
  _ListRow({
    required this.pets,
    required this.status,
    required this.date,
    required this.rel,
  });
  final List<Pet> pets;
  final DueStatus status;
  final String date;
  final String rel;
}

class _Timeline {
  _Timeline(this.groups, this.rows, this.summary, this.summaryColor);
  final List<_Group> groups;
  final List<_ListRow> rows;
  final String summary;
  final Color summaryColor;

  bool get hasLate => groups.any((g) => g.days < 0);
  double get base => hasLate ? VaccinationTimeline._lateZone : 0;

  /// 0..1 across the rail for a due date [days] from today.
  double frac(int days) =>
      base +
      (1 - base) *
          (days.clamp(0, VaccinationTimeline._yearDays) /
              VaccinationTimeline._yearDays);

  factory _Timeline.from(List<Pet> pets) {
    final active = pets.where((p) => p.isActive).toList();
    final byDate = <DateTime, List<Pet>>{};
    final extras = <_ListRow>[];
    for (final p in active) {
      if (p.status == DueStatus.historical) {
        extras.add(
          _ListRow(
            pets: [p],
            status: DueStatus.historical,
            date: 'Before 2024',
            rel: 'Visit LCVO',
          ),
        );
      } else if (p.nextDue == null) {
        extras.add(
          _ListRow(
            pets: [p],
            status: DueStatus.none,
            date: 'No shot yet',
            rel: '',
          ),
        );
      } else {
        byDate.putIfAbsent(p.nextDue!, () => []).add(p);
      }
    }
    final groups = (byDate.entries.map((e) => _Group(e.key, e.value)).toList())
      ..sort((a, b) => a.date.compareTo(b.date));

    final latePets = groups
        .where((g) => g.days < 0)
        .expand((g) => g.pets)
        .length;
    final soon = groups.where((g) => g.status == DueStatus.dueSoon).toList();
    final onTrack = groups.fold<int>(0, (n, g) => n + g.pets.length);
    String summary;
    Color color = Brand.inkSoft;
    if (latePets > 0 || soon.isNotEmpty) {
      final parts = <String>[
        if (latePets > 0) '$latePets overdue',
        if (soon.length == 1)
          soon.first.days == 0
              ? '${_plural(soon.first.pets.length, 'pet')} due today'
              : '${soon.first.pets.length} due ${_relative(soon.first.days)}',
        if (soon.length > 1)
          '${soon.fold<int>(0, (n, g) => n + g.pets.length)} due soon',
      ];
      summary = parts.join(' · ');
      color = latePets > 0 ? const Color(0xFFB3261E) : const Color(0xFF8A5A00);
    } else if (onTrack > 0) {
      summary =
          'Next 12 months · ${onTrack == active.length ? (onTrack == 1 ? '${active.first.name} is protected' : 'all $onTrack pets protected') : '$onTrack of ${active.length} pets protected'}';
      color = Brand.green700;
    } else {
      summary = 'No upcoming shots on record';
    }

    final rows = [
      for (final g in groups)
        _ListRow(
          pets: g.pets,
          status: g.status,
          date: formatDate(g.date),
          rel: _relative(g.days),
        ),
      ...extras,
    ];
    return _Timeline(groups, rows, summary, color);
  }
}

// ── rail ───────────────────────────────────────────────────────────────────

/// Faces that would overlap on the rail share one spot ("+2").
class _Spot {
  _Spot(this.x, this.pets, this.status);
  double x;
  final List<Pet> pets;
  DueStatus status;
}

class _Rail extends StatelessWidget {
  const _Rail({required this.tl, required this.width, this.onPick});
  final _Timeline tl;
  final double width;
  final ValueChanged<Pet>? onPick;

  static const _face = 28.0;
  static const _railY = 40.0;

  @override
  Widget build(BuildContext context) {
    // One spot per due date (overdue ones all in the Late zone), merged
    // left to right while two would overlap.
    final spots = <_Spot>[];
    final late = tl.groups
        .where((g) => g.days < 0)
        .expand((g) => g.pets)
        .toList();
    if (late.isNotEmpty) {
      spots.add(_Spot(width * tl.base / 2, late, DueStatus.overdue));
    }
    for (final g in tl.groups.where((g) => g.days >= 0)) {
      final x = (width * tl.frac(g.days)).clamp(_face / 2, width - _face / 2);
      if (spots.isNotEmpty && x - spots.last.x < _face + 6) {
        spots.last.pets.addAll(g.pets);
        spots.last.status = _worst(spots.last.pets);
      } else {
        spots.add(_Spot(x, [...g.pets], g.status));
      }
    }

    // Month labels every other month, clear of "Today".
    final today = _today();
    final todayX = width * tl.base;
    final months = <(double, String)>[];
    for (var i = 1; i <= 12; i += 2) {
      final first = DateTime(today.year, today.month + i, 1);
      final x = width * tl.frac(first.difference(today).inDays);
      if (x > todayX + 44 && x < width - 14) {
        months.add((x, _monthShort(first.month)));
      }
    }

    return SizedBox(
      height: _railY + 26,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (tl.hasLate)
            Positioned(
              left: 0,
              top: 0,
              width: todayX,
              height: _railY + 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          // the rail
          Positioned(
            left: 0,
            right: 0,
            top: _railY,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Brand.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // dots
          for (final g in tl.groups.where((g) => g.days >= 0))
            Positioned(
              left: (width * tl.frac(g.days)).clamp(4.0, width - 4) - 4,
              top: _railY - 2.5,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor(g.status),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // Today tick + labels
          Positioned(
            left: todayX - 1,
            top: _railY - 6,
            child: Container(width: 2, height: 15, color: Brand.maroon700),
          ),
          Positioned(
            left: tl.hasLate ? todayX - 20 : 0,
            top: _railY + 10,
            child: SizedBox(
              width: tl.hasLate ? 40 : null,
              child: Text(
                'Today',
                textAlign: tl.hasLate ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Brand.maroon700,
                ),
              ),
            ),
          ),
          for (final (x, label) in months)
            Positioned(
              left: x - 16,
              top: _railY + 10,
              width: 32,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: Brand.inkSoft),
              ),
            ),
          // faces
          for (final s in spots)
            Positioned(
              left: s.x - _face / 2,
              top: 0,
              child: GestureDetector(
                onTap: onPick == null ? null : () => onPick!(s.pets.first),
                child: _FaceStack(
                  pets: s.pets,
                  color: _statusColor(s.status),
                  size: _face,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _monthShort(int m) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][(m - 1) % 12];

/// One face, with a "+N" badge when more pets share the spot.
class _FaceStack extends StatelessWidget {
  const _FaceStack({
    required this.pets,
    required this.color,
    required this.size,
  });
  final List<Pet> pets;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PetFace(pet: pets.first, size: size, ring: color),
          if (pets.length > 1)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '+${pets.length - 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The dog or cat picture in a tinted circle, ringed in the status colour.
class PetFace extends StatelessWidget {
  const PetFace({super.key, required this.pet, this.size = 28, this.ring});
  final Pet pet;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Brand.maroon100,
        shape: BoxShape.circle,
        border: Border.all(color: ring ?? Colors.white, width: 2),
      ),
      child: Image.asset(
        pet.isCat ? 'assets/images/pet_cat.png' : 'assets/images/pet_dog.png',
        cacheWidth: 96,
      ),
    );
  }
}

// ── list ───────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({required this.row, this.onPick});
  final _ListRow row;
  final ValueChanged<Pet>? onPick;

  @override
  Widget build(BuildContext context) {
    final names = row.pets.map((p) => p.name).join(', ');
    final late = row.rel.endsWith('late');
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPick == null ? null : () => onPick!(row.pets.first),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _statusColor(row.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    names,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Brand.ink,
                    ),
                  ),
                  Text(
                    row.rel.isEmpty ? row.date : '${row.date} · ${row.rel}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: late ? const Color(0xFFB3261E) : Brand.inkSoft,
                      fontWeight: late ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            for (final p in row.pets.take(3))
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: PetFace(pet: p, size: 26),
              ),
            if (row.pets.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '+${row.pets.length - 3}',
                  style: const TextStyle(fontSize: 12, color: Brand.inkSoft),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
