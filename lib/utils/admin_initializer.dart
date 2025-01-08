import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminInitializer {
  static Future<void> initializeAdmin() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      try {
        await auth.signInWithEmailAndPassword(
          email: AuthService.adminEmail,
          password: AuthService.adminPassword,
        );
      } catch (e) {
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: AuthService.adminEmail,
          password: AuthService.adminPassword,
        );

        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': AuthService.adminEmail,
          'userType': 'admin',
          'name': 'System Admin',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await auth.signOut();
    } catch (e) {
      print('Error initializing admin: $e');
    }
  }
}