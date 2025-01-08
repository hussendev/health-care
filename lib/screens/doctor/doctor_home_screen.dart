import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../services/auth_service.dart';
import '../../widgets/common/app_drawer.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(userType: 'doctor'),
      appBar: AppBar(

        title: const Text('Doctor Dashboard'),
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
          _buildMenuCard(
            context,
            'My Appointments',
            Icons.calendar_today,
                () => Navigator.pushNamed(context, '/doctor/appointments'),
          ),
          _buildMenuCard(
            context,
            'Patient List',
            Icons.people_outline,
                () => Navigator.pushNamed(context, '/doctor/patients'),
          ),
          _buildMenuCard(
            context,
            'Medical Records',
            Icons.folder_outlined,
                () => Navigator.pushNamed(context, '/doctor/medical-records'),
          ),
          _buildMenuCard(
            context,
            'Prescriptions',
            Icons.medical_services_outlined,
                () => Navigator.pushNamed(context, '/doctor/prescriptions'),
          ),
          _buildMenuCard(
            context,
            'My Profile',
            Icons.person_outline,
                () => Navigator.pushNamed(context, '/doctor/profile'),
          ),
          _buildMenuCard(
            context,
            'Schedule',
            Icons.schedule,
                () => Navigator.pushNamed(context, '/doctor/schedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}