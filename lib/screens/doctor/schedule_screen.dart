import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  bool _isLoading = true;

  Map<String, Map<String, dynamic>> _schedule = {};
  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final docSnapshot = await _firestore
          .collection('doctors')
          .doc(_authService.currentUser?.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['schedule'] != null) {
          setState(() {
            _schedule = Map<String, Map<String, dynamic>>.from(data['schedule']);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSchedule() async {
    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection('doctors')
          .doc(_authService.currentUser?.uid)
          .update({
        'schedule': _schedule,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating schedule: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }

  void _editDaySchedule(String day) async {
    final currentSchedule = _schedule[day.toLowerCase()] ??
        {'isAvailable': false, 'startTime': '09:00', 'endTime': '17:00'};

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DayScheduleDialog(
        day: day,
        schedule: currentSchedule,
      ),
    );

    if (result != null) {
      setState(() {
        _schedule[day.toLowerCase()] = result;
      });
      await _updateSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Schedule'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Schedule Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Day')),
                Expanded(flex: 2, child: Text('Hours')),
                Expanded(child: Text('Status')),
              ],
            ),
          ),

          // Schedule List
          Expanded(
            child: ListView.builder(
              itemCount: _daysOfWeek.length,
              itemBuilder: (context, index) {
                final day = _daysOfWeek[index];
                final daySchedule = _schedule[day.toLowerCase()] ??
                    {'isAvailable': false, 'startTime': '09:00', 'endTime': '17:00'};

                return ListTile(
                  title: Text(day),
                  subtitle: daySchedule['isAvailable']
                      ? Text('${daySchedule['startTime']} - ${daySchedule['endTime']}')
                      : const Text('Not Available'),
                  trailing: Switch(
                    value: daySchedule['isAvailable'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _schedule[day.toLowerCase()] = {
                          ...daySchedule,
                          'isAvailable': value,
                        };
                      });
                      _updateSchedule();
                    },
                  ),
                  onTap: () => _editDaySchedule(day),
                );
              },
            ),
          ),

          // Break Time Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // Show break time settings dialog
                showDialog(
                  context: context,
                  builder: (context) => const BreakTimeDialog(),
                );
              },
              child: const Text('Set Break Times'),
            ),
          ),
        ],
      ),
    );
  }
}

// Day Schedule Dialog
class DayScheduleDialog extends StatefulWidget {
  final String day;
  final Map<String, dynamic> schedule;

  const DayScheduleDialog({
    Key? key,
    required this.day,
    required this.schedule,
  }) : super(key: key);

  @override
  State<DayScheduleDialog> createState() => _DayScheduleDialogState();
}

class _DayScheduleDialogState extends State<DayScheduleDialog> {
  late bool _isAvailable;
  late String _startTime;
  late String _endTime;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.schedule['isAvailable'] ?? false;
    _startTime = widget.schedule['startTime'] ?? '09:00';
    _endTime = widget.schedule['endTime'] ?? '17:00';
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay initialTime = TimeOfDay(
      hour: int.parse(isStart ? _startTime.split(':')[0] : _endTime.split(':')[0]),
      minute: int.parse(isStart ? _startTime.split(':')[1] : _endTime.split(':')[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = '${picked.hour.toString().padLeft(2, '0')}:'
              '${picked.minute.toString().padLeft(2, '0')}';
        } else {
          _endTime = '${picked.hour.toString().padLeft(2, '0')}:'
              '${picked.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.day} Schedule'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Available'),
            value: _isAvailable,
            onChanged: (value) {
              setState(() => _isAvailable = value);
            },
          ),
          if (_isAvailable) ...[
            ListTile(
              title: const Text('Start Time'),
              trailing: TextButton(
                onPressed: () => _selectTime(true),
                child: Text(_startTime),
              ),
            ),
            ListTile(
              title: const Text('End Time'),
              trailing: TextButton(
                onPressed: () => _selectTime(false),
                child: Text(_endTime),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'isAvailable': _isAvailable,
              'startTime': _startTime,
              'endTime': _endTime,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Break Time Dialog
class BreakTimeDialog extends StatefulWidget {
  const BreakTimeDialog({Key? key}) : super(key: key);

  @override
  State<BreakTimeDialog> createState() => _BreakTimeDialogState();
}

class _BreakTimeDialogState extends State<BreakTimeDialog> {
  final List<Map<String, String>> _breakTimes = [];

  void _addBreakTime() {
    setState(() {
      _breakTimes.add({
        'startTime': '12:00',
        'endTime': '13:00',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Break Times'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._breakTimes.map((breakTime) => ListTile(
              title: Text('${breakTime['startTime']} - ${breakTime['endTime']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _breakTimes.remove(breakTime);
                  });
                },
              ),
            )),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Break Time'),
              onPressed: _addBreakTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Save break times
            Navigator.pop(context, _breakTimes);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}