import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class DoctorMedicalRecordsScreen extends StatefulWidget {
  const DoctorMedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorMedicalRecordsScreen> createState() => _DoctorMedicalRecordsScreenState();
}

class _DoctorMedicalRecordsScreenState extends State<DoctorMedicalRecordsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  final _searchController = TextEditingController();
  String _selectedPatient = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
      ),
      body: Column(
        children: [
          // Patient Selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('patients')
                  .where('doctors', arrayContains: _authService.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                List<DropdownMenuItem<String>> patientItems =
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['name'] ?? 'Unknown'),
                  );
                }).toList();

                patientItems.insert(
                  0,
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Select Patient'),
                  ),
                );

                return DropdownButtonFormField<String>(
                  value: _selectedPatient.isEmpty ? null : _selectedPatient,
                  decoration: const InputDecoration(
                    labelText: 'Select Patient',
                    border: OutlineInputBorder(),
                  ),
                  items: patientItems,
                  onChanged: (value) {
                    setState(() => _selectedPatient = value ?? '');
                  },
                );
              },
            ),
          ),

          // Records List
          Expanded(
            child: _selectedPatient.isEmpty
                ? const Center(
              child: Text('Please select a patient to view records'),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('medical_records')
                  .where('doctorId', isEqualTo: _authService.currentUser!.uid)
                  .where('patientId', isEqualTo: _selectedPatient)
                  .orderBy('uploadDate', descending: true)
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
                  return const Center(
                    child: Text('No medical records found'),
                  );
                }

                return ListView.builder(
                  itemCount: records.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final record = records[index].data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        leading: Icon(_getFileIcon(record['fileType'])),
                        title: Text(record['title']),
                        subtitle: Text(
                          'Type: ${record['type']}\n'
                              'Date: ${record['uploadDate'].toDate().toString().split('.')[0]}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            // Implement download functionality
                            _downloadRecord(record['fileUrl']);
                          },
                        ),
                        onTap: () {
                          // View record details
                          _viewRecordDetails(context, record);
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
      floatingActionButton: _selectedPatient.isNotEmpty
          ? FloatingActionButton(
        onPressed: () {
          // Navigate to add medical record screen
          Navigator.pushNamed(
            context,
            '/doctor/medical-records/add',
            arguments: {'patientId': _selectedPatient},
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.file_present;
    }
  }

  Future<void> _downloadRecord(String fileUrl) async {
    // Implement file download functionality
    // You might want to use a package like url_launcher or dio for this
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}