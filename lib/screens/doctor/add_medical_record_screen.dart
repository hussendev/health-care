import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medical_record_types.dart';
import '../../services/auth_service.dart';

class AddMedicalRecordScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const AddMedicalRecordScreen({Key? key, this.args}) : super(key: key);

  @override
  State<AddMedicalRecordScreen> createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends State<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _remarksController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _authService = AuthService();

  String? _selectedPatient;
  String? _selectedRecordType;
  File? _selectedFile;
  DateTime? _recordDate;
  bool _isUploading = false;

  final List<String> _recordTypes = [
    'Lab Report',
    'Imaging Report',
    'Prescription',
    'Treatment Plan',
    'Progress Notes',
    'Referral Letter',
    'Discharge Summary',
    'Medical Certificate',
    'Other',
  ];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        // Check file size (limit to 10MB)
        if (result.files.single.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be less than 10MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = File(result.files.single.path!);
          // Auto-fill title if empty
          if (_titleController.text.isEmpty) {
            _titleController.text = result.files.single.name.split('.').first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recordDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _recordDate) {
      setState(() => _recordDate = picked);
    }
  }

  Future<void> _uploadRecord() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final patientId = widget.args?['patientId'] ?? _selectedPatient;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _selectedFile!.path.split('.').last;
      final fileName = '${timestamp}_${_titleController.text}.$extension';

      // Upload file to Firebase Storage
      // final ref = _storage.ref().child('medical_records/$patientId/$fileName');
      // final uploadTask = ref.putFile(
      //   _selectedFile!,
      //   SettableMetadata(
      //     contentType: 'application/${extension.toLowerCase()}',
      //     customMetadata: {
      //       'title': _titleController.text,
      //       'type': _selectedRecordType!,
      //       'uploadedBy': 'doctor',
      //       'doctorId': _authService.currentUser?.uid ?? '',
      //       'uploadDate': DateTime.now().toIso8601String(),
      //     },
      //   ),
      // );

      // Monitor upload progress
      // uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      //   double progress = snapshot.bytesTransferred / snapshot.totalBytes;
      //   // You could add a progress indicator here
      // });

      // Wait for upload to complete and get URL
      // await uploadTask;
      // final downloadUrl = await ref.getDownloadURL();

      // Save metadata to Firestore
      await _firestore.collection('medical_records').add({
        'patientId': patientId,
        'doctorId': _authService.currentUser?.uid,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'remarks': _remarksController.text,
        'type': _selectedRecordType,
        'fileUrl': 'downloadUrl',
        'fileName': fileName,
        'fileType': extension,
        'recordDate': _recordDate ?? DateTime.now(),
        'uploadDate': FieldValue.serverTimestamp(),
        'uploadedBy': 'doctor',
        'fileSize': _selectedFile!.lengthSync(),
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading record: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medical Record'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.args?['patientId'] == null) ...[
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

                  return DropdownButtonFormField<String>(
                    value: _selectedPatient,
                    decoration: const InputDecoration(
                      labelText: 'Select Patient',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
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

            // Record Type
            DropdownButtonFormField<String>(
              value: _selectedRecordType,
              decoration: const InputDecoration(
                labelText: 'Record Type',
                border: OutlineInputBorder(),
              ),
              // items: _recordTypes.map((type) {
              //   return DropdownMenuItem(value: type, child: Text(type));
              // }).toList(),
              items: MedicalRecordType.allTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              validator: (value) {
                if (value == null) return 'Please select record type';
                return null;
              },
              onChanged: (value) {
                setState(() => _selectedRecordType = value);
              },
            ),
            const SizedBox(height: 16),

            // Record Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Record Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _recordDate == null
                      ? 'Select Date'
                      : '${_recordDate!.day}/${_recordDate!.month}/${_recordDate!.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Doctor's Remarks
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Doctor\'s Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // File Selection
            Card(
              child: InkWell(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile == null ? Icons.upload_file : Icons.file_present,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile == null
                            ? 'Select Document'
                            : _selectedFile!.path.split('/').last,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedFile == null
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Button
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadRecord,
              child: _isUploading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(width: 16),
                  Text('Uploading...'),
                ],
              )
                  : const Text('Upload Record'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}