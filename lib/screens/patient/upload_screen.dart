import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({Key? key}) : super(key: key);

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String? _selectedDocType;
  File? _selectedFile;
  bool _isUploading = false;
  DateTime? _documentDate;

  final List<String> _documentTypes = [
    'Medical Report',
    'Lab Result',
    'Prescription',
    'X-Ray',
    'CT Scan',
    'MRI',
    'Vaccination Record',
    'Insurance Document',
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
      initialDate: _documentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _documentDate) {
      setState(() {
        _documentDate = picked;
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = _authService.currentUser!.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _selectedFile!.path.split('.').last;
      final fileName = '${timestamp}_${_titleController.text}.$extension';

      // Upload file
      final ref = _storage.ref().child('medical_documents/$userId/$fileName');
      final uploadTask = ref.putFile(
        _selectedFile!,
        SettableMetadata(
          contentType: 'application/${extension.toLowerCase()}',
          customMetadata: {
            'title': _titleController.text,
            'type': _selectedDocType!,
            'uploadDate': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // You could add a progress indicator here
      });

      // Wait for upload to complete and get URL
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      // Save metadata to Firestore
      await _firestore.collection('medical_records').add({
        'patientId': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _selectedDocType,
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'fileSize': _selectedFile!.lengthSync(),
        'fileType': extension,
        'documentDate': _documentDate ?? DateTime.now(),
        'uploadDate': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        actions: [
          if (_selectedFile != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadDocument,
              child: _isUploading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 2,
                ),
              )
                  : const Text('Upload', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // File Selection Card
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
            const SizedBox(height: 16),

            // Document Information
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Document Type
            DropdownButtonFormField<String>(
              value: _selectedDocType,
              decoration: const InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _documentTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              validator: (value) {
                if (value == null) return 'Please select a document type';
                return null;
              },
              onChanged: (value) => setState(() => _selectedDocType = value),
            ),
            const SizedBox(height: 16),

            // Document Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Document Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _documentDate == null
                      ? 'Select Date'
                      : DateFormat('MMM dd, yyyy').format(_documentDate!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Upload Instructions
            if (_selectedFile == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Supported formats: PDF, JPG, PNG, DOC'),
                      Text('• Maximum file size: 10MB'),
                      Text('• Make sure documents are clear and readable'),
                      Text('• Personal information should be visible'),
                    ],
                  ),
                ),
              ),

            // send uploaded file to firestor

            ElevatedButton(
              onPressed: _isUploading ? null : _uploadDocument,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Upload Document', style: TextStyle(color: Colors.black)),
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
    super.dispose();
  }
}