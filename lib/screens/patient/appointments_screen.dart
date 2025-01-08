import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'doctor_selection_screen.dart';
import 'book_appointment_screen.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  PatientAppointmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: _authService.currentUser?.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data?.docs ?? [];

          if (appointments.isEmpty) {
            return const Center(
              child: Text('No appointments scheduled'),
            );
          }

          return ListView.builder(
            itemCount: appointments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final appointment = appointments[index].data() as Map<String, dynamic>;
              final DateTime dateTime = (appointment['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('Dr. ${appointment['doctorName']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${dateTime.toString().split(' ')[0]}'),
                      Text('Time: ${appointment['time']}'),
                      Text('Status: ${appointment['status']}'),
                    ],
                  ),
                  trailing: appointment['status'] == 'pending'
                      ? IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () async {
                      // Add appointment cancellation logic
                      await _firestore
                          .collection('appointments')
                          .doc(appointments[index].id)
                          .update({'status': 'cancelled'});
                    },
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show doctor selection screen
          final selectedDoctor = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => const DoctorSelectionScreen(),
            ),
          );

          // If a doctor was selected, navigate to booking screen
          if (selectedDoctor != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookAppointmentScreen(doctor: selectedDoctor),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}