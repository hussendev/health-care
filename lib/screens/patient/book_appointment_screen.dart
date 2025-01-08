import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? doctor;

  const BookAppointmentScreen({Key? key, this.doctor}) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isLoading = false;
  List<String> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    print(widget.doctor.toString());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime date) {
        // Disable weekends
        return date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday;
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
     await _loadAvailableTimeSlots(picked);
    }
  }

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    setState(() => _isLoading = true);
    try {

      // First, get doctor's schedule for the selected day
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(widget.doctor?['uid'])
          .get();

      final doctorData = doctorDoc.data();
      final schedule = doctorData?['schedule'] ?? {};

      // Get the day of week in lowercase (e.g., 'monday', 'tuesday', etc.)
      final dayOfWeek = DateFormat('EEEE').format(date).toLowerCase();
      final daySchedule = schedule[dayOfWeek];

      // If doctor is not available on this day or no schedule is set
      if (daySchedule == null || !(daySchedule['isAvailable'] ?? false)) {
        setState(() {
          _availableTimeSlots = [];
        });
        return;
      }

      // Generate time slots based on doctor's schedule
      final startTime = _parseTimeString(daySchedule['startTime'] ?? '09:00');
      final endTime = _parseTimeString(daySchedule['endTime'] ?? '17:00');

      List<String> slots = [];
      var currentTime = startTime;

      // Generate 30-minute slots between start and end time
      while (currentTime.isBefore(endTime)) {
        slots.add(
            '${currentTime.hour.toString().padLeft(2, '0')}:'
                '${currentTime.minute.toString().padLeft(2, '0')}'
        );
        currentTime = currentTime.add(const Duration(minutes: 30));
      }

      // Check existing appointments for the selected date
      final appointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor?['uid'])
          .where('date', isEqualTo: Timestamp.fromDate(
          DateTime(date.year, date.month, date.day)
      ))
          .get();

      // Remove booked time slots
      final bookedSlots = appointments.docs
          .map((doc) => doc.data()['time'] as String)
          .toList();

      setState(() {
        _availableTimeSlots = slots
            .where((slot) => !bookedSlots.contains(slot))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading time slots: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Helper method to parse time string to DateTime
  DateTime _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1])
    );
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Check if slot is still available
      final existingAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor?['uid'])
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate!))
          .where('time', isEqualTo: _selectedTime)
          .get();

      if (existingAppointments.docs.isNotEmpty) {
        throw 'Selected time slot is no longer available';
      }

      // Create appointment
      await _firestore.collection('appointments').add({
        'patientId': _authService.currentUser?.uid,
        'doctorId': widget.doctor?['uid'],
        'doctorName': widget.doctor?['name'],
        'date': Timestamp.fromDate(_selectedDate!),
        'time': _selectedTime,
        'reason': _reasonController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('patients').doc(_authService.currentUser?.uid).update({
        'doctors': FieldValue.arrayUnion([widget.doctor?['uid']]),
      });

      // Update doctor's document to include this patient
      await _firestore.collection('doctors').doc(widget.doctor?['uid']).update({
        'patients': FieldValue.arrayUnion([_authService.currentUser?.uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info Card
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text('Dr. ${widget.doctor?['name'] ?? ''}'),
                  subtitle: Text(widget.doctor?['specialty'] ?? ''),
                ),
              ),
              const SizedBox(height: 24),

              // Date Selection
              ListTile(
                title: const Text('Select Date'),
                subtitle: Text(_selectedDate == null
                    ? 'No date selected'
                    : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Time Selection
              if (_selectedDate != null) ...[
                const Text('Available Time Slots',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_availableTimeSlots.isEmpty)
                  const Text('No available time slots for selected date')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTimeSlots.map((time) {
                      return ChoiceChip(
                        label: Text(time),
                        selected: _selectedTime == time,
                        onSelected: (selected) {
                          setState(() => _selectedTime = selected ? time : null);
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
              ],

              // Reason Input
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Visit',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reason for visit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Book Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookAppointment,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Book Appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}