import '../models/correction_request.dart';
import '../models/owner_profile.dart';
import '../models/pet.dart';
import 'api.dart';

/// Owner data, straight from the DIGIVET Online API. Nothing is cached to
/// disk (RA 10173) — every call is a fresh fetch, kept in memory by the
/// screen that asked. The server scopes everything to the signed-in owner's
/// session cookie; the app never sends an owner id.
class OwnerService {
  OwnerService._();
  static final OwnerService instance = OwnerService._();

  /// The owner's pets with their full vaccination history.
  Future<List<Pet>> fetchPets() async {
    final res = await Api.instance.get('/owner/pets');
    return [
      for (final p in (res['pets'] as List? ?? const []))
        Pet.fromJson(p as Map<String, dynamic>),
    ];
  }

  /// Correction requests this owner has sent, newest first.
  Future<List<CorrectionRequest>> fetchRequests() async {
    final res = await Api.instance.get('/owner/requests');
    return [
      for (final r in (res['requests'] as List? ?? const []))
        CorrectionRequest.fromJson(r as Map<String, dynamic>),
    ];
  }

  /// The owner's own name and contact details (printed on the vaccine card).
  Future<OwnerProfile> fetchProfile() async {
    final res = await Api.instance.get('/owner/profile');
    return OwnerProfile.fromJson(
      (res['profile'] as Map).cast<String, dynamic>(),
    );
  }

  /// Ask the office to correct one field on a pet. Owners can't edit records
  /// directly; staff approve or reject the request. The server only accepts
  /// pet_name, breed, color_markings, sex and birth_date, and scopes the pet
  /// to the signed-in owner (the app never sends an owner id).
  Future<void> submitRequest({
    required String petId,
    required String field,
    required String value,
    String? reason,
  }) async {
    await Api.instance.post('/owner/requests', {
      'petId': petId,
      'changes': {field: value},
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  /// Mark one of the owner's pets passed away (`deceased`) or `lost`, or back
  /// to `alive` (undo — allowed for the owner's own mark within 7 days).
  /// Date and note are optional.
  Future<void> setLifeStatus({
    required String petId,
    required String status,
    DateTime? date,
    String? note,
  }) async {
    String? iso(DateTime? d) => d == null
        ? null
        : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await Api.instance.post('/owner/pets/$petId/life-status', {
      'status': status,
      'source': 'app',
      if (date != null) 'date': iso(date),
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// Update the owner's own contact details (`PATCH /owner/profile`). The
  /// server only accepts names, contact no., email and address.
  Future<OwnerProfile> updateProfile(Map<String, String> changes) async {
    final res = await Api.instance.patch('/owner/profile', {
      'changes': changes,
    });
    return OwnerProfile.fromJson(
      (res['profile'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> changePassword(String current, String next) async {
    await Api.instance.patch('/owner/password', {
      'currentPassword': current,
      'newPassword': next,
    });
  }
}
