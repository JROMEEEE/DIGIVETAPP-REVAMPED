import 'package:flutter/material.dart';

import '../models/correction_request.dart';
import '../theme.dart';
import '../utils/format.dart';

/// A pet's correction requests, newest first: what was asked, why, when, and
/// the office's answer once it has one.
class RequestList extends StatelessWidget {
  const RequestList({super.key, required this.requests});
  final List<CorrectionRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Brand.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Brand.border),
        ),
        child: const Text(
          'No correction requests. If something on this card is wrong, you '
          'can ask the office to fix it.',
          style: TextStyle(fontSize: 13.5, height: 1.45, color: Brand.inkSoft),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < requests.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _RequestCard(request: requests[i]),
        ],
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final CorrectionRequest request;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (request.status) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              const Spacer(),
              if (request.createdAt != null)
                Text(
                  timeAgo(request.createdAt!),
                  style: const TextStyle(fontSize: 12.5, color: Brand.inkSoft),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final e in request.changes.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 124,
                    child: Text(
                      requestFieldLabel(e.key),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Brand.inkSoft,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (request.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Your reason: ${request.reason}',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: Brand.inkSoft,
              ),
            ),
          ],
          if (request.reviewNote != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Brand.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Office note: ${request.reviewNote}',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Brand.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
