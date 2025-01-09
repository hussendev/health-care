import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String type;
  final String title;
  final String description;
  final DateTime date;
  final String? fileUrl;
  final String? fileType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    this.fileUrl,
    this.fileType,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecord(
      id: doc.id,
      patientId: data['patientId'],
      doctorId: data['doctorId'],
      doctorName: data['doctorName'],
      type: data['type'],
      title: data['title'],
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(),
      fileUrl: data['fileUrl'],
      fileType: data['fileType'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'type': type,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'fileUrl': fileUrl,
      'fileType': fileType,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}