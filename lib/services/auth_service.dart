import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static const adminEmail = 'admin@healthcare.com';
  static const adminPassword = 'admin123';

  // Register new user
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false, // User starts as unverified
        'isActive': false,  // User starts as inactive
        'status': 'pending', // Status for admin verification
        ...userData,
      });

      // Create specific collection document based on user type
      if (userType == 'doctor') {
        await _firestore.collection('doctors').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'name': userData['name'],
          'specialty': userData['specialty'] ?? 'General',
          'isVerified': false,
          'doctorId': 'pending', // Will be assigned by admin
          'patients': [],
          'consultationFee': 0,
          'education': [],
          'experience': '',
          'about': '',
          'schedule':{},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (userType == 'patient') {
        await _firestore.collection('patients').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'name': userData['name'],
          'isVerified': false,
          'patientId': 'pending', // Will be assigned by admin
          'doctors': [],
          'dateOfBirth': userData['dateOfBirth'],
          'gender':userData['gender'],
          'phoneNumber': '',
          'address': '',
          'bloodGroup': userData['bloodGroup'],
          'allergies': [],
          'chronicDiseases': [],
          'emergencyContact': {
            'name': '',
            'relation': '',
            'phoneNumber': '',
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Add to pending verifications collection for admin
      await _firestore.collection('pending_verifications').add({
        'userId': credential.user!.uid,
        'userType': userType,
        'email': email,
        'name': userData['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'documents': userData['documents'] ?? [],
      });

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isUserVerified(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.get('isVerified') as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  // Sign in user
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Check if it's admin login
      if (email == adminEmail && password == adminPassword) {
        // Sign in with admin credentials
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Verify if the user is actually an admin in Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists || userDoc.data()?['userType'] != 'admin') {
          throw 'Unauthorized access';
        }

        return userCredential;
      }

      // Regular user login
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return error.toString();
  }

  // Get user type
  Future<String?> getUserType(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.get('userType') as String?;
    } catch (e) {
      return null;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

}