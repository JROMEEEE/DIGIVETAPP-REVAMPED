import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../theme.dart';

/// A centred card for empty and error states.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Brand.maroon100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Brand.maroon700, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Brand.serif,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Brand.maroon900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Brand.inkSoft,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.maroon700,
                shape: const StadiumBorder(),
              ),
              onPressed: onAction,
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label and colours for a pet's status chip.
({String label, Color fg, Color bg}) statusStyle(DueStatus s) => switch (s) {
  DueStatus.overdue => (
    label: 'Overdue',
    fg: const Color(0xFFB3261E),
    bg: const Color(0xFFFDECEA),
  ),
  DueStatus.dueSoon => (
    label: 'Due soon',
    fg: const Color(0xFF8A5A00),
    bg: const Color(0xFFFDF0D0),
  ),
  DueStatus.upToDate => (
    label: 'Up to date',
    fg: Brand.green700,
    bg: Brand.green100,
  ),
  DueStatus.none => (
    label: 'No shots yet',
    fg: Brand.inkSoft,
    bg: const Color(0xFFF1F5F9),
  ),
  DueStatus.passedAway => (
    label: 'Passed away',
    fg: Brand.inkSoft,
    bg: const Color(0xFFF1F5F9),
  ),
  DueStatus.lost => (
    label: 'Lost',
    fg: Brand.inkSoft,
    bg: const Color(0xFFF1F5F9),
  ),
};
