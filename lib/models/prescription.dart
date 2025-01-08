import 'package:cloud_firestore/cloud_firestore.dart';

import 'medication.dart';

class Prescription {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime date;
  final List<Medication> medications;
  final String instructions;
  final String status;

  Prescription({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.medications,
    required this.instructions,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'date': date,
      'medications': medications.map((m) => m?.toMap()).toList(),
      'instructions': instructions,
      'status': status,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      medications: (map['medications'] as List)
          .map((m) => Medication.fromMap(m))
          .toList(),
      instructions: map['instructions'] ?? '',
      status: map['status'] ?? '',
    );
  }
}
