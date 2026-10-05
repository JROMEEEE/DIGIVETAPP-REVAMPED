import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/owner_data.dart';
import '../theme.dart';
import '../widgets/fade_in.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_message.dart';
import 'pet_detail_screen.dart';

/// My Pets: every pet at a glance; tap one for its profile and history.
class MyPetsTab extends StatefulWidget {
  const MyPetsTab({super.key});

  @override
  State<MyPetsTab> createState() => _MyPetsTabState();
}

class _MyPetsTabState extends State<MyPetsTab> {
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
                  SliverToBoxAdapter(child: _Header(count: pets?.length)),
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
          SkeletonBox(height: 84, radius: 18),
          SizedBox(height: 12),
          SkeletonBox(height: 84, radius: 18),
          SizedBox(height: 12),
          SkeletonBox(height: 84, radius: 18),
        ],
      );
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
      children: [
        for (var i = 0; i < pets.length; i++)
          FadeIn(
            index: i,
            child: _PetRow(
              pet: pets[i],
              pending: data
                  .requestsFor(pets[i].id)
                  .any((r) => r.status.name == 'pending'),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Pets',
            style: TextStyle(
              fontFamily: Brand.serif,
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Brand.maroon900,
            ),
          ),
          if (count != null) ...[
            const SizedBox(height: 2),
            Text(
              count == 1 ? '1 pet' : '$count pets',
              style: const TextStyle(fontSize: 14, color: Brand.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({required this.pet, required this.pending});
  final Pet pet;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final st = statusStyle(pet.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Brand.border),
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
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Brand.maroon100,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    pet.isCat
                        ? 'assets/images/pet_cat.png'
                        : 'assets/images/pet_dog.png',
                    cacheWidth: 160,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Brand.ink,
                        ),
                      ),
                      Text(
                        [
                          pet.species,
                          if ((pet.breed ?? '').isNotEmpty) pet.breed!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Brand.inkSoft,
                        ),
                      ),
                      if (pending)
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Text(
                            'Update pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A5A00),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Brand.inkSoft,
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
