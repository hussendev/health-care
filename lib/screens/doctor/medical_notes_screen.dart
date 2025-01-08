import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class MedicalNotesScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const MedicalNotesScreen({Key? key, required this.args}) : super(key: key);

  @override
  State<MedicalNotesScreen> createState() => _MedicalNotesScreenState();
}

class _MedicalNotesScreenState extends State<MedicalNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _observationsController = TextEditingController();
  final _treatmentPlanController = TextEditingController();
  final _notesController = TextEditingController();
  final _vitalSignsController = TextEditingController();

  List<String> _allergies = [];
  bool _isLoading = false;
  String _selectedBloodPressure = 'Normal';
  String _selectedTemperature = 'Normal';

  final List<String> _bloodPressureOptions = [
    'Low',
    'Normal',
    'Pre-high',
    'High',
  ];

  final List<String> _temperatureOptions = [
    'Low',
    'Normal',
    'Fever',
    'High Fever',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingNotes();
  }

  Future<void> _loadExistingNotes() async {
    try {
      final appointmentId = widget.args['appointmentId'];
      if (appointmentId != null) {
        final doc = await _firestore
            .collection('medical_notes')
            .where('appointmentId', isEqualTo: appointmentId)
            .limit(1)
            .get();

        if (doc.docs.isNotEmpty) {
          final data = doc.docs.first.data();
          setState(() {
            _diagnosisController.text = data['diagnosis'] ?? '';
            _symptomsController.text = data['symptoms'] ?? '';
            _observationsController.text = data['observations'] ?? '';
            _treatmentPlanController.text = data['treatmentPlan'] ?? '';
            _notesController.text = data['notes'] ?? '';
            _vitalSignsController.text = data['vitalSigns'] ?? '';
            _allergies = List<String>.from(data['allergies'] ?? []);
            _selectedBloodPressure = data['bloodPressure'] ?? 'Normal';
            _selectedTemperature = data['temperature'] ?? 'Normal';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notes: $e')),
        );
      }
    }
  }

  void _addAllergy() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Allergy'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Allergy',
              hintText: 'Enter allergy or medication',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _allergies.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMedicalNotes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'patientId': widget.args['patientId'],
        'doctorId': _authService.currentUser?.uid,
        'appointmentId': widget.args['appointmentId'],
        'diagnosis': _diagnosisController.text,
        'symptoms': _symptomsController.text,
        'observations': _observationsController.text,
        'treatmentPlan': _treatmentPlanController.text,
        'notes': _notesController.text,
        'vitalSigns': _vitalSignsController.text,
        'allergies': _allergies,
        'bloodPressure': _selectedBloodPressure,
        'temperature': _selectedTemperature,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Check if notes already exist for this appointment
      final existingNotes = await _firestore
          .collection('medical_notes')
          .where('appointmentId', isEqualTo: widget.args['appointmentId'])
          .limit(1)
          .get();

      if (existingNotes.docs.isNotEmpty) {
        // Update existing notes
        await _firestore
            .collection('medical_notes')
            .doc(existingNotes.docs.first.id)
            .update(data);
      } else {
        // Create new notes
        await _firestore.collection('medical_notes').add(data);
      }

      // Update appointment status
      await _firestore
          .collection('appointments')
          .doc(widget.args['appointmentId'])
          .update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical notes saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving notes: $e')),
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
        title: const Text('Medical Notes'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveMedicalNotes,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Info Card (You can expand this)
            FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('patients')
                  .doc(widget.args['patientId'])
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final patientData = snapshot.data!.data() as Map<String, dynamic>?;
                  return Card(
                    child: ListTile(
                      title: Text(patientData?['name'] ?? 'Unknown Patient'),
                      subtitle: Text('Patient ID: ${widget.args['patientId']}'),
                    ),
                  );
                }
                return const Card(
                  child: ListTile(
                    title: Text('Loading patient info...'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Vital Signs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vital Signs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodPressure,
                      decoration: const InputDecoration(
                        labelText: 'Blood Pressure',
                        border: OutlineInputBorder(),
                      ),
                      items: _bloodPressureOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedBloodPressure = value!);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTemperature,
                      decoration: const InputDecoration(
                        labelText: 'Temperature',
                        border: OutlineInputBorder(),
                      ),
                      items: _temperatureOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTemperature = value!);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _vitalSignsController,
                      decoration: const InputDecoration(
                        labelText: 'Other Vital Signs',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Allergies
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
                          'Allergies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          onPressed: _addAllergy,
                        ),
                      ],
                    ),
                    if (_allergies.isEmpty)
                      const Text('No allergies recorded')
                    else
                      Wrap(
                        spacing: 8,
                        children: _allergies.map((allergy) {
                          return Chip(
                            label: Text(allergy),
                            onDeleted: () {
                              setState(() {
                                _allergies.remove(allergy);
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Symptoms and Diagnosis
            TextFormField(
              controller: _symptomsController,
              decoration: const InputDecoration(
                labelText: 'Symptoms',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter symptoms';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter diagnosis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Observations
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(
                labelText: 'Observations',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Treatment Plan
            TextFormField(
              controller: _treatmentPlanController,
              decoration: const InputDecoration(
                labelText: 'Treatment Plan',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter treatment plan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Additional Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _observationsController.dispose();
    _treatmentPlanController.dispose();
    _notesController.dispose();
    _vitalSignsController.dispose();
    super.dispose();
  }
}