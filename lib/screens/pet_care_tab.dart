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
        if (pets.isNotEmpty) ...[
          const FadeIn(child: RemindSwitch()),
          const SizedBox(height: 14),
          FadeIn(index: 1, child: _Banner(pets: pets)),
        ],
        if (pets.isEmpty)
          const StateMessage(
            icon: Icons.pets_outlined,
            title: 'No pets yet',
            text:
                'Reminders will appear here once your pets are registered at an LCVO vaccination drive or the City Veterinary Office.',
          )
        else ...[
          const SizedBox(height: 22),
          const _Label('REMINDERS'),
          const SizedBox(height: 10),
          for (var i = 0; i < sorted.length; i++)
            FadeIn(
              index: i + 1,
              child: _ReminderCard(pet: sorted[i]),
            ),
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

/// One-glance summary, coloured by the most urgent pet.
class _Banner extends StatelessWidget {
  const _Banner({required this.pets});
  final List<Pet> pets;

  @override
  Widget build(BuildContext context) {
    final overdue = pets.where((p) => p.status == DueStatus.overdue).length;
    final soon = pets.where((p) => p.status == DueStatus.dueSoon).length;
    final (icon, title, sub, fg, bg) = overdue > 0
        ? (
            Icons.error_outline_rounded,
            '$overdue vaccination${overdue == 1 ? '' : 's'} overdue',
            'Schedule a visit as soon as possible.',
            const Color(0xFFB3261E),
            const Color(0xFFFDECEA),
          )
        : soon > 0
        ? (
            Icons.schedule_rounded,
            '$soon vaccination${soon == 1 ? '' : 's'} due soon',
            'Due within the next 30 days.',
            const Color(0xFF8A5A00),
            const Color(0xFFFDF0D0),
          )
        : pets.isNotEmpty && pets.every((p) => p.isHistorical || !p.isActive)
        // Only records from before 2024: nothing is "protected" — say what's true.
        ? (
            Icons.history_rounded,
            'No recent vaccinations on record',
            "Your pets' last LCVO shots were before 2024. Visit LCVO to update.",
            Brand.inkSoft,
            const Color(0xFFF1F5F9),
          )
        : (
            Icons.check_circle_outline_rounded,
            pets.length == 1
                ? 'Your pet is protected'
                : 'All pets are protected',
            'Nothing is due in the next 30 days.',
            Brand.green700,
            Brand.green100,
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

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final days = pet.daysRemaining;
    final status = pet.status;
    final accent = switch (status) {
      DueStatus.overdue => const Color(0xFFB3261E),
      DueStatus.dueSoon => const Color(0xFF8A5A00),
      DueStatus.upToDate => Brand.maroon700,
      DueStatus.none || DueStatus.passedAway || DueStatus.lost || DueStatus.historical => Brand.inkSoft,
    };
    final big = days == null ? '—' : (days == 0 ? 'Today' : '${days.abs()}');
    final unit = days == null
        ? 'no schedule'
        : (days == 0
              ? 'due'
              : days < 0
              ? (days == -1 ? 'day overdue' : 'days overdue')
              : (days == 1 ? 'day' : 'days'));
    final next = pet.latest == null
        ? 'No schedule yet'
        : pet.isHistorical
        ? 'Last shot ${formatDate(pet.latest!.date)} · before 2024'
        : 'Next: ${pet.latest!.vaccineName}${pet.nextDue == null ? '' : ' · ${formatDate(pet.nextDue!)}'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: status == DueStatus.overdue
                ? const Color(0xFFE6B3B3)
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
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Brand.maroon100,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    pet.isCat
                        ? 'assets/images/pet_cat.png'
                        : 'assets/images/pet_dog.png',
                    cacheWidth: 150,
                  ),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 2),
                      Text(
                        next,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Brand.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      big,
                      style: TextStyle(
                        fontFamily: Brand.serif,
                        fontSize: big == 'Today' || big == '—' ? 22 : 32,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(unit, style: TextStyle(fontSize: 12, color: accent)),
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
            for (var i = 0; i < careTips.length; i++)
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
                    careTips[i].icon,
                    color: Brand.maroon700,
                    size: 21,
                  ),
                ),
                title: Text(
                  careTips[i].title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Brand.ink,
                  ),
                ),
                subtitle: Text(
                  careTips[i].summary,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Brand.inkSoft,
                  ),
                ),
                children: [
                  Text(
                    careTips[i].detail,
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
