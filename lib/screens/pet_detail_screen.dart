import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/owner_data.dart';
import '../theme.dart';
import '../widgets/pet_card.dart';
import '../widgets/request_list.dart';
import '../widgets/vaccine_card.dart';
import 'request_sheet.dart';

/// One pet: the hero card, its profile, and its full vaccination history.
/// Reads live from [OwnerData], so a refresh elsewhere updates this page.
class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Brand.maroon900),
      ),
      body: ListenableBuilder(
        listenable: OwnerData.instance,
        builder: (context, _) {
          final match = (OwnerData.instance.pets ?? const <Pet>[]).where(
            (p) => p.id == petId,
          );
          if (match.isEmpty) {
            return const Center(
              child: Text(
                'This pet is no longer available.',
                style: TextStyle(color: Brand.inkSoft),
              ),
            );
          }
          final pet = match.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              SizedBox(height: 250, child: PetCard(pet: pet)),
              const SizedBox(height: 26),
              const _Label('VACCINE CARD'),
              const SizedBox(height: 10),
              VaccineCard(pet: pet, owner: OwnerData.instance.profile),
              const SizedBox(height: 26),
              const _Label('CORRECTION REQUESTS'),
              const SizedBox(height: 10),
              RequestList(requests: OwnerData.instance.requestsFor(pet.id)),
              const SizedBox(height: 12),
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
                onPressed: () => showRequestSheet(context, pet),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Request a correction'),
              ),
            ],
          );
        },
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
