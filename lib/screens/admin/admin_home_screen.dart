import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'User Verification',
            Icons.verified_user,
            'Verify new user registrations',
                () => Navigator.pushNamed(context, '/admin/verify-users'),
            Colors.blue,
          ),
          _buildDashboardCard(
            context,
            'Manage Users',
            Icons.people,
            'Manage all users',
                () => Navigator.pushNamed(context, '/admin/users'),
            Colors.green,
          ),
          _buildDashboardCard(
            context,
            'Analytics',
            Icons.analytics,
            'View system analytics',
                () => Navigator.pushNamed(context, '/admin/analytics'),
            Colors.purple,
          ),
          _buildDashboardCard(
            context,
            'Billing',
            Icons.payment,
            'Manage billing and payments',
                () => Navigator.pushNamed(context, '/admin/billing'),
            Colors.orange,
          ),
          _buildDashboardCard(
            context,
            'Medical Records',
            Icons.folder_shared,
            'Manage medical records',
                () => Navigator.pushNamed(context, '/admin/medical-records'),
            Colors.red,
          ),
          _buildDashboardCard(
            context,
            'Settings',
            Icons.settings,
            'System settings',
                () => Navigator.pushNamed(context, '/admin/settings'),
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context,
      String title,
      IconData icon,
      String description,
      VoidCallback onTap,
      Color color,
      ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}