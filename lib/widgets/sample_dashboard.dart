import 'package:flutter/material.dart';

import '../theme.dart';
import 'protection_ring.dart';

/// Static miniature of the owner dashboard, shown on the landing screen so
/// visitors know what they will see. Sample data only — never real records.
class SampleDashboard extends StatelessWidget {
  const SampleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Brand.border),
          ),
          child: Column(
            children: [
              const _Hero(),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(child: _PetsCard()),
                  SizedBox(width: 8),
                  Expanded(child: _UpNextCard()),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -11,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Brand.maroon700,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'SAMPLE PREVIEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
      decoration: const BoxDecoration(
        color: Brand.maroon700,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bantay',
                  style: TextStyle(
                    fontFamily: Brand.serif,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const _Fact(label: 'LAST VACCINE', value: 'Anti-Rabies'),
                const SizedBox(height: 4),
                const _Fact(label: 'NEXT DUE', value: 'Sep 17, 2027'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'View records',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Brand.maroon700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const _Dial(),
        ],
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
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Brand.gold300,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// The protection ring: how much of the protection window is left.
class _Dial extends StatelessWidget {
  const _Dial();

  @override
  Widget build(BuildContext context) {
    return ProtectionRing(
      size: 92,
      fraction: 0.98,
      color: Brand.cream,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '357',
            style: TextStyle(
              fontFamily: Brand.serif,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            'days protected',
            style: TextStyle(fontSize: 8, color: Colors.white70),
          ),
          Text(
            'Up to Date',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Brand.cream,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Brand.ink,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _PetsCard extends StatelessWidget {
  const _PetsCard();

  @override
  Widget build(BuildContext context) {
    return const _MiniCard(
      title: 'My Pets',
      child: Column(
        children: [
          _PetRow(asset: 'assets/images/pet_dog.png', name: 'Bantay', ok: true),
          SizedBox(height: 4),
          _PetRow(
            asset: 'assets/images/pet_cat.png',
            name: 'Mingming',
            ok: false,
          ),
        ],
      ),
    );
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({required this.asset, required this.name, required this.ok});
  final String asset;
  final String name;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Brand.maroon100,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Image.asset(asset, cacheWidth: 60),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Brand.ink,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: ok ? Brand.green100 : const Color(0xFFFDF0D0),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              ok ? 'Up to date' : 'Due soon',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: ok ? Brand.green700 : const Color(0xFF8A5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard();

  @override
  Widget build(BuildContext context) {
    return _MiniCard(
      title: 'Up next',
      child: Row(
        children: const [
          Text(
            '357',
            style: TextStyle(
              fontFamily: Brand.serif,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Brand.maroon700,
              height: 1,
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'days until next dose',
                  style: TextStyle(fontSize: 8, color: Brand.inkSoft),
                ),
                Text(
                  'Bantay',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
