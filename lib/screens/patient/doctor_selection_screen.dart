import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({Key? key}) : super(key: key);

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedSpecialty = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Doctor'),
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
              stream: _firestore.collection('doctors').get().asStream(),
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
          const SizedBox(height: 16),
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
                        subtitle: Text(doctor['specialty']),
                        onTap: () {
                          // Return selected doctor to previous screen
                          Navigator.pop(context, doctor);
                        },
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