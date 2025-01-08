import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  String _selectedFilter = 'upcoming';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Appointments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Today'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentsList('upcoming'),
            _buildAppointmentsList('today'),
            _buildAppointmentsList('past'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(String filter) {
    Query query = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: _authService.currentUser?.uid);

    // Apply date filters
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));

    switch (filter) {
      case 'upcoming':
        query = query.where('date', isGreaterThanOrEqualTo: tomorrow);
        break;
      case 'today':
        query = query.where('date', isGreaterThanOrEqualTo: today)
            .where('date', isLessThan: tomorrow);
        break;
      case 'past':
        query = query.where('date', isLessThan: today);
        break;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data?.docs ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${filter == 'upcoming' ? 'upcoming' : filter == 'today' ? 'today\'s' : 'past'} appointments',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: appointments.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final appointment = appointments[index].data() as Map<String, dynamic>;
            final date = (appointment['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('patients')
                          .doc(appointment['patientId'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final patientData = snapshot.data!.data() as Map<String, dynamic>?;
                          return Text(patientData?['name'] ?? 'Unknown Patient');
                        }
                        return const Text('Loading...');
                      },
                    ),
                    subtitle: Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(date)}\n'
                          'Time: ${appointment['time']}\n'
                          'Status: ${appointment['status']}',
                    ),
                    trailing: appointment['status'] == 'pending'
                        ? PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'accept',
                          child: Text('Accept'),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Text('Reject'),
                        ),
                      ],
                      onSelected: (value) async {
                        await _firestore
                            .collection('appointments')
                            .doc(appointments[index].id)
                            .update({'status': value});
                      },
                    )
                        : null,
                  ),
                  if (appointment['reason'] != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason for Visit:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(appointment['reason']),
                        ],
                      ),
                    ),
                  if (appointment['status'] == 'accepted')
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.medical_services),
                            label: const Text('Add Prescription'),
                            onPressed: () {
                              // Navigate to add prescription screen
                              Navigator.pushNamed(
                                context,
                                '/doctor/prescriptions/add',
                                arguments: {
                                  'appointmentId': appointments[index].id,
                                  'patientId': appointment['patientId'],
                                },
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.note_add),
                            label: const Text('Medical Notes'),
                            onPressed: () {
                              // Navigate to medical notes screen
                              Navigator.pushNamed(
                                context,
                                '/doctor/medical-notes/add',
                                arguments: {
                                  'appointmentId': appointments[index].id,
                                  'patientId': appointment['patientId'],
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}