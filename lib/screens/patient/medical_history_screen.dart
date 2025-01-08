import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class PatientHistoryScreen extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  PatientHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medical History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Past Visits'),
              Tab(text: 'Prescriptions'),
              Tab(text: 'Lab Results'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPastVisits(),
            _buildPrescriptions(),
            _buildLabResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildPastVisits() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('medical_notes')
          .where('patientId', isEqualTo: _authService.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final visits = snapshot.data?.docs ?? [];

        if (visits.isEmpty) {
          return const Center(child: Text('No past visits found'));
        }

        return ListView.builder(
          itemCount: visits.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final visit = visits[index].data() as Map<String, dynamic>;
            final date = (visit['createdAt'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text('Dr. ${visit['doctorName'] ?? 'Unknown'}'),
                subtitle: Text(
                  '${date.day}/${date.month}/${date.year}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Symptoms', visit['symptoms'] ?? 'Not specified'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Diagnosis', visit['diagnosis'] ?? 'Not specified'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Treatment', visit['treatmentPlan'] ?? 'Not specified'),
                        const SizedBox(height: 8),
                        if (visit['notes'] != null)
                          _buildInfoRow('Additional Notes', visit['notes']),
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

  Widget _buildPrescriptions() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: _authService.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final prescriptions = snapshot.data?.docs ?? [];

        if (prescriptions.isEmpty) {
          return const Center(child: Text('No prescriptions found'));
        }

        return ListView.builder(
          itemCount: prescriptions.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final prescription = prescriptions[index].data() as Map<String, dynamic>;
            final date = (prescription['createdAt'] as Timestamp).toDate();
            final medications = List<Map<String, dynamic>>.from(prescription['medications'] ?? []);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title:  FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('doctors').doc(prescription['doctorId']).get(),
                  builder: (context, doctorSnapshot) {
                    if (doctorSnapshot.hasData && doctorSnapshot.data!.exists) {
                      final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
                      return Text('Doctor: Dr. ${doctorData['name'] ?? 'Unknown'}');
                    }
                    return Text('Doctor: Loading...');
                  },
                ),
                subtitle: Text(
                  '${date.day}/${date.month}/${date.year}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medications:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...medications.map((med) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${med['name']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dosage: ${med['dosage']}'),
                                    Text('Frequency: ${med['frequency']}'),
                                    Text('Duration: ${med['duration']}'),
                                    if (med['instructions'] != null)
                                      Text('Instructions: ${med['instructions']}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (prescription['notes'] != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(prescription['notes']),
                        ],
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

  Widget _buildLabResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('medical_records')
          .where('patientId', isEqualTo: _authService.currentUser?.uid)
          .where('type', isEqualTo: 'Lab Report')
          .orderBy('recordDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data?.docs ?? [];

        if (records.isEmpty) {
          return const Center(child: Text('No lab results found'));
        }

        return ListView.builder(
          itemCount: records.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final record = records[index].data() as Map<String, dynamic>;
            final date = (record['recordDate'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.science),
                ),
                title: Text(record['title'] ?? 'Lab Result'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${date.day}/${date.month}/${date.year}'),
                    Text('Doctor: Dr. ${record['doctorName'] ?? 'Unknown'}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // Implement download functionality
                  },
                ),
                onTap: () {
                  _showLabResultDetails(context, record);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  void _showLabResultDetails(BuildContext context, Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record['title'] ?? 'Lab Result',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Date',
                '${(record['recordDate'] as Timestamp).toDate().day}/'
                    '${(record['recordDate'] as Timestamp).toDate().month}/'
                    '${(record['recordDate'] as Timestamp).toDate().year}'
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Doctor', 'Dr. ${record['doctorName'] ?? 'Unknown'}'),
            if (record['description'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Description', record['description']),
            ],
            if (record['remarks'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Remarks', record['remarks']),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Result'),
                onPressed: () {
                  // Implement download functionality
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}