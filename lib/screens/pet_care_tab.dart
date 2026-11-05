import 'package:flutter/material.dart';

import '../data/care_tips.dart';
import '../models/pet.dart';
import '../services/owner_data.dart';
import '../services/reminder_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/fade_in.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_message.dart';
import 'pet_detail_screen.dart';

/// Pet Care: is anything due, a countdown per pet, and general care tips.
/// Reads the shared owner data already loaded for Home — no requests of its own.
class PetCareTab extends StatefulWidget {
  const PetCareTab({super.key});

  @override
  State<PetCareTab> createState() => _PetCareTabState();
}

class _PetCareTabState extends State<PetCareTab> {
  @override
  void initState() {
    super.initState();
    OwnerData.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Brand.maroon700,
          onRefresh: OwnerData.instance.refresh,
          child: ListenableBuilder(
            listenable: OwnerData.instance,
            builder: (context, _) {
              final data = OwnerData.instance;
              final pets = data.pets;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    sliver: SliverToBoxAdapter(child: _body(data, pets)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(OwnerData data, List<Pet>? pets) {
    if (pets == null) {
      if (data.error != null) {
        return StateMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Can’t load your pets',
          text: data.error!,
          action: 'Try again',
          onAction: data.refresh,
        );
      }
      return const Column(
        children: [
          SkeletonBox(height: 84, radius: 20),
          SizedBox(height: 14),
          SkeletonBox(height: 84, radius: 18),
          SizedBox(height: 12),
          SkeletonBox(height: 84, radius: 18),
        ],
      );
    }

    // Most urgent first; pets with nothing scheduled last.
    const rank = {
      DueStatus.overdue: 0,
      DueStatus.dueSoon: 1,
      DueStatus.upToDate: 2,
      DueStatus.none: 3,
      DueStatus.historical: 3,
      DueStatus.passedAway: 4,
      DueStatus.lost: 4,
    };
    final sorted = [...pets]
      ..sort((a, b) {
        final r = rank[a.status]!.compareTo(rank[b.status]!);
        if (r != 0) return r;
        if (a.nextDue == null) return 1;
        if (b.nextDue == null) return -1;
        return a.nextDue!.compareTo(b.nextDue!);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pets.isNotEmpty) FadeIn(child: _Banner(pets: pets)),
        if (pets.isEmpty)
          const StateMessage(
            icon: Icons.pets_outlined,
            title: 'No pets yet',
            text:
                'Reminders will appear here once your pets are registered at an LCVO vaccination drive or the City Veterinary Office.',
          )
        else ...[
          const SizedBox(height: 22),
          const _Label('NEXT SHOTS'),
          const SizedBox(height: 10),
          for (var i = 0; i < sorted.length; i++)
            FadeIn(
              index: i + 1,
              child: _ReminderCard(pet: sorted[i]),
            ),
          const SizedBox(height: 10),
          const RemindSwitch(),
        ],
        const SizedBox(height: 22),
        const _Label('CARE TIPS'),
        const SizedBox(height: 10),
        const _Tips(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pet Care',
            style: TextStyle(
              fontFamily: Brand.serif,
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Brand.maroon900,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Vaccination reminders for your pets',
            style: TextStyle(fontSize: 14, color: Brand.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: Brand.inkSoft,
    ),
  );
}

String _plural(int n, String w) => '$n $w${n == 1 ? '' : 's'}';
String _inTime(int days) => days == 0
    ? 'today'
    : days <= 45
    ? 'in ${_plural(days, 'day')}'
    : 'in ${_plural((days / 30.44).round(), 'month')}';

/// The web Pet Care summary: the most pressing thing, then the next visit
/// (pets due the same day are one trip).
class _Banner extends StatelessWidget {
  const _Banner({required this.pets});
  final List<Pet> pets;

  String _nextVisit(List<Pet> list) {
    final first = ([
      ...list,
    ]..sort((a, b) => a.nextDue!.compareTo(b.nextDue!))).first;
    final together = list.where((p) => p.nextDue == first.nextDue).toList();
    return '${formatDate(first.nextDue!)} · ${together.length == 1 ? together.first.name : '${together.length} pets'}';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = pets.where((p) => p.status == DueStatus.overdue).toList();
    final soon = pets.where((p) => p.status == DueStatus.dueSoon).toList();
    final ok = pets
        .where((p) => p.status == DueStatus.upToDate && p.nextDue != null)
        .toList();
    final active = pets.where((p) => p.isActive).toList();
    final (
      IconData icon,
      String title,
      String sub,
      Color fg,
      Color bg,
    ) = overdue.isNotEmpty
        ? (
            Icons.error_outline_rounded,
            '${_plural(overdue.length, 'vaccination')} overdue',
            'Bring ${overdue.length == 1 ? overdue.first.name : 'them'} to LCVO as soon as possible',
            const Color(0xFFB3261E),
            const Color(0xFFFDECEA),
          )
        : soon.isNotEmpty
        ? (
            Icons.schedule_rounded,
            '${_plural(soon.length, 'vaccination')} due soon',
            'Next visit ${_nextVisit(soon)}',
            const Color(0xFF8A5A00),
            const Color(0xFFFDF0D0),
          )
        : ok.isNotEmpty
        ? (
            Icons.verified_outlined,
            ok.length == active.length
                ? (active.length == 1
                      ? '${active.first.name} is up to date'
                      : 'All ${active.length} pets up to date')
                : '${ok.length} of ${active.length} pets up to date',
            'Next visit ${_nextVisit(ok)}',
            Brand.green700,
            Brand.green100,
          )
        // Only pre-2024 records (or none): nothing is "up to date" — say what's true.
        : (
            Icons.history_rounded,
            'No recent vaccinations on record',
            'Visit LCVO to bring your pets up to date',
            Brand.inkSoft,
            const Color(0xFFF1F5F9),
          );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 13.5, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One pet's protection card, as on the web: the next shot, how much of
/// the protection window (last shot -> next due) is left as 12 blocks, and
/// the last shot. Gold when due within 30 days, red once overdue.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.pet});
  final Pet pet;

  static const _blocks = 12;

  @override
  Widget build(BuildContext context) {
    final status = pet.status;
    final days = pet.daysRemaining;
    final latest = pet.latest;
    // "rabi" catches both "Anti-Rabies Vaccine" and the RABISIN brand.
    final shot =
        RegExp('rabi', caseSensitive: false).hasMatch(latest?.vaccineName ?? '')
        ? 'anti-rabies shot'
        : 'shot';
    final accent = switch (status) {
      DueStatus.overdue => const Color(0xFFB3261E),
      DueStatus.dueSoon => const Color(0xFFC89B2A),
      DueStatus.upToDate => Brand.green700,
      _ => Brand.inkSoft,
    };

    var kicker = 'Next $shot';
    var headline = '—';
    var when = '';
    var note = '';
    int? left; // blocks of protection left; null = no meter
    if (!pet.isActive) {
      kicker = 'Status';
      headline = pet.isPassedAway ? 'Passed away' : 'Lost';
      note = 'Kept here for your records.';
    } else if (status == DueStatus.historical) {
      kicker = 'Last shot on record';
      headline = latest == null ? '—' : formatDate(latest.date);
      when = 'before 2024';
      note = 'Visit LCVO to bring the record up to date.';
    } else if (days == null) {
      kicker = 'Vaccinations';
      headline = 'None on file';
      note = 'Bring your pet to LCVO or the next vaccination drive.';
    } else {
      headline = formatDate(pet.nextDue!);
      final span = latest == null
          ? 365
          : pet.nextDue!.difference(latest.date).inDays.clamp(1, 100000);
      left = ((days / span) * _blocks).round().clamp(0, _blocks);
      if (status == DueStatus.overdue) {
        kicker = '${shot[0].toUpperCase()}${shot.substring(1)} overdue';
        when = '${_plural(-days, 'day')} late';
        note = 'Protection may have lapsed — bring ${pet.name} to LCVO.';
      } else {
        when = _inTime(days);
        final since = latest == null
            ? null
            : DateTime.now().difference(latest.date).inDays;
        if (status == DueStatus.dueSoon) {
          note = days == 0
              ? 'Due today — plan a visit.'
              : 'Due ${_inTime(days)} — plan a visit.';
        } else if (since != null && since <= 30) {
          note =
              'Vaccinated ${since == 0 ? 'today' : '${_plural(since, 'day')} ago'} — fully protected.';
        } else {
          note =
              '${_plural((days / 30.44).round(), 'month')} of protection left';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: status == DueStatus.overdue
                ? const Color(0xFFE6B3B3)
                : status == DueStatus.dueSoon
                ? const Color(0xFFEAD3A0)
                : Brand.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PetDetailScreen(petId: pet.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Brand.maroon100,
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Image.asset(
                        pet.isCat
                            ? 'assets/images/pet_cat.png'
                            : 'assets/images/pet_dog.png',
                        cacheWidth: 132,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Brand.ink,
                            ),
                          ),
                          Text(
                            [
                              pet.species,
                              if ((pet.breed ?? '').isNotEmpty) pet.breed!,
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Brand.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  kicker.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontFamily: Brand.serif,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Brand.maroon900,
                      ),
                    ),
                    if (when.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        when,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ],
                ),
                if (left != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < _blocks; i++)
                        Expanded(
                          child: Container(
                            height: 10,
                            margin: EdgeInsets.only(
                              right: i == _blocks - 1 ? 0 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: i < _blocks - left
                                  ? const Color(0xFFE2E8F0)
                                  : accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  note,
                  style: const TextStyle(fontSize: 13, color: Brand.ink),
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        latest == null
                            ? 'No shots on file'
                            : 'Last shot ${formatDate(latest.date)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Brand.inkSoft,
                        ),
                      ),
                    ),
                    const Text(
                      'Records',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Brand.maroon700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Brand.maroon700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vaccination first, then warning signs; the rest keep their order (web).
final _tipsOrdered = [
  ...careTips.where((t) => t.title == 'Vaccination Schedule'),
  ...careTips.where((t) => t.title == 'Warning Signs'),
  ...careTips.where(
    (t) => t.title != 'Vaccination Schedule' && t.title != 'Warning Signs',
  ),
];

/// Expandable list: the summary shows closed, the longer advice when open.
class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Brand.border),
        child: Column(
          children: [
            for (var i = 0; i < _tipsOrdered.length; i++)
              ExpansionTile(
                key: PageStorageKey('tip-$i'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                iconColor: Brand.maroon700,
                collapsedIconColor: Brand.inkSoft,
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Brand.maroon100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _tipsOrdered[i].icon,
                    color: Brand.maroon700,
                    size: 21,
                  ),
                ),
                title: Text(
                  _tipsOrdered[i].title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Brand.ink,
                  ),
                ),
                subtitle: Text(
                  _tipsOrdered[i].summary,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Brand.inkSoft,
                  ),
                ),
                children: [
                  Text(
                    _tipsOrdered[i].detail,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Brand.ink,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// "Remind me" switch: on-phone notifications 7 days before each due date
/// and on the day. Turning it on asks Android for notification permission.
class RemindSwitch extends StatelessWidget {
  const RemindSwitch({super.key});

  Future<void> _toggle(BuildContext context, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ReminderService.instance.setEnabled(
      value,
      OwnerData.instance.pets,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are turned off for DIGIVET. Allow them in your phone’s settings to get reminders.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReminderService.instance,
      builder: (context, _) {
        final on = ReminderService.instance.enabled;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Brand.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Brand.maroon100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Brand.maroon700,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remind me before shots are due',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      '7 days before and on the due day, at 9:00 AM',
                      style: TextStyle(fontSize: 12.5, color: Brand.inkSoft),
                    ),
                  ],
                ),
              ),
              Switch(
                value: on,
                activeThumbColor: Colors.white,
                activeTrackColor: Brand.maroon700,
                onChanged: (v) => _toggle(context, v),
              ),
            ],
          ),
        );
      },
    );
  }
}
