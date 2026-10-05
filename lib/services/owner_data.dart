import 'package:flutter/foundation.dart';

import '../models/correction_request.dart';
import '../models/owner_profile.dart';
import '../models/pet.dart';
import 'api.dart';
import 'owner_service.dart';

/// The signed-in owner's pets and correction requests, held in memory and
/// shared by Home and My Pets so switching tabs doesn't refetch and a new
/// request shows up everywhere at once.
///
/// Never written to disk (RA 10173), and wiped on sign-out.
class OwnerData extends ChangeNotifier {
  OwnerData._();
  static final OwnerData instance = OwnerData._();

  List<Pet>? _pets; // null until the first load finishes
  List<CorrectionRequest> _requests = const [];
  OwnerProfile? _profile;
  String? _error;
  bool _loading = false;

  List<Pet>? get pets => _pets;
  List<CorrectionRequest> get requests => _requests;
  OwnerProfile? get profile => _profile;

  /// Set only while there are no pets to show (a failed refresh keeps the old data).
  String? get error => _error;
  bool get loading => _loading;

  /// Requests waiting on the office for a given pet.
  List<CorrectionRequest> requestsFor(String petId) => [
    for (final r in _requests)
      if (r.petId == petId) r,
  ];

  /// Loads once; later calls are no-ops until [refresh] or [clear].
  // Deferred a microtask: it's called from initState, and notifying listeners
  // (other tabs) in the middle of a build is an error.
  Future<void> ensureLoaded() => _pets == null && !_loading
      ? Future<void>.microtask(refresh)
      : Future.value();

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Requests are a bonus: if only they fail, the pets still show.
      final requestsFuture = OwnerService.instance.fetchRequests().catchError(
        (_) => <CorrectionRequest>[],
      );
      final profileFuture = OwnerService.instance
          .fetchProfile()
          .then<OwnerProfile?>((p) => p)
          .catchError((_) => null);
      final pets = await OwnerService.instance.fetchPets();
      _pets = pets;
      _requests = await requestsFuture;
      _profile = await profileFuture;
    } on ApiException catch (e) {
      // A 401 has already signed the user out (the gate swaps screens).
      if (!e.unauthorized && _pets == null) _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setProfile(OwnerProfile p) {
    _profile = p;
    notifyListeners();
  }

  /// Forget everything (sign-out or the server ending the session).
  void clear() {
    _pets = null;
    _requests = const [];
    _profile = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
