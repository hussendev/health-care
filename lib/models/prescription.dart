import 'package:cloud_firestore/cloud_firestore.dart';

import 'medication.dart';

class Prescription {
  final String recordId;
  final List<Medication> medications;
  final String diagnosis;
  final String instructions;
  final DateTime validUntil;

  Prescription({
    required this.recordId,
    required this.medications,
    required this.diagnosis,
    required this.instructions,
    required this.validUntil,
  });

  Map<String, dynamic> toMetadata() {
    return {
      'medications': medications.map((m) => m.toMap()).toList(),
      'diagnosis': diagnosis,
      'instructions': instructions,
      'validUntil': Timestamp.fromDate(validUntil),
    };
  }
}