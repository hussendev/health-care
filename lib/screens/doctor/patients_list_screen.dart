import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Recent'),
                  selected: _selectedFilter == 'recent',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'recent');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Active'),
                  selected: _selectedFilter == 'active',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'active');
                  },
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('patients')
                  .where('doctors', arrayContains: _authService.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final patients = snapshot.data?.docs ?? [];

                // Filter patients
                var filteredPatients = patients.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'].toString().toLowerCase();
                  final searchQuery = _searchController.text.toLowerCase();

                  // Apply search filter
                  if (searchQuery.isNotEmpty && !name.contains(searchQuery)) {
                    return false;
                  }

                  // Apply status filter
                  switch (_selectedFilter) {
                    case 'recent':
                      final lastVisit = data['lastVisit'] as Timestamp?;
                      if (lastVisit == null) return false;
                      return DateTime.now().difference(lastVisit.toDate()).inDays <= 30;
                    case 'active':
                      return data['activeAppointments'] != null &&
                          (data['activeAppointments'] as int) > 0;
                    default:
                      return true;
                  }
                }).toList();

                if (filteredPatients.isEmpty) {
                  return const Center(
                    child: Text('No patients found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredPatients.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final patient = filteredPatients[index].data() as Map<String, dynamic>;
                    final patientId = filteredPatients[index].id;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: patient['profileImageUrl'] != null
                              ? NetworkImage(patient['profileImageUrl'])
                              : null,
                          child: patient['profileImageUrl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(patient['name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (patient['lastVisit'] != null)
                              Text(
                                'Last Visit: ${_formatDate(patient['lastVisit'] as Timestamp)}',
                              ),
                            if (patient['nextAppointment'] != null)
                              Text(
                                'Next Appointment: ${_formatDate(patient['nextAppointment'] as Timestamp)}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/doctor/patient-details',
                            arguments: {
                              'patientId': patientId,
                              'patientData': patient,
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}