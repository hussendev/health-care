import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const PatientDetailsScreen({Key? key, required this.args}) : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final patientId = widget.args['patientId'] as String;
    final patientData = widget.args['patientData'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(patientData['name'] ?? 'Patient Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('patients').doc(patientId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Basic Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: data['profileImageUrl'] != null
                                  ? NetworkImage(data['profileImageUrl'])
                                  : null,
                              child: data['profileImageUrl'] == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    // 'Age',
                                    'Age: ${_calculateAge(data['dateOfBirth'])}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Gender: ${data['gender'] ?? 'Not specified'}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildInfoRow('Phone', data['phone'] ?? 'Not provided'),
                        _buildInfoRow('Email', data['email'] ?? 'Not provided'),
                        _buildInfoRow('Address', data['address'] ?? 'Not provided'),
                        if (data['bloodGroup'] != null)
                          _buildInfoRow('Blood Group', data['bloodGroup']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: Icons.note_add,
                              label: 'Add Medical\nRecord',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/doctor/medical-records/add',
                                  arguments: {'patientId': patientId},
                                );
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.medical_services,
                              label: 'Add\nPrescription',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/doctor/prescriptions/add',
                                  arguments: {'patientId': patientId},
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical History
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Medical History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigator.pushNamed(
                                //   context,
                                //   '/doctor/patient-history',
                                //   arguments: {'patientId': patientId},
                                // );
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildHistoryList(patientId),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Upcoming Appointments
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Appointments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildAppointmentsList(patientId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _calculateAge(Timestamp dateOfBirth) {
    final dob = dateOfBirth.toDate();
    final now = DateTime.now();
    final age = now.year - dob.year;
    if (now.month < dob.month) {
      return age - 1;
    }
    if (now.month == dob.month && now.day < dob.day) {
      return age - 1;
    }
    return age;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
    child: Container(
    padding: const EdgeInsets.all(8),
    child: Column(
    children: [
    Icon(icon, size: 32),
    const SizedBox(height: 4),
    Text(
    label,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 12),
    ),
    ],
    ),
    ),
    );
  }

  Widget _buildHistoryList(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('medical_records')
          .where('patientId', isEqualTo:patientId)
          .orderBy('recordDate', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data!.docs;

        if (history.isEmpty) {
          return const Text('No medical history available');
        }

        return Column(
          children: history.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['title'] ?? 'Unknown'),

              // subtitle:
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['recordDate'].toDate().toString() ?? 'Unknown'),
                  Text('Type: ${data['type']}'),
                  Text('Status: ${data['status']}'),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/doctor/medical-records/view',
                  arguments: {
                    'patientId': patientId,
                    'recordId': doc.id,
                  },
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentsList(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _authService.currentUser!.uid)
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'accept')
          .orderBy('date', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!.docs;

        if (appointments.isEmpty) {
          return const Text('No upcoming appointments');
        }

        return Column(
          children: appointments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['doctorName'] ?? 'Unknown'),
              subtitle: Text(data['date'].toDate().toString() ?? 'Unknown'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/doctor/appointment-details',
                  arguments: {
                    'appointmentId': doc.id,
                  },
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}