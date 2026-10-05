enum RequestStatus { pending, approved, rejected }

/// A correction the owner asked staff to make to a pet's profile
/// (`GET /owner/requests`). Owners can't edit records directly; staff approve
/// or reject these.
class CorrectionRequest {
  CorrectionRequest({
    required this.id,
    required this.petId,
    required this.petName,
    required this.fields,
    required this.status,
    this.changes = const {},
    this.reason,
    this.reviewNote,
    this.createdAt,
  });

  final String id;
  final String petId;
  final String petName;

  /// Human-readable names of the fields being changed, e.g. "pet name".
  final List<String> fields;
  final RequestStatus status;

  /// Field name (as the server knows it) -> the value the owner asked for.
  final Map<String, String> changes;
  final String? reason;

  /// The office's note when it approved or rejected the request.
  final String? reviewNote;
  final DateTime? createdAt;

  factory CorrectionRequest.fromJson(Map<String, dynamic> j) {
    final changes = j['changes'];
    return CorrectionRequest(
      id: j['request_id'] as String,
      petId: j['pet_id'] as String,
      petName: (j['pet_name'] ?? '') as String,
      changes: changes is Map
          ? {for (final e in changes.entries) e.key as String: '${e.value}'}
          : const {},
      reason: _clean(j['reason']),
      reviewNote: _clean(j['review_note']),
      createdAt: j['created_at'] == null
          ? null
          : DateTime.tryParse(j['created_at'] as String)?.toLocal(),
      fields: changes is Map
          ? [for (final k in changes.keys) (k as String).replaceAll('_', ' ')]
          : const [],
      status: switch (j['status']) {
        'approved' => RequestStatus.approved,
        'rejected' => RequestStatus.rejected,
        _ => RequestStatus.pending,
      },
    );
  }
}

String? _clean(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// Friendly label for a field the owner may ask to change.
String requestFieldLabel(String key) => switch (key) {
  'pet_name' => 'Pet name',
  'breed' => 'Breed',
  'color_markings' => 'Color / markings',
  'sex' => 'Sex',
  'birth_date' => 'Birth date',
  _ => key.replaceAll('_', ' '),
};
