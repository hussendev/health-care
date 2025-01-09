import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medical_record_types.dart';
import '../../services/auth_service.dart';

class PatientMedicalRecordsScreen extends StatefulWidget {
  const PatientMedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  State<PatientMedicalRecordsScreen> createState() => _PatientMedicalRecordsScreenState();
}

class _PatientMedicalRecordsScreenState extends State<PatientMedicalRecordsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  final List<String> _recordTypes = [
    'All',
    'Lab Report',
    'Imaging Report',
    'Treatment Plan',
    'Progress Notes',
    'Referral Letter',
    'Discharge Summary',
    'Medical Certificate',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _recordTypes.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medical Records'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              ..._recordTypes.map((type) => Tab(text: type)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ..._recordTypes.map((type) => _buildRecordsList(type)),
            ...MedicalRecordType.allTypes.map((type) {
              return _buildRecordsList(type);
            }),
          ],
        ),
      ),
    );
  }

 Future<String?> getDoctorNameById(String doctorId)async{
    final doctorSnapshot = await _firestore.collection('doctors').doc(doctorId).get();
    if (doctorSnapshot.exists) {
      final doctorData = doctorSnapshot.data() as Map<String, dynamic>;
      return doctorData['name'];
    }
    return null;
  }

  Widget _buildRecordsList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredRecordsStream(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data?.docs ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${type == 'all' ? '' : '$type '}records found',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: records.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final record = records[index].data() as Map<String, dynamic>;

            String doctorName='';


            return Card(
              child: ListTile(
                leading: _getRecordTypeIcon(record['type']),
                title: Text(record['title'] ?? 'Untitled Record'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${_formatDate(record['recordDate'] as Timestamp)}'),
                    FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('doctors').doc(record['doctorId']).get(),
                      builder: (context, doctorSnapshot) {
                        if (doctorSnapshot.hasData && doctorSnapshot.data!.exists) {
                          final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
                          doctorName=doctorData['name'];
                          return Text('Doctor: Dr. ${doctorData['name'] ?? 'Unknown'}');
                        }
                        return Text('Doctor: Loading...');
                      },
                    ),
                    Text('Type: ${record['type'] ?? 'Unknown'}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        _downloadRecord(record['fileUrl']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        _showRecordDetails(record,doctorName);
                      },
                    ),
                  ],
                ),
                onTap: () => _showRecordDetails(record,doctorName),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredRecordsStream(String type) {
    Query query = _firestore
        .collection('medical_records')
        .where('patientId', isEqualTo: _authService.currentUser?.uid)
        .orderBy('recordDate', descending: true);

    if (type != 'All') {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots();
  }

  Widget _getRecordTypeIcon(String? type) {
    IconData iconData;
    switch (type) {
      case 'Lab Report':
        iconData = Icons.science;
        break;
      case 'Imaging Report':
        iconData = Icons.image;
        break;
      case 'Prescription':
        iconData = Icons.medical_services;
        break;
      case 'Treatment Plan':
        iconData = Icons.playlist_add_check;
        break;
      case 'Progress Notes':
        iconData = Icons.note;
        break;
      case 'Referral Letter':
        iconData = Icons.mail;
        break;
      case 'Discharge Summary':
        iconData = Icons.summarize;
        break;
      case 'Medical Certificate':
        iconData = Icons.verified;
        break;
      default:
        iconData = Icons.file_present;
    }

    return CircleAvatar(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(iconData, color: Theme.of(context).primaryColor),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRecordDetails(Map<String, dynamic> record,String doctorName) {
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
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record['title'] ?? 'Untitled Record',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildDetailRow('Type', record['type'] ?? 'Unknown'),
                _buildDetailRow('Date', _formatDate(record['recordDate'] as Timestamp)),
                _buildDetailRow('Doctor', 'Dr. ${doctorName ?? 'Unknown'}'),
                if (record['description'] != null && record['description'].toString().isNotEmpty)
                  _buildDetailRow('Description', record['description']),
                if (record['remarks'] != null && record['remarks'].toString().isNotEmpty)
                  _buildDetailRow('Doctor\'s Remarks', record['remarks']),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _downloadRecord(record['fileUrl']),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Record'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _downloadRecord(String fileUrl) {
    // Implement file download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading record...')),
    );
  }
}