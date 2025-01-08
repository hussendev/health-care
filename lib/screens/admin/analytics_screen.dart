import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _selectedTimeRange = 'month';

  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'activeUsers': 0,
    'totalDoctors': 0,
    'totalPatients': 0,
    'totalAppointments': 0,
    'completedAppointments': 0,
    'pendingAppointments': 0,
    'canceledAppointments': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // Load user statistics
      final usersSnapshot = await _firestore.collection('users').get();
      final doctors = usersSnapshot.docs.where((doc) =>
      doc.data()['userType'] == 'doctor').length;
      final patients = usersSnapshot.docs.where((doc) =>
      doc.data()['userType'] == 'patient').length;
      final activeUsers = usersSnapshot.docs.where((doc) =>
      doc.data()['isActive'] == true).length;

      // Load appointment statistics
      final appointmentsSnapshot = await _firestore.collection('appointments').get();
      final completed = appointmentsSnapshot.docs.where((doc) =>
      doc.data()['status'] == 'accept').length;
      final pending = appointmentsSnapshot.docs.where((doc) =>
      doc.data()['status'] == 'pending').length;
      final canceled = appointmentsSnapshot.docs.where((doc) =>
      doc.data()['status'] == 'reject').length;

      setState(() {
        _stats = {
          'totalUsers': usersSnapshot.docs.length,
          'activeUsers': activeUsers,
          'totalDoctors': doctors,
          'totalPatients': patients,
          'totalAppointments': appointmentsSnapshot.docs.length,
          'completedAppointments': completed,
          'pendingAppointments': pending,
          'canceledAppointments': canceled,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Analytics Dashboard'),
    actions: [
    PopupMenuButton<String>(
    initialValue: _selectedTimeRange,
    onSelected: (value) {
    setState(() => _selectedTimeRange = value);
    _loadAnalytics();
    },
    itemBuilder: (context) => [
    const PopupMenuItem(
    value: 'week',
    child: Text('This Week'),
    ),
    const PopupMenuItem(
    value: 'month',
    child: Text('This Month'),
    ),
    const PopupMenuItem(
      value: 'year',
      child: Text('This Year'),
    ),
    ],
    ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadAnalytics,
      ),
    ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                _buildSummaryCard(
                  'Total Users',
                  _stats['totalUsers'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Active Users',
                  _stats['activeUsers'].toString(),
                  Icons.person_outline,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryCard(
                  'Doctors',
                  _stats['totalDoctors'].toString(),
                  Icons.medical_services,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Patients',
                  _stats['totalPatients'].toString(),
                  Icons.personal_injury,
                  Colors.orange,
                ),
              ],
            ),

            // Appointments Chart
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: _stats['completedAppointments'].toDouble(),
                              title: 'Completed',
                              radius: 60,
                            ),
                            PieChartSectionData(
                              color: Colors.blue,
                              value: _stats['pendingAppointments'].toDouble(),
                              title: 'Pending',
                              radius: 60,
                            ),
                            PieChartSectionData(
                              color: Colors.red,
                              value: _stats['canceledAppointments'].toDouble(),
                              title: 'Canceled',
                              radius: 60,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Activity Timeline
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to detailed activity log
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    _buildActivityTimeline(),
                  ],
                ),
              ),
            ),

            // System Health
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Health',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHealthIndicator(
                      'Database Status',
                      'Healthy',
                      Colors.green,
                    ),
                    _buildHealthIndicator(
                      'Storage Usage',
                      '45%',
                      Colors.orange,
                    ),
                    _buildHealthIndicator(
                      'API Response Time',
                      '120ms',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final activities = snapshot.data?.docs ?? [];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                child: _getActivityIcon(activity['type']),
              ),
              title: Text(activity['description'] ?? ''),
              subtitle: Text(_formatTimestamp(activity['timestamp'] as Timestamp)),
            );
          },
        );
      },
    );
  }

  Widget _getActivityIcon(String type) {
    switch (type) {
      case 'appointment':
        return const Icon(Icons.calendar_today, size: 20);
      case 'user':
        return const Icon(Icons.person, size: 20);
      case 'medical':
        return const Icon(Icons.medical_services, size: 20);
      default:
        return const Icon(Icons.info, size: 20);
    }
  }

  Widget _buildHealthIndicator(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Chip(
            label: Text(value),
            backgroundColor: color.withOpacity(0.1),
            labelStyle: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}