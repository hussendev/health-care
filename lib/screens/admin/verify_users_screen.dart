import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class VerifyUsersScreen extends StatefulWidget {
  const VerifyUsersScreen({Key? key}) : super(key: key);

  @override
  State<VerifyUsersScreen> createState() => _VerifyUsersScreenState();
}

class _VerifyUsersScreenState extends State<VerifyUsersScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  final _authService = AuthService();

  Future<void> _verifyUser(String userId, String userType) async {
    setState(() => _isLoading = true);
    try {
      String uniqueId = _generateUniqueId(userType);

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'isActive': true,
        'status': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': _authService.currentUser?.uid,
      });

      // Update specific collection based on user type
      if (userType == 'doctor') {
        await _firestore.collection('doctors').doc(userId).update({
          'doctorId': uniqueId,
          'isVerified': true,
          'status': 'active',
        });
      } else if (userType == 'patient') {
        await _firestore.collection('patients').doc(userId).update({
          'patientId': uniqueId,
          'isVerified': true,
          'status': 'active',
        });
      }

      // Remove from pending verifications
      final pendingDocs = await _firestore
          .collection('pending_verifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in pendingDocs.docs) {
        await doc.reference.delete();
      }

      // Add verification record
      await _firestore.collection('verification_records').add({
        'userId': userId,
        'userType': userType,
        'uniqueId': uniqueId,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': _authService.currentUser?.uid,
      });

      // Send notification to user
      await _sendVerificationNotification(userId, uniqueId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying user: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateUniqueId(String userType) {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = timestamp % 10000; // Last 4 digits of timestamp
    final year = now.year % 100; // Last 2 digits of year

    if (userType == 'doctor') {
      return 'D$year${random.toString().padLeft(4, '0')}';
    } else {
      return 'P$year${random.toString().padLeft(4, '0')}';
    }
  }

  Future<void> _sendVerificationNotification(String userId, String uniqueId) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // Send push notification
        // Implement your notification logic here
      }

      // Add notification to user's notifications collection
      await _firestore.collection('users').doc(userId)
          .collection('notifications').add({
        'title': 'Account Verified',
        'body': 'Your account has been verified. Your ID is: $uniqueId',
        'type': 'verification',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify Users'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Patients'),
              Tab(text: 'Pending Doctors'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList('patient'),
            _buildUserList('doctor'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String userType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('userType', isEqualTo: userType)
          .where('isVerified', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return Center(
            child: Text('No pending ${userType}s'),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    userType == 'patient' ? Icons.person : Icons.medical_services,
                  ),
                ),
                title: Text(user['name'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${user['email']}'),
                    Text('Registered: ${_formatDate(user['createdAt'] as Timestamp)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: Colors.green,
                      onPressed: _isLoading
                          ? null
                          : () => _verifyUser(userId, userType),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showUserDetails(user),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUserDetails(Map<String, dynamic> user) async {
    // Fetch additional details based on user type
    Map<String, dynamic>? additionalDetails;

    try {
      if (user['userType'] == 'doctor') {
        final doctorDoc = await _firestore
            .collection('doctors')
            .doc(user['uid'])
            .get();

        if (doctorDoc.exists) {
          additionalDetails = doctorDoc.data();
        }
      } else if (user['userType'] == 'patient') {
        final patientDoc = await _firestore
            .collection('patients')
            .doc(user['uid'])
            .get();

        if (patientDoc.exists) {
          additionalDetails = patientDoc.data();
        }
      }
    } catch (e) {
      print('Error fetching additional details: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Basic User Info
              _buildSectionTitle('Basic Information'),
              _buildDetailRow('Name', user['name'] ?? 'Unknown'),
              _buildDetailRow('Email', user['email'] ?? 'Unknown'),
              _buildDetailRow('User Type', user['userType'] ?? 'Unknown'),
              _buildDetailRow('Status', user['isActive'] ? 'Active' : 'Inactive'),
              _buildDetailRow('ID', user['uniqueId'] ?? 'Not assigned'),

              // Contact Information
              const SizedBox(height: 16),
              _buildSectionTitle('Contact Information'),
              _buildDetailRow('Phone', additionalDetails?['phone'] ?? 'Not provided'),
              _buildDetailRow('Address', additionalDetails?['address'] ?? 'Not provided'),

              // Doctor Specific Details
              if (user['userType'] == 'doctor' && additionalDetails != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Professional Information'),
                _buildDetailRow('Specialty', additionalDetails['specialty'] ?? 'Not specified'),
                _buildDetailRow('Registration Number', additionalDetails['registrationNumber'] ?? 'Not provided'),
                _buildDetailRow('Experience', '${additionalDetails['experience'] ?? 0} years'),
                _buildDetailRow('Consultation Fee', '\$${additionalDetails['consultationFee'] ?? 0}'),
                if (additionalDetails['qualifications'] != null)
                  _buildDetailRow('Qualifications',
                      (additionalDetails['qualifications'] as List).join(', ')),
                if (additionalDetails['languages'] != null)
                  _buildDetailRow('Languages',
                      (additionalDetails['languages'] as List).join(', ')),

                if (additionalDetails['services'] != null)
                  _buildDetailRow('services',
                      (additionalDetails['services'] as List).join(', ')),
              ],

              // Patient Specific Details
              if (user['userType'] == 'patient' && additionalDetails != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Medical Information'),
                _buildDetailRow('Blood Group', additionalDetails['bloodGroup'] ?? 'Not specified'),
                _buildDetailRow('Age', _calculateAge(additionalDetails['dateOfBirth'])),
                if (additionalDetails['allergies'] != null)
                  _buildDetailRow('Allergies',
                      (additionalDetails['allergies'] as List).join(', ')),
                if (additionalDetails['chronicDiseases'] != null)
                  _buildDetailRow('Chronic Diseases',
                      (additionalDetails['chronicDiseases'] as List).join(', ')),

                const SizedBox(height: 8),
                _buildSectionTitle('Emergency Contact'),
                _buildDetailRow('Name', additionalDetails['emergencyContact']?['name'] ?? 'Not provided'),
                _buildDetailRow('Relation', additionalDetails['emergencyContact']?['relation'] ?? 'Not provided'),
                _buildDetailRow('Phone', additionalDetails['emergencyContact']?['phoneNumber'] ?? 'Not provided'),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Implement data export
                      },
                      child: const Text('Export Data'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement edit functionality
                      },
                      child: const Text('Edit User'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  String _calculateAge(Timestamp? dateOfBirth) {
    if (dateOfBirth == null) return 'Not provided';

    final today = DateTime.now();
    final birthDate = dateOfBirth.toDate();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return '$age years';
  }
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}