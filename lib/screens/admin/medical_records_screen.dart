import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class AdminMedicalRecordsScreen extends StatefulWidget {
  const AdminMedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  State<AdminMedicalRecordsScreen> createState() => _AdminMedicalRecordsScreenState();
}

class _AdminMedicalRecordsScreenState extends State<AdminMedicalRecordsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medical Records Management'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                // Tabs
                const TabBar(
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Lab Reports'),
                    Tab(text: 'Prescriptions'),
                    Tab(text: 'Other'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildRecordsList('all'),
            _buildRecordsList('Lab Report'),
            _buildRecordsList('Prescription'),
            _buildRecordsList('Other'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Show options to manage records
            _showManagementOptions();
          },
          child: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Widget _buildRecordsList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRecordsStream(type),
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
            child: Text('No ${type == 'all' ? 'medical records' : '$type records'} found'),
          );
        }

        return ListView.builder(
          itemCount: records.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final record = records[index].data() as Map<String, dynamic>;
            final recordId = records[index].id;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: _getRecordTypeIcon(record['type']),
                ),
                title: Text(record['title'] ?? 'Untitled Record'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${record['patientName'] ?? 'Unknown'}'),
                    Text('Doctor: Dr. ${record['doctorName'] ?? 'Unknown'}'),
                    Text('Date: ${_formatDate(record['createdAt'] as Timestamp)}'),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'backup',
                      child: Text('Backup'),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
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
    );
  }

  Stream<QuerySnapshot> _getRecordsStream(String type) {
    Query query = _firestore.collection('medical_records')
        .orderBy('createdAt', descending: true);

    if (type != 'All') {
      query = query.where('type', isEqualTo: type);
    }

    // Apply search filter if text is entered
    if (_searchController.text.isNotEmpty) {
      query = query.where('searchTerms', arrayContains: _searchController.text.toLowerCase());
    }

    return query.snapshots();
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

  void _showRecordDetails(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                _buildDetailRow('Record Type', record['type'] ?? 'Unknown'),
                _buildDetailRow('Patient', record['patientName'] ?? 'Unknown'),
                _buildDetailRow('Doctor', 'Dr. ${record['doctorName'] ?? 'Unknown'}'),
                _buildDetailRow('Created', _formatDate(record['createdAt'] as Timestamp)),
                _buildDetailRow('Status', record['status'] ?? 'Active'),
                if (record['description'] != null)
                  _buildDetailRow('Description', record['description']),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement download functionality
                  },
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

  Icon _getRecordTypeIcon(String? type) {
    switch (type) {
      case 'Lab Report':
        return const Icon(Icons.science);
      case 'Prescription':
        return const Icon(Icons.medical_services);
      case 'Imaging':
        return const Icon(Icons.image);
      default:
        return const Icon(Icons.description);
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleRecordAction(String action, String recordId, Map<String, dynamic> record) async {
    switch (action) {
      case 'view':
        _showRecordDetails(record);
        break;
      case 'backup':
        await _backupRecord(recordId);
        break;
      case 'archive':
        await _archiveRecord(recordId);
        break;
      case 'delete':
        await _deleteRecord(recordId);
        break;
    }
  }

  Future<void> _backupRecord(String recordId) async {
    // Implement backup functionality
  }

  Future<void> _archiveRecord(String recordId) async {
    // Implement archive functionality
  }

  Future<void> _deleteRecord(String recordId) async {
    // Implement delete functionality
  }

  Future<void> _backupAllRecords() async {
    // Implement backup all functionality
  }

  Future<void> _archiveOldRecords() async {
    // Implement archive old records functionality
  }

  Future<void> _generateReport() async {
    // Implement report generation functionality
  }

  void _showRecordSettings() {
    // Implement settings dialog
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}