/// How urgent a pet's next vaccination is. Same rules as the web portal:
/// overdue if the next due date has passed, due soon within 30 days, and
/// [none] for a pet with no vaccinations on record yet.
enum DueStatus { overdue, dueSoon, upToDate, none }

DateTime _day(String iso) {
  final p = iso.substring(0, 10).split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class Vaccination {
  Vaccination({
    required this.id,
    required this.vaccineName,
    required this.date,
    this.nextDue,
    this.dose,
    this.vetName,
    this.lotNo,
    this.approvalCode,
  });

  final String id;
  final String vaccineName;
  final DateTime date;
  final DateTime? nextDue;
  final int? dose;
  final String? vetName;
  final String? lotNo;
  final String? approvalCode;

  factory Vaccination.fromJson(Map<String, dynamic> j) => Vaccination(
    id: j['vaccination_id'] as String,
    vaccineName: (j['vaccine_name'] ?? 'Vaccine') as String,
    date: _day(j['vaccination_date'] as String),
    nextDue: j['next_due_date'] == null
        ? null
        : _day(j['next_due_date'] as String),
    dose: j['dose_number'] as int?,
    vetName: j['veterinarian_name'] as String?,
    lotNo: j['manufacturer_lot_no'] as String?,
    approvalCode: j['approval_code'] as String?,
  );
}

class Pet {
  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.color,
    this.lifeStatus,
    this.registrationNo,
    this.birthDate,
    this.birthDateEstimated = false,
    this.age,
    required this.vaccinations,
  });

  final String id;
  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final String? color;
  final String? lifeStatus;
  final String? registrationNo;
  final DateTime? birthDate;
  final bool birthDateEstimated;

  /// Age as recorded at registration (free text, e.g. "2 years").
  final String? age;

  /// Oldest first.
  final List<Vaccination> vaccinations;

  factory Pet.fromJson(Map<String, dynamic> j) {
    final shots = [
      for (final v in (j['vaccinations'] as List? ?? const []))
        Vaccination.fromJson(v as Map<String, dynamic>),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return Pet(
      id: j['pet_id'] as String,
      name: (j['pet_name'] ?? '') as String,
      species: (j['species'] ?? '') as String,
      breed: j['breed'] as String?,
      sex: j['sex'] as String?,
      color: j['color_markings'] as String?,
      lifeStatus: j['life_status'] as String?,
      registrationNo: j['registration_no'] as String?,
      birthDate: j['birth_date'] == null
          ? null
          : _day(j['birth_date'] as String),
      birthDateEstimated: (j['is_birth_date_estimated'] ?? false) as bool,
      age: j['age_recorded']?.toString(),
      vaccinations: shots,
    );
  }

  bool get isDog => species.toLowerCase() == 'dog';
  bool get isCat => species.toLowerCase() == 'cat';

  Vaccination? get latest => vaccinations.isEmpty ? null : vaccinations.last;
  DateTime? get nextDue => latest?.nextDue;

  DueStatus get status {
    if (latest == null) return DueStatus.none;
    final due = nextDue;
    if (due == null) return DueStatus.upToDate;
    final today = _today();
    if (due.isBefore(today)) return DueStatus.overdue;
    if (!due.isAfter(today.add(const Duration(days: 30)))) {
      return DueStatus.dueSoon;
    }
    return DueStatus.upToDate;
  }

  /// Days until the next dose; negative when overdue. Null with no schedule.
  int? get daysRemaining {
    final due = nextDue;
    return due?.difference(_today()).inDays;
  }

  /// How much of the protection window (last shot -> next due) is left, 0..1.
  double? get protectionFraction {
    final due = nextDue;
    final last = latest?.date;
    if (due == null || last == null) return null;
    final total = due.difference(last).inDays;
    if (total <= 0) return 0;
    return (due.difference(_today()).inDays / total).clamp(0.0, 1.0);
  }
}
