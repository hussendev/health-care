import 'package:flutter/material.dart';

class DayScheduleDialog extends StatefulWidget {
  final String day;
  final String startTime;
  final String endTime;

  const DayScheduleDialog({
    Key? key,
    required this.day,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<DayScheduleDialog> createState() => _DayScheduleDialogState();
}

class _DayScheduleDialogState extends State<DayScheduleDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.startTime);
    _endTime = _parseTime(widget.endTime);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set ${widget.day} Schedule'),
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
                onPressed: () => _selectTime(context, true),
                child: Text(_formatTime(_startTime)),
              ),
            ),
            ListTile(
              title: const Text('End Time'),
              trailing: TextButton(
                onPressed: () => _selectTime(context, false),
                child: Text(_formatTime(_endTime)),
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
            if (_isAvailable) {
              Navigator.pop(context, {
                'start': _formatTime(_startTime),
                'end': _formatTime(_endTime),
              });
            } else {
              Navigator.pop(context, null);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

