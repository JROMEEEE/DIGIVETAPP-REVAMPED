import 'package:flutter/material.dart';

import '../models/correction_request.dart';
import '../theme.dart';

/// "My correction requests" on My Pets (same place as the web portal): every
/// request the owner has sent, with what it asks to change and its status.
/// Shown only when the owner has sent at least one.
class MyRequestsSection extends StatelessWidget {
  const MyRequestsSection({super.key, required this.requests});
  final List<CorrectionRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MY CORRECTION REQUESTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Brand.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          for (final r in requests)
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
                          r.changes.isEmpty
                              ? 'Profile update'
                              : r.changes.keys
                                    .map(requestFieldLabel)
                                    .join(', '),
                          maxLines: 2,
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
                  RequestChip(r.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class RequestChip extends StatelessWidget {
  const RequestChip(this.status, {super.key});
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
