import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/owner_data.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/pet_card.dart';
import '../widgets/receipt_sheet.dart';
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
              const _Label('DETAILS'),
              const SizedBox(height: 10),
              _InfoGrid(pet: pet),
              const SizedBox(height: 26),
              _History(pet: pet),
              const SizedBox(height: 14),
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
              const _Label('CORRECTION REQUESTS'),
              const SizedBox(height: 10),
              RequestList(requests: OwnerData.instance.requestsFor(pet.id)),
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

/// The web portal's info grid: registration, colour, birth date and the
/// vaccination dates, two to a row.
class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final latest = pet.latest;
    final sex = (pet.sex ?? '').trim();
    final color = (pet.color ?? '').trim();
    final regNo = (pet.registrationNo ?? '').trim();
    // The receipt is generated from the records, as on the web (an encoded
    // pet has paid); tapping "Paid · DV-…" opens it.
    final user = AuthService.instance.user;
    final profile = OwnerData.instance.profile;
    final receipt = receiptForPet(
      pet,
      OwnerData.instance.pets ?? [pet],
      personId: user?.personId ?? '',
      ownerName: (profile?.fullName.isNotEmpty ?? false)
          ? profile!.fullName
          : (user?.username ?? ''),
    );
    final items = <(IconData, String, String)>[
      (
        Icons.check_circle_outline_rounded,
        'Registration fee',
        receipt == null ? 'Paid' : 'Paid · ${receipt.number}',
      ),
      if (regNo.isNotEmpty) (Icons.badge_outlined, 'Registration No.', regNo),
      (Icons.palette_outlined, 'Color / markings', color.isEmpty ? '—' : color),
      if (sex.isNotEmpty)
        (Icons.pets_outlined, 'Sex', sex[0].toUpperCase() + sex.substring(1)),
      if (pet.birthDate != null)
        (
          Icons.cake_outlined,
          'Born',
          formatDate(pet.birthDate!) +
              (pet.birthDateEstimated ? ' (est.)' : ''),
        ),
      (
        Icons.vaccines_outlined,
        'Last vaccinated',
        latest == null ? 'No shots yet' : formatDate(latest.date),
      ),
      (
        Icons.event_outlined,
        'Next due',
        pet.nextDue == null ? '—' : formatDate(pet.nextDue!),
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: Brand.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            children: [
              for (final (icon, label, value) in items)
                SizedBox(
                  width: w,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 17, color: Brand.maroon700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Brand.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (label == 'Registration fee' &&
                                  receipt != null)
                                GestureDetector(
                                  onTap: () =>
                                      showReceiptSheet(context, receipt),
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Brand.maroon700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Brand.maroon700,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  value,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Brand.ink,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Vaccination history, newest first, with the same columns as the web
/// table (date, vaccine, lot, vet, next due, Approval ID) stacked to fit a
/// phone. "LCVO card" switches to the paper-card layout owners know.
class _History extends StatefulWidget {
  const _History({required this.pet});
  final Pet pet;

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  bool _card = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final shots = pet.vaccinations.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _Label('VACCINATION HISTORY · ${shots.length}')),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: Brand.maroon700,
                selectedForegroundColor: Colors.white,
                foregroundColor: Brand.inkSoft,
                side: const BorderSide(color: Brand.border),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              segments: const [
                ButtonSegment(value: false, label: Text('List')),
                ButtonSegment(value: true, label: Text('LCVO card')),
              ],
              selected: {_card},
              onSelectionChanged: (s) => setState(() => _card = s.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_card)
          VaccineCard(pet: pet, owner: OwnerData.instance.profile)
        else if (shots.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Brand.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Brand.border),
            ),
            child: const Text(
              'No vaccinations on file yet.',
              style: TextStyle(color: Brand.inkSoft),
            ),
          )
        else
          for (final v in shots) _ShotTile(shot: v),
      ],
    );
  }
}

class _ShotTile extends StatelessWidget {
  const _ShotTile({required this.shot});
  final Vaccination shot;

  static Widget _cell(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Brand.inkSoft),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Brand.ink,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final lot = (shot.lotNo ?? '').trim();
    final vet = (shot.vetName ?? '').trim();
    final code = (shot.approvalCode ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  shot.vaccineName,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Brand.ink,
                  ),
                ),
              ),
              Text(
                formatDate(shot.date),
                style: const TextStyle(fontSize: 13, color: Brand.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _cell('Lot no.', lot.isEmpty ? '—' : lot),
              _cell(
                'Next due',
                shot.nextDue == null ? '—' : formatDate(shot.nextDue!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [_cell('Veterinarian', vet.isEmpty ? '—' : vet)]),
          if (code.isNotEmpty) ...[
            const Divider(height: 22),
            Row(
              children: [
                const Text(
                  'Approval ID',
                  style: TextStyle(fontSize: 11.5, color: Brand.inkSoft),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    code,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Brand.maroon700,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      await OwnerService.instance.setLifeStatus(
        petId: widget.pet.id,
        status: 'alive',
      );
      await OwnerData.instance.refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
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
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Brand.ink,
            ),
          ),
          if (pet.lifeNote != null && pet.lifeNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '“${pet.lifeNote}”',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Brand.inkSoft,
              ),
            ),
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
                TextButton(
                  onPressed: _undoing ? null : _undo,
                  child: Text(_undoing ? 'Undoing…' : 'Undo'),
                ),
              ],
            )
          else
            const Text(
              'Need to change this? Please contact LCVO.',
              style: TextStyle(fontSize: 13, color: Brand.inkSoft),
            ),
        ],
      ),
    );
  }
}
