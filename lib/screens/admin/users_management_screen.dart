import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _selectedUserType = 'all';
  bool _showOnlyActive = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Users'),
              Tab(text: 'Patients'),
              Tab(text: 'Doctors'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Show Only Active Users'),
                    value: _showOnlyActive,
                    onChanged: (value) => setState(() => _showOnlyActive = value),
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: TabBarView(
                children: [
                  _buildUserList('all'),
                  _buildUserList('patient'),
                  _buildUserList('doctor'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String userType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUsersStream(userType),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = users.where((doc) {
          final userData = doc.data() as Map<String, dynamic>;
          final searchQuery = _searchController.text.toLowerCase();
          final name = (userData['name'] ?? '').toLowerCase();
          final email = (userData['email'] ?? '').toLowerCase();

          return (name.contains(searchQuery) || email.contains(searchQuery));
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final user = filteredUsers[index].data() as Map<String, dynamic>;
            final userId = filteredUsers[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    user['userType'] == 'patient'
                        ? Icons.person
                        : Icons.medical_services,
                  ),
                ),
                title: Text(user['name'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${user['email']}'),
                    Text(
                      'Status: ${user['isActive'] ? 'Active' : 'Inactive'}',
                      style: TextStyle(
                        color: user['isActive'] ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('View Details'),
                        onTap: () {
                          Navigator.pop(context);
                          _showUserDetails(user);
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(
                          user['isActive'] ? Icons.block : Icons.check_circle,
                          color: user['isActive'] ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          user['isActive'] ? 'Deactivate' : 'Activate',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _toggleUserStatus(userId, user['isActive']);
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.backup),
                        title: const Text('Backup Data'),
                        onTap: () {
                          Navigator.pop(context);
                          _backupUserData(userId);
                        },
                      ),
                    ),
                  ],
                ),
                onTap: () => _showUserDetails(user),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getUsersStream(String userType) {
    Query query = _firestore.collection('users');

    if (userType != 'all') {
      query = query.where('userType', isEqualTo: userType);
    }

    if (_showOnlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots();
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${currentStatus ? 'deactivated' : 'activated'} successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user status: $e')),
      );
    }
  }

  Future<void> _backupUserData(String userId) async {
    // Implement backup functionality
  }

  void _showUserDetails(Map<String, dynamic> user) async {
    // Fetch additional details based on user type
    Map<String, dynamic>? additionalDetails;

    try {
      if (user['userType'] == 'doctor') {
        final doctorDoc = await _firestore
            .collection('doctors')
            .doc(user['uid'])
            .get();

        if (doctorDoc.exists) {
          additionalDetails = doctorDoc.data();
        }
      } else if (user['userType'] == 'patient') {
        final patientDoc = await _firestore
            .collection('patients')
            .doc(user['uid'])
            .get();

        if (patientDoc.exists) {
          additionalDetails = patientDoc.data();
        }
      }
    } catch (e) {
      print('Error fetching additional details: $e');
    }

    if (!mounted) return;

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
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Basic User Info
              _buildSectionTitle('Basic Information'),
              _buildDetailRow('Name', user['name'] ?? 'Unknown'),
              _buildDetailRow('Email', user['email'] ?? 'Unknown'),
              _buildDetailRow('User Type', user['userType'] ?? 'Unknown'),
              _buildDetailRow('Status', user['isActive'] ? 'Active' : 'Inactive'),
              _buildDetailRow('ID', additionalDetails?['doctorId'] ?? 'Not assigned'),

              // Contact Information
              const SizedBox(height: 16),
              _buildSectionTitle('Contact Information'),
              _buildDetailRow('Phone', additionalDetails?['phone'] ?? 'Not provided'),
              _buildDetailRow('Address', additionalDetails?['address'] ?? 'Not provided'),

              // Doctor Specific Details
              if (user['userType'] == 'doctor' && additionalDetails != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Professional Information'),
                _buildDetailRow('Specialty', additionalDetails['specialty'] ?? 'Not specified'),
                _buildDetailRow('Registration Number', additionalDetails['registrationNumber'] ?? 'Not provided'),
                _buildDetailRow('Experience', '${additionalDetails['experience'] ?? 0} years'),
                _buildDetailRow('Consultation Fee', '\$${additionalDetails['consultationFee'] ?? 0}'),
                if (additionalDetails['qualifications'] != null)
                  _buildDetailRow('Qualifications',
                      (additionalDetails['qualifications'] as List).join(', ')),
                if (additionalDetails['languages'] != null)
                  _buildDetailRow('Languages',
                      (additionalDetails['languages'] as List).join(', ')),

                if (additionalDetails['services'] != null)
                  _buildDetailRow('services',
                      (additionalDetails['services'] as List).join(', ')),
              ],

              // Patient Specific Details
              if (user['userType'] == 'patient' && additionalDetails != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Medical Information'),
                _buildDetailRow('Blood Group', additionalDetails['bloodGroup'] ?? 'Not specified'),
                _buildDetailRow('Age', _calculateAge(additionalDetails['dateOfBirth'])),
                if (additionalDetails['allergies'] != null)
                  _buildDetailRow('Allergies',
                      (additionalDetails['allergies'] as List).join(', ')),
                if (additionalDetails['chronicDiseases'] != null)
                  _buildDetailRow('Chronic Diseases',
                      (additionalDetails['chronicDiseases'] as List).join(', ')),

                const SizedBox(height: 8),
                _buildSectionTitle('Emergency Contact'),
                _buildDetailRow('Name', additionalDetails['emergencyContact']?['name'] ?? 'Not provided'),
                _buildDetailRow('Relation', additionalDetails['emergencyContact']?['relation'] ?? 'Not provided'),
                _buildDetailRow('Phone', additionalDetails['emergencyContact']?['phoneNumber'] ?? 'Not provided'),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Implement data export
                      },
                      child: const Text('Export Data'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement edit functionality
                      },
                      child: const Text('Edit User'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _calculateAge(Timestamp? dateOfBirth) {
    if (dateOfBirth == null) return 'Not provided';

    final today = DateTime.now();
    final birthDate = dateOfBirth.toDate();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return '$age years';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}