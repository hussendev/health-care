import 'package:flutter/material.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/auth_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
      ),
      drawer: AppDrawer(userType: 'patient'),
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
                () => Navigator.pushNamed(context, '/patient/appointments'),
          ),
          _buildMenuCard(
            context,
            'Find Doctor',
            Icons.search,
                () => Navigator.pushNamed(context, '/patient/find-doctor'),
          ),
          _buildMenuCard(
            context,
            'Medical Records',
            Icons.folder_outlined,
                () => Navigator.pushNamed(context, '/patient/medical-records'),
          ),
          _buildMenuCard(
            context,
            'Upload Documents',
            Icons.upload_file,
                () => Navigator.pushNamed(context, '/patient/upload'),
          ),
          _buildMenuCard(
            context,
            'My Profile',
            Icons.person_outline,
                () => Navigator.pushNamed(context, '/patient/profile'),
          ),
          _buildMenuCard(
            context,
            'Medical History',
            Icons.history,
                () => Navigator.pushNamed(context, '/patient/history'),
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
