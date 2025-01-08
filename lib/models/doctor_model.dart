class DoctorModel {
  final String uid;
  final String fullName;
  final String specialty;
  final List<String> patients;
  final Map<String, dynamic> schedule;

  DoctorModel({
    required this.uid,
    required this.fullName,
    required this.specialty,
    this.patients = const [],
    this.schedule = const {},
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      uid: json['uid'],
      fullName: json['fullName'],
      specialty: json['specialty'],
      patients: List<String>.from(json['patients'] ?? []),
      schedule: json['schedule'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'specialty': specialty,
      'patients': patients,
      'schedule': schedule,
    };
  }
}