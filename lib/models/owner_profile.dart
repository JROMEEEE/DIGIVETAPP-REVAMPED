/// The signed-in owner's own details (`GET /owner/profile`), as printed on the
/// vaccine card.
class OwnerProfile {
  OwnerProfile({
    required this.fullName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    this.contactNo,
    this.address,
  });

  final String fullName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String? contactNo;
  final String? address;

  factory OwnerProfile.fromJson(Map<String, dynamic> j) {
    String? clean(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final name = [
      clean(j['first_name']),
      clean(j['middle_name']),
      clean(j['last_name']),
    ].whereType<String>().join(' ');
    return OwnerProfile(
      fullName: name,
      firstName: clean(j['first_name']),
      middleName: clean(j['middle_name']),
      lastName: clean(j['last_name']),
      email: clean(j['email']),
      contactNo: clean(j['contact_no']),
      address: clean(j['address_line']),
    );
  }
}
