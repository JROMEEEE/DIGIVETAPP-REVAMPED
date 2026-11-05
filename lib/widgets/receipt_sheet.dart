import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Payment acknowledgement for new-pet fees, the same as the web portal's
/// (digivetonline/client/src/components/Receipt.jsx — change both).
/// Nothing about payments is stored: a pet that is encoded has paid, so the
/// receipt is generated from the records — one per owner visit (the pets
/// whose first vaccination was on the same day at the same drive / walk-in),
/// at the standard fee. Titled "Payment Acknowledgement", not "Official
/// Receipt": an official receipt is the City Treasury's numbered form.
const standardFee = 50;

class Receipt {
  Receipt({
    required this.number,
    required this.date,
    required this.drive,
    required this.visit,
    required this.owner,
    required this.pets,
  });
  final String number;
  final DateTime date;
  final bool drive;
  final String visit;
  final String owner;
  final List<Pet> pets;
  int get total => standardFee * pets.length;
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

/// Same number every time: date + owner (+ drive), e.g. DV-20261013-3F9A2C
/// (walk-in) or DV-20261013-3F9A2C-D7 (drive).
String receiptNo(DateTime date, String personId, String? sessionId) {
  final owner = personId.replaceAll('-', '');
  final who = owner.substring(0, owner.length < 6 ? owner.length : 6);
  final drive = sessionId == null
      ? ''
      : '-${sessionId.replaceAll('-', '').substring(0, 2)}';
  return 'DV-${_ymd(date)}-$who$drive'.toUpperCase();
}

String _speciesWord(String sp) {
  if (RegExp(r'^(dog|aso|canine)$', caseSensitive: false).hasMatch(sp)) {
    return 'Canine';
  }
  if (RegExp(r'^(cat|pusa|feline)$', caseSensitive: false).hasMatch(sp)) {
    return 'Feline';
  }
  return sp.isEmpty ? 'Pet' : sp;
}

/// The receipt that covers [pet]'s registration, or null if it has no shots.
Receipt? receiptForPet(
  Pet pet,
  List<Pet> all, {
  required String personId,
  required String ownerName,
}) {
  final first = pet.vaccinations.isEmpty ? null : pet.vaccinations.first;
  if (first == null) return null;
  bool sameVisit(Pet p) {
    final f = p.vaccinations.isEmpty ? null : p.vaccinations.first;
    return f != null && f.date == first.date && f.sessionId == first.sessionId;
  }

  final pets = all.where(sameVisit).toList();
  return Receipt(
    number: receiptNo(first.date, personId, first.sessionId),
    date: first.date,
    drive: first.sessionId != null,
    visit: first.sessionId == null
        ? 'Walk-in'
        : [
            if ((first.sessionBarangay ?? '').isNotEmpty)
              first.sessionBarangay!,
            formatDate(first.date),
          ].join(' · '),
    owner: ownerName,
    pets: pets.isEmpty ? [pet] : pets,
  );
}

String _peso(int v) => '₱$v.00';

Future<void> showReceiptSheet(BuildContext context, Receipt r) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        0,
        22,
        22 + MediaQuery.of(ctx).viewPadding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/digivet_logo.png',
                width: 44,
                height: 44,
                cacheWidth: 132,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIGIVET',
                      style: TextStyle(
                        fontFamily: Brand.serif,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Brand.maroon900,
                      ),
                    ),
                    Text(
                      'Office of the City Veterinarian · Lipa City',
                      style: TextStyle(fontSize: 12.5, color: Brand.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Payment Acknowledgement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Brand.serif,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Brand.ink,
            ),
          ),
          const SizedBox(height: 14),
          _meta('Receipt no.', r.number, mono: true),
          _meta('Date', formatDate(r.date)),
          _meta(r.drive ? 'Drive' : 'Visit', r.visit),
          _meta('Received from', r.owner),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Brand.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: const BoxDecoration(
                    color: Brand.surfaceAlt,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pet',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Brand.inkSoft,
                          ),
                        ),
                      ),
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Brand.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final p in r.pets)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Brand.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Brand.ink,
                                ),
                              ),
                              Text(
                                '${_speciesWord(p.species)} · new pet',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Brand.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _peso(standardFee),
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Brand.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total (cash)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Brand.ink,
                  ),
                ),
              ),
              Text(
                _peso(r.total),
                style: const TextStyle(
                  fontFamily: Brand.serif,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Brand.maroon900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_peso(standardFee)} per new pet · pets already on file and boosters are free.',
            style: const TextStyle(fontSize: 12.5, color: Brand.inkSoft),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.maroon700,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _meta(String label, String value, {bool mono = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 118,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Brand.inkSoft),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontFamily: mono ? 'monospace' : null,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Brand.ink,
          ),
        ),
      ),
    ],
  ),
);
