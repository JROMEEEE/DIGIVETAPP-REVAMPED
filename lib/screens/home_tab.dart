import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/care_tips.dart';
import '../models/pet.dart';
import '../services/auth_service.dart';
import '../services/owner_data.dart';
import '../theme.dart';
import '../widgets/fade_in.dart';
import '../widgets/lcvo_card.dart';
import '../widgets/pet_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_message.dart';
import '../widgets/vaccination_timeline.dart';
import 'pet_detail_screen.dart';

/// Owner Home, the phone version of the web portal's dashboard: the big pet
/// card (opens on the pet that needs attention most), the 12-month
/// Vaccination status timeline, the Tip of the day, and the LCVO card.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _carousel = GlobalKey<_PetCarouselState>();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    OwnerData.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Tapping a pet on the timeline puts it on the big card, like hovering a
  // face on the web dashboard.
  void _showPet(Pet pet) {
    HapticFeedback.selectionClick();
    _carousel.currentState?.showPet(pet.id);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
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
              controller: _scroll,
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
          child: KeyedSubtree(
            key: ValueKey(pets.map((p) => p.id).join(',')),
            child: _PetCarousel(key: _carousel, pets: pets),
          ),
        ),
        const SizedBox(height: 22),
        FadeIn(
          index: 1,
          child: VaccinationTimeline(pets: pets, onPick: _showPet),
        ),
        const SizedBox(height: 14),
        const FadeIn(index: 2, child: _TipOfTheDay()),
        const SizedBox(height: 14),
        const FadeIn(index: 3, child: SizedBox(height: 196, child: LcvoCard())),
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

  /// Turn to [petId]'s card (from the timeline).
  void showPet(String petId) {
    final i = widget.pets.indexWhere((p) => p.id == petId);
    if (i < 0 || !_controller.hasClients) return;
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pets = widget.pets;
    final pages = pets.length; // the LCVO card now has its own place below
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PetDetailScreen(petId: pets[i].id),
                  ),
                ),
                child: PetCard(pet: pets[i]),
              ),
            ),
          ),
        ),
        if (pages > 1) ...[
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

/// Same tip all day (changes at midnight), picked by the day of the year,
/// like the web dashboard's Tip of the day.
class _TipOfTheDay extends StatelessWidget {
  const _TipOfTheDay();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final tip = careTips[dayOfYear % careTips.length];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Brand.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(tip.icon, color: Brand.maroon700, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIP OF THE DAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xFF8A5A00),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontFamily: Brand.serif,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Brand.maroon900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.detail,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Brand.ink,
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
