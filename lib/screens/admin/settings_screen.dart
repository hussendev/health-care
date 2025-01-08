import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // System Settings
  bool _autoBackup = true;
  bool _emailNotifications = true;
  bool _requireVerification = true;
  String _backupFrequency = 'daily';
  String _retentionPeriod = '30';

  // Notifications Settings
  bool _newUserAlerts = true;
  bool _appointmentAlerts = true;
  bool _systemAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final doc = await _firestore.collection('settings').doc('system').get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _autoBackup = data['autoBackup'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _requireVerification = data['requireVerification'] ?? true;
          _backupFrequency = data['backupFrequency'] ?? 'daily';
          _retentionPeriod = data['retentionPeriod']?.toString() ?? '30';
          _newUserAlerts = data['newUserAlerts'] ?? true;
          _appointmentAlerts = data['appointmentAlerts'] ?? true;
          _systemAlerts = data['systemAlerts'] ?? true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('settings').doc('system').set({
        'autoBackup': _autoBackup,
        'emailNotifications': _emailNotifications,
        'requireVerification': _requireVerification,
        'backupFrequency': _backupFrequency,
        'retentionPeriod': int.parse(_retentionPeriod),
        'newUserAlerts': _newUserAlerts,
        'appointmentAlerts': _appointmentAlerts,
        'systemAlerts': _systemAlerts,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('System Settings'),
    actions: [
    TextButton.icon(
    icon: const Icon(Icons.save, color: Colors.white),
    label: const Text('Save', style: TextStyle(color: Colors.white)),
    onPressed: _isLoading ? null : _saveSettings,
    ),
    ],
    ),
    body: _isLoading
    ? const Center(child: CircularProgressIndicator())
        : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // System Settings Section
        const Text(
          'System Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Automatic Backup'),
                subtitle: const Text('Automatically backup system data'),
                value: _autoBackup,
                onChanged: (value) => setState(() => _autoBackup = value),
              ),
              const Divider(),
              ListTile(
                title: const Text('Backup Frequency'),
                subtitle: Text(_backupFrequency),
                trailing: DropdownButton<String>(
                  value: _backupFrequency,
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _backupFrequency = value);
                    }
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Data Retention Period (days)'),
                subtitle: Text('Keep records for $_retentionPeriod days'),
                trailing: SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _retentionPeriod),
                    onChanged: (value) => _retentionPeriod = value,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Notification Settings Section
        const SizedBox(height: 24),
        const Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Send email notifications'),
                value: _emailNotifications,
                onChanged: (value) => setState(() => _emailNotifications = value),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('New User Alerts'),
                subtitle: const Text('Get notified about new user registrations'),
                value: _newUserAlerts,
                onChanged: _emailNotifications
                    ? (value) => setState(() => _newUserAlerts = value)
                    : null,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Appointment Alerts'),
                subtitle: const Text('Get notified about appointment changes'),
                value: _appointmentAlerts,
                onChanged: _emailNotifications
                    ? (value) => setState(() => _appointmentAlerts = value)
                    : null,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('System Alerts'),
                subtitle: const Text('Get notified about system events'),
                value: _systemAlerts,
                onChanged: _emailNotifications
                    ? (value) => setState(() => _systemAlerts = value)
                    : null,
              ),
            ],
          ),
        ),

        // Security Settings Section
        const SizedBox(height: 24),
        const Text(
          'Security Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Require User Verification'),
                subtitle: const Text('Manually verify new user registrations'),
                value: _requireVerification,
                onChanged: (value) => setState(() => _requireVerification = value),
              ),
              ListTile(
                title: const Text('Password Policy'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showPasswordPolicyDialog,
                ),
              ),
              ListTile(
                title: const Text('Session Timeout'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showSessionTimeoutDialog,
                ),
              ),
            ],
          ),
        ),

        // Maintenance Section
        const SizedBox(height: 24),
        const Text(
          'System Maintenance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Manual Backup'),
                trailing: ElevatedButton(
                  onPressed: _performBackup,
                  child: const Text('Backup Now'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services),
                title: const Text('Clean Old Data'),
                trailing: ElevatedButton(
                  onPressed: _cleanOldData,
                  child: const Text('Clean'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('System Optimization'),
                trailing: ElevatedButton(
                  onPressed: _optimizeSystem,
                  child: const Text('Optimize'),
                ),
              ),
            ],
          ),
        ),

        // Action Buttons
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _exportSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Export Settings'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _resetSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Reset to Default'),
              ),
            ),
          ],
        ),
      ],
    ),
    );
  }

  void _showPasswordPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Policy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add password policy settings
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save password policy
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSessionTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add session timeout settings
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save session timeout
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup() async {
    // Implement backup functionality
  }

  Future<void> _cleanOldData() async {
    // Implement data cleaning functionality
  }

  Future<void> _optimizeSystem() async {
    // Implement system optimization
  }

  Future<void> _exportSettings() async {
    // Implement settings export
  }

  Future<void> _resetSettings() async {
    // Implement settings reset
  }
}