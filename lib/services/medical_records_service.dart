import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/medical_record.dart';
import '../models/medical_record_types.dart';
import '../models/prescription.dart';

class MedicalRecordsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a medical record
  Future<MedicalRecord> createMedicalRecord({
    required String patientId,
    required String doctorId,
    required String type,
    required String title,
    required String description,
    File? file,
    Map<String, dynamic>? metadata,
  }) async {
    // Upload file if provided
    String? fileUrl;
    String? fileType;
    if (file != null) {
      final extension = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ref = _storage.ref().child('medical_records/$patientId/$fileName');
      await ref.putFile(file);
      fileUrl = await ref.getDownloadURL();
      fileType = extension;
    }

    // Get doctor's name
    final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
    final doctorName = doctorDoc.data()?['name'] ?? 'Unknown Doctor';

    // Create record document
    final docRef = await _firestore.collection('medical_records').add({
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'type': type,
      'title': title,
      'description': description,
      'date': FieldValue.serverTimestamp(),
      'fileUrl': fileUrl,
      'fileType': fileType,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return MedicalRecord.fromFirestore(doc);
  }


  // Get patient's records
  Stream<List<MedicalRecord>> getPatientRecords(String patientId, {String? type}) {
    Query query = _firestore
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList());
  }

  // Get doctor's records
  Stream<List<MedicalRecord>> getDoctorRecords(String doctorId, {String? type}) {
    Query query = _firestore
        .collection('medical_records')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList());
  }
}