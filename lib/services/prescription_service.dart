import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrescriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create new prescription
  Future<void> createPrescription({
    required String patientId,
    required List<Map<String, dynamic>> medications,
    required String instructions,
    String? diagnosis,
  }) async {
    try {
      final doctorId = _auth.currentUser!.uid;

      await _firestore.collection('prescriptions').add({
        'patientId': patientId,
        'doctorId': doctorId,
        'medications': medications,
        'instructions': instructions,
        'diagnosis': diagnosis,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _firestore.collection('activity_logs').add({
        'type': 'prescription_created',
        'doctorId': doctorId,
        'patientId': patientId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create prescription: $e');
    }
  }

  Stream<QuerySnapshot> getPatientPrescriptions(String patientId) {
    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getDoctorPrescriptions(String doctorId) {
    return _firestore
        .collection('prescriptions')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updatePrescriptionStatus(String prescriptionId, String status) async {
    try {
      await _firestore.collection('prescriptions').doc(prescriptionId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update prescription status: $e');
    }
  }
}