import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({Key? key}) : super(key: key);

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  String _selectedSpecialty = 'All';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _selectDoctor(Map<String, dynamic> doctor) async {
    try {


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor selected successfully')),
        );
        // Navigate to book appointment
        Navigator.pushNamed(
          context,
          '/patient/book-appointment',
          arguments: doctor,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting doctor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                List<String> specialties = ['All'];
                for (var doc in snapshot.data!.docs) {
                  final specialty = (doc.data() as Map<String, dynamic>)['specialty'] as String;
                  if (!specialties.contains(specialty)) {
                    specialties.add(specialty);
                  }
                }

                return DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: specialties.map((specialty) {
                    return DropdownMenuItem(
                      value: specialty,
                      child: Text(specialty),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialty = value!;
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var doctors = snapshot.data?.docs ?? [];

                // Filter by specialty
                if (_selectedSpecialty != 'All') {
                  doctors = doctors.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['specialty'] == _selectedSpecialty;
                  }).toList();
                }

                // Filter by search query
                if (_searchController.text.isNotEmpty) {
                  doctors = doctors.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['name']
                        .toString()
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());
                  }).toList();
                }

                if (doctors.isEmpty) {
                  return const Center(
                    child: Text('No doctors found'),
                  );
                }

                return ListView.builder(
                  itemCount: doctors.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final doctor = doctors[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text('Dr. ${doctor['name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Specialty: ${doctor['specialty']}'),
                            if (doctor['experience'] != null)
                              Text('Experience: ${doctor['experience']}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _selectDoctor(doctor),
                          child: const Text('Select'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}