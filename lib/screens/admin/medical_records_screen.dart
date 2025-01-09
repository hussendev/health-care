// lib/screens/admin/admin_medical_records_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medical_record_types.dart';
import '../../services/medical_records_service.dart';

class AdminMedicalRecordsScreen extends StatefulWidget {
  const AdminMedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  State<AdminMedicalRecordsScreen> createState() => _AdminMedicalRecordsScreenState();
}

class _AdminMedicalRecordsScreenState extends State<AdminMedicalRecordsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _selectedType = 'all';
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _generateReport(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 8),

                  // Type Filter
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
                            Text('Type: ${record['type']}'),
                            Text('Patient: ${record['patientName'] ?? 'Unknown'}'),
                            Text('Doctor: Dr. ${record['doctorName'] ?? 'Unknown'}'),
                            Text('Date: ${_formatDate(record['recordDate'] as Timestamp)}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'audit',
                              child: Text('View Audit Trail'),
                            ),
                            const PopupMenuItem(
                              value: 'backup',
                              child: Text('Create Backup'),
                            ),
                            const PopupMenuItem(
                              value: 'archive',
                              child: Text('Archive Record'),
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
        onPressed: _showManagementOptions,
        child: const Icon(Icons.more_vert),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredRecordsStream() {
    Query query = _firestore.collection('medical_records')
        .orderBy('recordDate', descending: true);

    if (_selectedType != 'all') {
      query = query.where('type', isEqualTo: _selectedType);
    }

    if (_startDate != null) {
      query = query.where('recordDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }

    if (_endDate != null) {
      query = query.where('recordDate', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
    }

    // Apply search filter if text is entered
    if (_searchController.text.isNotEmpty) {
      query = query.where('searchTerms', arrayContains: _searchController.text.toLowerCase());
    }

    return query.snapshots();
  }

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
                Text(
                  record['title'] ?? 'Record Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(height: 32),
                _buildDetailRow('Type', record['type']),
                _buildDetailRow('Patient', record['patientName'] ?? 'Unknown'),
                _buildDetailRow('Doctor', 'Dr. ${record['doctorName'] ?? 'Unknown'}'),
                _buildDetailRow('Date', _formatDate(record['recordDate'] as Timestamp)),
                if (record['description'] != null)
                  _buildDetailRow('Description', record['description']),

                // Type-specific details
                if (record['type'] == 'Prescription') ...[
                  const SizedBox(height: 16),
                  const Text('Medications',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ...((record['metadata']?['medications'] ?? []) as List)
                      .map((med) => ListTile(
                    title: Text(med['name']),
                    subtitle: Text(
                        'Dosage: ${med['dosage']}\n'
                            'Frequency: ${med['frequency']}\n'
                            'Duration: ${med['duration']}'),
                  )),
                ],

                // File attachment
                if (record['fileUrl'] != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download File'),
                    onPressed: () => _downloadFile(record['fileUrl']),
                  ),
                ],
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showManagementOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup All Records'),
            onTap: () {
              Navigator.pop(context);
              _backupAllRecords();
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archive Old Records'),
            onTap: () {
              Navigator.pop(context);
              _archiveOldRecords();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Generate Report'),
            onTap: () {
              Navigator.pop(context);
              _generateReport();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Record Settings'),
            onTap: () {
              Navigator.pop(context);
              _showRecordSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleRecordAction(String action, String recordId, Map<String, dynamic> record) async {
    switch (action) {
      case 'view':
        _showRecordDetails(record);
        break;
      case 'audit':
        _showAuditTrail(recordId);
        break;
      case 'backup':
        await _backupRecord(recordId);
        break;
      case 'archive':
        await _archiveRecord(recordId);
        break;
    }
  }

  // Implement other helper methods...
  void _showAuditTrail(String recordId) {
    // Implement audit trail view
  }

  Future<void> _backupRecord(String recordId) async {
    // Implement backup functionality
  }

  Future<void> _archiveRecord(String recordId) async {
    // Implement archive functionality
  }

  Future<void> _backupAllRecords() async {
    // Implement backup all functionality
  }

  Future<void> _archiveOldRecords() async {
    // Implement archive old records functionality
  }

  Future<void> _generateReport() async {
    // Implement report generation
  }

  void _showRecordSettings() {
    // Implement settings dialog
  }

  Future<void> _downloadFile(String fileUrl) async {
    // Implement file download
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}