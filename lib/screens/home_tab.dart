import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/correction_request.dart';
import '../models/pet.dart';
import '../services/auth_service.dart';
import '../services/owner_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/fade_in.dart';
import '../widgets/lcvo_card.dart';
import '../widgets/pet_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_message.dart';
import 'pet_detail_screen.dart';

/// Owner Home. Phase 1: header, loading / error / empty states, and the
/// data plumbing. The swipeable pet cards, "Up next" and "Recent" replace the
/// simple list below in the next phases.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    OwnerData.instance.ensureLoaded();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : (h < 18 ? 'Good afternoon' : 'Good evening');
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    final name = (user?.firstName?.trim().isNotEmpty ?? false)
        ? user!.firstName!
        : (user?.username ?? '');
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Brand.maroon700,
          onRefresh: OwnerData.instance.refresh,
          child: ListenableBuilder(
            listenable: OwnerData.instance,
            builder: (context, _) => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(greeting: _greeting, name: name),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  sliver: SliverToBoxAdapter(child: _body(OwnerData.instance)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(OwnerData data) {
    final pets = data.pets;
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
      return const _LoadingSkeleton();
    }
    if (pets.isEmpty) {
      return const StateMessage(
        icon: Icons.pets_outlined,
        title: 'No pets yet',
        text:
            'Your pets will appear here once they’re registered at an LCVO vaccination drive or the City Veterinary Office.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeIn(
          child: _PetCarousel(
            key: ValueKey(pets.map((p) => p.id).join(',')),
            pets: pets,
          ),
        ),
        FadeIn(index: 1, child: _UpNext(pets: pets)),
        FadeIn(index: 2, child: _Recent(pets: pets)),
        FadeIn(index: 3, child: _Requests(requests: data.requests)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.name});
  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(fontSize: 14, color: Brand.inkSoft),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: Brand.serif,
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Brand.maroon900,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showAccountSheet(context, name),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Brand.maroon700,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: Brand.serif,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
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

// Account sheet: who is signed in, and log out. Moves into Settings later.
void _showAccountSheet(BuildContext context, String name) {
  final user = AuthService.instance.user;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: Brand.serif,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Brand.maroon900,
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 2),
              Text(
                '@${user.username}',
                style: const TextStyle(color: Brand.inkSoft),
              ),
            ],
            const SizedBox(height: 22),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Brand.maroon700,
                side: const BorderSide(color: Brand.maroon700, width: 1.5),
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(ctx).pop();
                AuthService.instance.logout();
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    ),
  );
}

// Shapes of what is loading: a big card, then two rows.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 220, radius: 22),
        SizedBox(height: 18),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 12),
        SkeletonBox(height: 72, radius: 16),
      ],
    );
  }
}

/// Opens on the pet that most needs attention: overdue first, then due soon.
int _priorityIndex(List<Pet> pets) {
  var i = pets.indexWhere((p) => p.status == DueStatus.overdue);
  if (i < 0) i = pets.indexWhere((p) => p.status == DueStatus.dueSoon);
  return i < 0 ? 0 : i;
}

class _PetCarousel extends StatefulWidget {
  const _PetCarousel({super.key, required this.pets});
  final List<Pet> pets;

  @override
  State<_PetCarousel> createState() => _PetCarouselState();
}

class _PetCarouselState extends State<_PetCarousel> {
  late int _page = _priorityIndex(widget.pets);
  late final PageController _controller = PageController(
    initialPage: _page,
    viewportFraction: 0.92,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pets = widget.pets;
    final pages = pets.length + 1; // the pets, then the LCVO Facebook card
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _controller,
            clipBehavior: Clip.none,
            itemCount: pages,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _page = i);
            },
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              child: i < pets.length
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PetDetailScreen(petId: pets[i].id),
                        ),
                      ),
                      child: PetCard(pet: pets[i]),
                    )
                  : const LcvoCard(),
            ),
          ),
        ),
        ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pages; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page ? Brand.maroon700 : Brand.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The next dose due across all pets (soonest date first, overdue included).
class _UpNext extends StatelessWidget {
  const _UpNext({required this.pets});
  final List<Pet> pets;

  @override
  Widget build(BuildContext context) {
    final due = pets.where((p) => p.nextDue != null).toList()
      ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    if (due.isEmpty) return const SizedBox.shrink();
    final pet = due.first;
    final days = pet.daysRemaining!;
    final st = statusStyle(pet.status);
    final accent = switch (pet.status) {
      DueStatus.overdue => const Color(0xFFB3261E),
      DueStatus.dueSoon => const Color(0xFF8A5A00),
      _ => Brand.maroon700,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UP NEXT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Brand.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Brand.border),
            ),
            child: Row(
              children: [
                Text(
                  days == 0 ? 'Today' : '${days.abs()}',
                  style: TextStyle(
                    fontFamily: Brand.serif,
                    fontSize: days == 0 ? 30 : 40,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        days == 0
                            ? 'dose due'
                            : (days < 0
                                  ? 'days overdue'
                                  : (days == 1
                                        ? 'day until next dose'
                                        : 'days until next dose')),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Brand.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Brand.ink,
                        ),
                      ),
                      Text(
                        formatDate(pet.nextDue!),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Brand.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: st.bg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    st.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: st.fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: Brand.inkSoft,
      ),
    );
  }
}

/// The last three shots across all pets, newest first, on a dotted timeline.
class _Recent extends StatelessWidget {
  const _Recent({required this.pets});
  final List<Pet> pets;

  @override
  Widget build(BuildContext context) {
    final shots = [
      for (final p in pets)
        for (final v in p.vaccinations) (pet: p.name, shot: v),
    ]..sort((a, b) => b.shot.date.compareTo(a.shot.date));
    if (shots.isEmpty) return const SizedBox.shrink();
    final recent = shots.take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('RECENT'),
          const SizedBox(height: 12),
          for (var i = 0; i < recent.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            color: Brand.maroon700,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < recent.length - 1)
                          Expanded(
                            child: Container(width: 2, color: Brand.border),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < recent.length - 1 ? 16 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recent[i].shot.vaccineName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Brand.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${recent[i].pet} · ${formatDate(recent[i].shot.date)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Brand.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown only when the owner has sent correction requests.
class _Requests extends StatelessWidget {
  const _Requests({required this.requests});
  final List<CorrectionRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('CORRECTION REQUESTS'),
          const SizedBox(height: 10),
          for (final r in requests.take(2))
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Brand.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Brand.ink,
                          ),
                        ),
                        Text(
                          r.fields.isEmpty
                              ? 'Profile update'
                              : r.fields.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Brand.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RequestChip(r.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestChip extends StatelessWidget {
  const _RequestChip(this.status);
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      RequestStatus.pending => (
        'Pending',
        const Color(0xFF8A5A00),
        const Color(0xFFFDF0D0),
      ),
      RequestStatus.approved => ('Approved', Brand.green700, Brand.green100),
      RequestStatus.rejected => (
        'Rejected',
        const Color(0xFFB3261E),
        const Color(0xFFFDECEA),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
