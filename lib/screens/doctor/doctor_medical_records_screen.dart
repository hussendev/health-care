import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medical_record_types.dart';
import '../../services/auth_service.dart';

class DoctorMedicalRecordsScreen extends StatefulWidget {
  const DoctorMedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorMedicalRecordsScreen> createState() => _DoctorMedicalRecordsScreenState();
}

class _DoctorMedicalRecordsScreenState extends State<DoctorMedicalRecordsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  String? _selectedPatient;
  String _selectedType = 'all';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
      ),
      body: Column(
        children: [
          // Patient Selection and Filters
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Patient Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('patients')
                        .where('doctors', arrayContains: _authService.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final patients = snapshot.data!.docs;

                      return DropdownButtonFormField<String>(
                        value: _selectedPatient,
                        decoration: const InputDecoration(
                          labelText: 'Select Patient',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Patients'),
                          ),
                          ...patients.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(data['name'] ?? 'Unknown'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedPatient = value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Record Type Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedType == 'all',
                          onSelected: (selected) {
                            setState(() => _selectedType = 'all');
                          },
                        ),
                        const SizedBox(width: 8),
                        ...MedicalRecordType.allTypes.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(type),
                              selected: _selectedType == type,
                              onSelected: (selected) {
                                setState(() => _selectedType = type);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Records List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredRecordsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = snapshot.data?.docs ?? [];

                if (records.isEmpty) {
                  return const Center(child: Text('No records found'));
                }

                return ListView.builder(
                  itemCount: records.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final record = records[index].data() as Map<String, dynamic>;
                    final recordId = records[index].id;

                    return Card(
                      child: ListTile(
                        leading: _getRecordTypeIcon(record['type']),
                        title: Text(record['title'] ?? 'Untitled'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: _firestore
                                  .collection('patients')
                                  .doc(record['patientId'])
                                  .get(),
                              builder: (context, patientSnapshot) {
                                if (patientSnapshot.hasData) {
                                  final patientData = patientSnapshot.data!.data()
                                  as Map<String, dynamic>;
                                  return Text('Patient: ${patientData['name'] ?? 'Unknown'}');
                                }
                                return const Text('Loading patient...');
                              },
                            ),
                            Text('Type: ${record['type']}'),
                            // Text('Date: ${_formatDate(record['date'] as Timestamp)}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () => _viewRecordDetails(context, record),
                              value: 'view',
                              child: const Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Record'),
                            ),
                            const PopupMenuItem(
                              value: 'download',
                              child: Text('Download'),
                            ),
                          ],
                          onSelected: (value) => _handleRecordAction(value, recordId, record),
                        ),
                        onTap: () => _showRecordDetails(record),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _viewRecordDetails(BuildContext context, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${record['type']}'),
              const SizedBox(height: 8),
              Text('Description: ${record['description'] ?? 'No description'}'),
              const SizedBox(height: 8),
              Text('Uploaded: ${record['uploadDate'].toDate().toString().split('.')[0]}'),
              const SizedBox(height: 8),
              Text('File Type: ${record['fileType']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => _downloadRecord(record['fileUrl']),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredRecordsStream() {
    print('object ${_authService.currentUser?.uid}');
    Query query = _firestore
        .collection('medical_records')
        .where('doctorId', isEqualTo: _authService.currentUser?.uid)
        .orderBy('recordDate', descending: true);

    if (_selectedPatient != null) {
      query = query.where('patientId', isEqualTo: _selectedPatient);
    }

    if (_selectedType != 'all') {
      query = query.where('type', isEqualTo: _selectedType);
    }

    return query.snapshots();
  }

  void _showAddRecordOptions() {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Add Medical Record'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/doctor/medical-records/add',
                arguments: {'patientId': _selectedPatient},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Upload Document'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/doctor/upload-medical-record',
                arguments: {'patientId': _selectedPatient},
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods...
  Widget _getRecordTypeIcon(String type) {
    IconData iconData;
    switch (type) {
      case 'Prescription':
        iconData = Icons.medical_services;
        break;
      case 'Lab Result':
        iconData = Icons.science;
        break;
      case 'Imaging':
        iconData = Icons.image;
        break;
      case 'Diagnosis':
        iconData = Icons.health_and_safety;
        break;
      default:
        iconData = Icons.description;
    }

    return CircleAvatar(
      child: Icon(iconData),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    // Similar to admin's _showRecordDetails but with edit options
  }

  Future<void> _handleRecordAction(String action, String recordId, Map<String, dynamic> record) async {
    switch (action) {
      case 'view':
        _showRecordDetails(record);
        break;
      case 'edit':
        _editRecord(recordId, record);
        break;
      case 'download':
        _downloadRecord(record['fileUrl']);
        break;
    }
  }

  void _editRecord(String recordId, Map<String, dynamic> record) {
    // Navigate to edit screen based on record type
    switch (record['type']) {
      case 'Prescription':
        Navigator.pushNamed(
          context,
          '/doctor/edit-prescription',
          arguments: {'recordId': recordId},
        );
        break;
      default:
        Navigator.pushNamed(
          context,
          '/doctor/edit-medical-record',
          arguments: {'recordId': recordId},
        );
    }
  }

  Future<void> _downloadRecord(String? fileUrl) async {
    if (fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file available')),
      );
      return;
    }
    // Implement download functionality
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}