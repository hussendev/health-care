import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prescriptions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recent'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrescriptionsList(isRecent: true),
            _buildPrescriptionsList(isRecent: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/doctor/prescriptions/add');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPrescriptionsList({required bool isRecent}) {
    Query query = _firestore
        .collection('prescriptions')
        .where('doctorId', isEqualTo: _authService.currentUser?.uid);

    if (isRecent) {
      // Get prescriptions from last 30 days
      query = query.where(
        'createdAt',
        isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 30)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final prescriptions = snapshot.data?.docs ?? [];

        if (prescriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  isRecent
                      ? 'No recent prescriptions'
                      : 'No prescriptions found',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: prescriptions.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final prescription = prescriptions[index].data() as Map<String, dynamic>;

            return Card(
              child: ExpansionTile(
                title: FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('patients')
                      .doc(prescription['patientId'])
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
                  'Date: ${prescription['createdAt'].toDate().toString().split(' ')[0]}\n'
                      'Diagnosis: ${prescription['diagnosis']}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medications:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          (prescription['medications'] as List).length,
                              (index) {
                            final medication = prescription['medications'][index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(
                                    child: Text(
                                      '${medication['name']} - '
                                          '${medication['dosage']}\n'
                                          'Instructions: ${medication['instructions']}',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (prescription['notes'] != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(prescription['notes']),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.print),
                              label: const Text('Print'),
                              onPressed: () {
                                // Implement print functionality
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              onPressed: () {
                                // Implement share functionality
                              },
                            ),
                          ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}