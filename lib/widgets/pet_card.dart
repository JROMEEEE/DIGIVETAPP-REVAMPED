import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'protection_ring.dart';

/// Ring/accent colour for a status, tuned to read on the maroon card.
Color ringColor(DueStatus s) => switch (s) {
  DueStatus.overdue => const Color(0xFFF4A9A9),
  DueStatus.dueSoon => Brand.gold300,
  DueStatus.upToDate => Brand.cream,
  DueStatus.none || DueStatus.passedAway || DueStatus.lost => Colors.white38,
};

/// One pet on the owner's Home. The pet itself is the hero: a large dog/cat
/// illustration fills the right side, with the name and status beside it and
/// the protection ring plus last/next vaccine along the bottom.
class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final status = pet.status;
    final color = ringColor(status);
    final latest = pet.latest;
    final days = pet.daysRemaining;
    final overdue = status == DueStatus.overdue;
    final statusLabel = switch (status) {
      DueStatus.overdue => 'Overdue',
      DueStatus.dueSoon => 'Due soon',
      DueStatus.upToDate => 'Up to date',
      DueStatus.none => '',
      DueStatus.passedAway => 'Passed away',
      DueStatus.lost => 'Lost',
    };
    final ringNumber = days == null ? '—' : (days == 0 ? '0' : '${days.abs()}');

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: Brand.maroon700,
        child: Stack(
          children: [
            // Soft disc behind the pet, like the web hero's dark circle.
            Positioned(
              right: -34,
              top: -18,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 8,
              child: Image.asset(
                pet.isCat
                    ? 'assets/images/pet_cat.png'
                    : 'assets/images/pet_dog.png',
                width: 150,
                cacheWidth: 450,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            pet.species,
                            if ((pet.breed ?? '').isNotEmpty) pet.breed!,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: Brand.serif,
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (statusLabel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (latest == null)
                    const Text(
                      'No vaccinations recorded yet.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProtectionRing(
                          size: 62,
                          stroke: 5,
                          color: color,
                          fraction: overdue ? 0 : (pet.protectionFraction ?? 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ringNumber,
                                style: TextStyle(
                                  fontFamily: Brand.serif,
                                  fontSize: ringNumber.length > 3 ? 16 : 21,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              Text(
                                overdue ? 'overdue' : 'days',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _Fact(
                            label: 'LAST VACCINE',
                            value: latest.vaccineName,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _Fact(
                          label: 'NEXT DUE',
                          value: pet.nextDue == null
                              ? '—'
                              : formatDate(pet.nextDue!),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Brand.gold300,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
