import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../services/auth_service.dart';
// import '../../widgets/custom_text_field.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  // State variables
  String? _selectedSpecialty;
  List<String> _qualifications = [];
  List<String> _languages = [];
  List<String> _services = [];
  String? _profileImageUrl;
  File? _newProfileImage;
  bool _isOnline = false;
  bool _isEditing = false;
  bool _isLoading = true;

  final List<String> _specialties = [
    'General',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Psychiatrist',
    'Orthopedist',
    'Ophthalmologist',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = 'General';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _firestore
          .collection('doctors')
          .doc(_authService.currentUser?.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _experienceController.text = data['experience']?.toString() ?? '';
          _bioController.text = data['bio'] ?? '';
          _consultationFeeController.text =
              data['consultationFee']?.toString() ?? '';
          _registrationNumberController.text = data['registrationNumber'] ?? '';
          _selectedSpecialty = data['specialty'] ?? 'General'; // Provide default value
          _profileImageUrl = data['profileImageUrl'];
          _isOnline = data['isOnline'] ?? false;
          _qualifications = List<String>.from(data['qualifications'] ?? []);
          _languages = List<String>.from(data['languages'] ?? []);
          _services = List<String>.from(data['services'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _newProfileImage = File(image.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_newProfileImage == null) return;

    try {
      final ref = _storage.ref().child(
          'doctor_profiles/${_authService.currentUser?.uid}/profile.jpg');

      await ref.putFile(_newProfileImage!);
      final url = await ref.getDownloadURL();

      await _firestore
          .collection('doctors')
          .doc(_authService.currentUser?.uid)
          .update({'profileImageUrl': url});

      setState(() {
        _profileImageUrl = url;
        _newProfileImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  void _addQualification() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController qualificationController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Add Qualification'),
          content: TextField(
            controller: qualificationController,
            decoration: const InputDecoration(
              labelText: 'Qualification',
              hintText: 'e.g., MBBS, MD, MS',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (qualificationController.text.isNotEmpty) {
                  setState(() {
                    _qualifications.add(qualificationController.text);
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

  void _addLanguage() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController languageController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Add Language'),
          content: TextField(
            controller: languageController,
            decoration: const InputDecoration(
              labelText: 'Language',
              hintText: 'e.g., English, Spanish',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (languageController.text.isNotEmpty) {
                  setState(() {
                    _languages.add(languageController.text);
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

  void _addService() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController serviceController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Service'),
          content: TextField(
            controller: serviceController,
            decoration: const InputDecoration(
              labelText: 'Service',
              hintText: 'e.g., General Consultation, Surgery',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (serviceController.text.isNotEmpty) {
                  setState(() {
                    _services.add(serviceController.text);
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_newProfileImage != null) {
        await _uploadImage();
      }

      await _firestore
          .collection('doctors')
          .doc(_authService.currentUser?.uid)
          .update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'specialty': _selectedSpecialty,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'bio': _bioController.text,
        'consultationFee': int.tryParse(_consultationFeeController.text) ?? 0,
        'registrationNumber': _registrationNumberController.text,
        'qualifications': _qualifications,
        'languages': _languages,
        'services': _services,
        'isOnline': _isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
        title: const Text('Doctor Profile'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: _isEditing
                ? (value) {
                    setState(() => _isOnline = value);
                  }
                : null,
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isLoading
                ? null
                : () {
                    if (_isEditing) {
                      _updateProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _newProfileImage != null
                                ? FileImage(_newProfileImage!)
                                : _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                            child: _profileImageUrl == null &&
                                    _newProfileImage == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  color: Colors.white,
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Section
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSpecialty,
                      decoration: const InputDecoration(
                        labelText: 'Specialty',
                        border: OutlineInputBorder(),
                      ),
                      items: _specialties.map((specialty) {
                        return DropdownMenuItem(
                          value: specialty,
                          child: Text(specialty),
                        );
                      }).toList(),
                      onChanged: _isEditing
                          ? (value) {
                              setState(() =>
                                  _selectedSpecialty = value ?? 'General');
                            }
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your specialty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _registrationNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Registration Number',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your registration number';
                        }
                        return null;
                      },
                    ),

                    // Contact Information Section
                    const SizedBox(height: 24),
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),

                    // Professional Information Section
                    const SizedBox(height: 24),
                    const Text(
                      'Professional Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Years of Experience',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your years of experience';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _consultationFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Consultation Fee',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your consultation fee';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Professional Bio',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      maxLines: 4,
                    ),

                    // Qualifications Section
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Qualifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addQualification,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _qualifications.map((qualification) {
                        return Chip(
                          label: Text(qualification),
                          onDeleted: _isEditing
                              ? () {
                                  setState(() {
                                    _qualifications.remove(qualification);
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),

                    // Languages Section
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Languages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addLanguage,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languages.map((language) {
                        return Chip(
                          label: Text(language),
                          onDeleted: _isEditing
                              ? () {
                                  setState(() {
                                    _languages.remove(language);
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),

                    // Services Section
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addService,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _services.map((service) {
                        return Chip(
                          label: Text(service),
                          onDeleted: _isEditing
                              ? () {
                                  setState(() {
                                    _services.remove(service);
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _consultationFeeController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }
}
