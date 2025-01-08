import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const AddPrescriptionScreen({Key? key, this.args}) : super(key: key);

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedPatient;
  List<Map<String, String>> _medications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If patient ID is passed through arguments, set it
    if (widget.args?['patientId'] != null) {
      _selectedPatient = widget.args!['patientId'];
    }
    // Add first empty medication
    _addNewMedication();
  }

  void _addNewMedication() {
    setState(() {
      _medications.add({
        'name': '',
        'dosage': '',
        'frequency': '',
        'duration': '',
        'instructions': '',
      });
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Format medications
      final List<Map<String, String>> formattedMedications = _medications
          .where((med) => med['name']!.isNotEmpty)
          .toList();

      // Create prescription document
      await _firestore.collection('prescriptions').add({
        'patientId': _selectedPatient,
        'doctorId': _authService.currentUser!.uid,
        'diagnosis': _diagnosisController.text,
        'medications': formattedMedications,
        'notes': _notesController.text,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prescription: $e')),
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
        title: const Text('Add Prescription'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePrescription,
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
            if (_selectedPatient == null) ...[
              // Patient Selection
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('patients')
                    .where('doctors', arrayContains: _authService.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final patients = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedPatient,
                    decoration: const InputDecoration(
                      labelText: 'Select Patient',
                      border: OutlineInputBorder(),
                    ),
                    items: patients.map((patient) {
                      final data = patient.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: patient.id,
                        child: Text(data['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) return 'Please select a patient';
                      return null;
                    },
                    onChanged: (value) {
                      setState(() => _selectedPatient = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Diagnosis
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter diagnosis';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Medications
            const Text(
              'Medications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(_medications.length, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Medication ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_medications.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeMedication(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _medications[index]['name'],
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medicine name';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _medications[index]['name'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _medications[index]['dosage'],
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter dosage';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _medications[index]['dosage'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _medications[index]['frequency'],
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Once daily, Twice daily',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter frequency';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _medications[index]['frequency'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _medications[index]['duration'],
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 7 days, 2 weeks',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _medications[index]['duration'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _medications[index]['instructions'],
                        decoration: const InputDecoration(
                          labelText: 'Special Instructions',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Take after meals',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          setState(() {
                            _medications[index]['instructions'] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Add Medication Button
            OutlinedButton.icon(
              onPressed: _addNewMedication,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Medication'),
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            // create button to send prescription
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePrescription,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Prescription', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}