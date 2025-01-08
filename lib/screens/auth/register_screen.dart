import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _specialtyController = TextEditingController();

  String _selectedUserType = 'patient';
  String? _selectedSpecialty;
  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime? _dateOfBirth;
  bool _isLoading = false;

  // Lists for dropdowns
  final List<String> _specialties = [
    'Dermatologist',
    'Pediatrician',
    'Cardiologist',
    'Neurologist',
    'Psychiatrist',
    'Orthopedist',
    'General',
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _authService = AuthService();

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      if (_selectedUserType == 'patient' && (_dateOfBirth == null || _selectedGender == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final Map<String, dynamic> userData = {
          'name': _fullNameController.text.trim(),
          'userType': _selectedUserType,
        };

        // Add doctor specific fields
        if (_selectedUserType == 'doctor') {
          userData['specialty'] = _selectedSpecialty ?? 'General';
        }

        // Add patient specific fields
        if (_selectedUserType == 'patient') {
          userData.addAll({
            'dateOfBirth': _dateOfBirth,
            'gender': _selectedGender,
            'bloodGroup': _selectedBloodGroup,
          });
        }

        print(userData);

        await _authService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          userType: _selectedUserType,
          userData: userData,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // User Type Selection
              DropdownButtonFormField<String>(
                value: _selectedUserType,
                decoration: const InputDecoration(
                  labelText: 'User Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'patient', child: Text('Patient')),
                  DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                ],
                onChanged: (value) {
                  setState(() => _selectedUserType = value!);
                },
              ),
              const SizedBox(height: 16),

              // Doctor Specific Fields
              if (_selectedUserType == 'doctor') ...[
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
                  validator: (value) {
                    if (_selectedUserType == 'doctor' && value == null) {
                      return 'Please select your specialty';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() => _selectedSpecialty = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Patient Specific Fields
              if (_selectedUserType == 'patient') ...[
                // Date of Birth
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : 'Select Date of Birth',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender Selection
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: _genders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  validator: (value) {
                    if (_selectedUserType == 'patient' && value == null) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() => _selectedGender = value);
                  },
                ),
                const SizedBox(height: 16),

                // Blood Group Selection
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(),
                  ),
                  items: _bloodGroups.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBloodGroup = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Email and Password Fields
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
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
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register'),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }
}