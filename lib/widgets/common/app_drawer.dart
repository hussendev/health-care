import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String userType;

  const AppDrawer({Key? key, required this.userType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35),
                ),
                const SizedBox(height: 10),
                Text(
                  'Healthcare App',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  userType.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (userType == 'patient') ...[
            _buildDrawerItem(
              icon: Icons.calendar_today,
              title: 'My Appointments',
              onTap: () => Navigator.pushNamed(context, '/patient/appointments'),
            ),
            _buildDrawerItem(
              icon: Icons.search,
              title: 'Find Doctor',
              onTap: () => Navigator.pushNamed(context, '/patient/find-doctor'),
            ),
            _buildDrawerItem(
              icon: Icons.folder_outlined,
              title: 'Medical Records',
              onTap: () => Navigator.pushNamed(context, '/patient/medical-records'),
            ),
          ] else if (userType == 'doctor') ...[
            _buildDrawerItem(
              icon: Icons.calendar_today,
              title: 'My Appointments',
              onTap: () => Navigator.pushNamed(context, '/doctor/appointments'),
            ),
            _buildDrawerItem(
              icon: Icons.people_outline,
              title: 'My Patients',
              onTap: () => Navigator.pushNamed(context, '/doctor/patients'),
            ),
            _buildDrawerItem(
              icon: Icons.medical_services_outlined,
              title: 'Prescriptions',
              onTap: () => Navigator.pushNamed(context, '/doctor/prescriptions'),
            ),
          ] else if (userType == 'admin') ...[
            _buildDrawerItem(
              icon: Icons.people_outline,
              title: 'User Management',
              onTap: () => Navigator.pushNamed(context, '/admin/users'),
            ),
            _buildDrawerItem(
              icon: Icons.verified_user_outlined,
              title: 'Verify Users',
              onTap: () => Navigator.pushNamed(context, '/admin/verify-users'),
            ),
            _buildDrawerItem(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
            ),
          ],
          const Divider(),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () => Navigator.pushNamed(context, '/$userType/profile'),
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => Navigator.pushNamed(context, '/$userType/settings'),
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}