import 'package:flutter/material.dart';
import '../services/service.admission.dart';

class AdmissionDetailsScreen extends StatefulWidget {
  const AdmissionDetailsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdmissionDetailsScreenState createState() => _AdmissionDetailsScreenState();
}

class _AdmissionDetailsScreenState extends State<AdmissionDetailsScreen> {
  List<Map<String, dynamic>> _allAdmissions = [];
  List<Map<String, dynamic>> _filteredAdmissions = [];
  
  String _searchQuery = '';
  String? _selectedClass;
  String? _selectedGender;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await AdmissionDbService().getAllAdmissions();
    if (!mounted) return;
    setState(() {
      _allAdmissions = data;
      _filteredAdmissions = data;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredAdmissions = _allAdmissions.where((admission) {
        final name = (admission['name'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(_searchQuery.toLowerCase());
        
        final matchesClass = _selectedClass == null || _selectedClass == 'All' || admission['className'] == _selectedClass;
        final matchesGender = _selectedGender == null || _selectedGender == 'All' || admission['gender'] == _selectedGender;
        
        return matchesSearch && matchesClass && matchesGender;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classOptions = ['All', ..._allAdmissions.map((e) => e['className']?.toString() ?? '').where((e) => e.isNotEmpty).toSet()];
    final genderOptions = ['All', 'Male', 'Female', 'Other'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admission Details', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBAE6FD).withValues(alpha: 0.45),
                  ),
                ),
              ),
              Positioned(
                top: 280,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by name...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Class',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            ),
                            initialValue: _selectedClass ?? 'All',
                            items: classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (value) {
                              _selectedClass = value;
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            ),
                            initialValue: _selectedGender ?? 'All',
                            items: genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (value) {
                              _selectedGender = value;
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _filteredAdmissions.isEmpty
                            ? const Center(child: Text("No records found.", style: TextStyle(color: Colors.grey, fontSize: 16)))
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2942)),
                                    columns: const [
                                      DataColumn(label: Text('ID')),
                                      DataColumn(label: Text('Name')),
                                      DataColumn(label: Text('DOB')),
                                      DataColumn(label: Text('Gender')),
                                      DataColumn(label: Text('Class')),
                                      DataColumn(label: Text('Phone')),
                                      DataColumn(label: Text('Date')),
                                    ],
                                    rows: _filteredAdmissions.map((admission) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(admission['id'].toString())),
                                          DataCell(Text(admission['name']?.toString() ?? '-')),
                                          DataCell(Text(admission['dob']?.toString() ?? '-')),
                                          DataCell(Text(admission['gender']?.toString() ?? '-')),
                                          DataCell(Text(admission['className']?.toString() ?? '-')),
                                          DataCell(Text(admission['phone']?.toString() ?? '-')),
                                          DataCell(Text(
                                            admission['createdAt'] != null 
                                              ? DateTime.parse(admission['createdAt']).toString().split('.')[0] 
                                              : '-'
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
