import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/owner_data.dart';
import '../theme.dart';
import '../widgets/pet_card.dart';
import '../widgets/request_list.dart';
import '../widgets/vaccine_card.dart';
import '../services/api.dart';
import '../services/owner_service.dart';
import '../utils/format.dart';
import 'life_status_sheet.dart';
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
              const SizedBox(height: 26),
              const _Label('STATUS'),
              const SizedBox(height: 10),
              _LifeStatus(pet: pet),
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

/// Alive: a quiet "Update status" link. Passed away / lost: what was recorded,
/// plus the owner's 7-day undo (or a note to contact LCVO).
class _LifeStatus extends StatefulWidget {
  const _LifeStatus({required this.pet});
  final Pet pet;

  @override
  State<_LifeStatus> createState() => _LifeStatusState();
}

class _LifeStatusState extends State<_LifeStatus> {
  bool _undoing = false;

  Future<void> _undo() async {
    setState(() => _undoing = true);
    try {
      await OwnerService.instance.setLifeStatus(petId: widget.pet.id, status: 'alive');
      await OwnerData.instance.refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _undoing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    if (pet.isActive) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => showLifeStatusSheet(context, pet),
          icon: const Icon(Icons.favorite_border_rounded, size: 18),
          label: const Text('Update status'),
          style: TextButton.styleFrom(foregroundColor: Brand.inkSoft),
        ),
      );
    }
    final when = pet.isPassedAway ? pet.deceasedDate : pet.lostDate;
    final title = pet.isPassedAway
        ? 'Passed away${when != null ? ' · ${formatDate(when)}' : ''}'
        : 'Lost${when != null ? ' · since ${formatDate(when)}' : ''}';
    final until = pet.lifeChangedAt?.add(const Duration(days: 7));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Brand.ink)),
          if (pet.lifeNote != null && pet.lifeNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('“${pet.lifeNote}”', style: const TextStyle(fontStyle: FontStyle.italic, color: Brand.inkSoft)),
          ],
          const SizedBox(height: 10),
          if (pet.canChangeStatus)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Marked by mistake?${until != null ? ' You can undo this until ${formatDate(until)}.' : ''}',
                    style: const TextStyle(fontSize: 13, color: Brand.inkSoft),
                  ),
                ),
                TextButton(onPressed: _undoing ? null : _undo, child: Text(_undoing ? 'Undoing…' : 'Undo')),
              ],
            )
          else
            const Text('Need to change this? Please contact LCVO.', style: TextStyle(fontSize: 13, color: Brand.inkSoft)),
        ],
      ),
    );
  }
}
