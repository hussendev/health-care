class PatientModel {
  final String uid;
  final String patientId;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final List<String> assignedDoctors;
  final Map<String, dynamic> medicalHistory;

  PatientModel({
    required this.uid,
    required this.patientId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.assignedDoctors = const [],
    this.medicalHistory = const {},
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      uid: json['uid'],
      patientId: json['patientId'],
      fullName: json['fullName'],
      dateOfBirth: json['dateOfBirth'].toDate(),
      gender: json['gender'],
      assignedDoctors: List<String>.from(json['assignedDoctors'] ?? []),
      medicalHistory: json['medicalHistory'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'patientId': patientId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'assignedDoctors': assignedDoctors,
      'medicalHistory': medicalHistory,
    };
  }
}
