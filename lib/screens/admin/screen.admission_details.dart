import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/service.admission.dart';
import 'widgets/admission_nav_header.dart';
import 'widgets/admission_filter_card.dart';
import 'widgets/admission_data_table.dart';
import 'widgets/admission_profile_dialog.dart';
import 'widgets/admission_status_bar.dart';

class AdmissionDetailsScreen extends StatefulWidget {
  const AdmissionDetailsScreen({super.key});

  @override
  State<AdmissionDetailsScreen> createState() => _AdmissionDetailsScreenState();
}

class _AdmissionDetailsScreenState extends State<AdmissionDetailsScreen> {
  List<Map<String, dynamic>> _allAdmissions = [];
  List<Map<String, dynamic>> _filteredAdmissions = [];
  final Set<int> _selectedIds = {};

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  String _searchQuery = '';
  String? _selectedClass;
  String? _selectedGender;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await AdmissionDbService().getAllAdmissions();
    if (!mounted) return;
    setState(() {
      _allAdmissions = data;
      _isLoading = false;
      final validIds = data
          .map((e) => e['id'] as int?)
          .whereType<int>()
          .toSet();
      _selectedIds.retainAll(validIds);
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredAdmissions = _allAdmissions.where((admission) {
        final query = _searchQuery.toLowerCase().trim();
        final name = (admission['name'] ?? '').toString().toLowerCase();
        final id = (admission['id'] ?? '').toString().toLowerCase();
        final phone = (admission['phone'] ?? '').toString().toLowerCase();
        final matchesSearch =
            query.isEmpty ||
            name.contains(query) ||
            id.contains(query) ||
            phone.contains(query);

        final className = admission['className']?.toString() ?? '';
        final matchesClass =
            _selectedClass == null ||
            _selectedClass == 'All Classes' ||
            className == _selectedClass;

        final gender = admission['gender']?.toString() ?? '';
        final matchesGender =
            _selectedGender == null ||
            _selectedGender == 'All Genders' ||
            gender.toLowerCase() == _selectedGender!.toLowerCase();

        return matchesSearch && matchesClass && matchesGender;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedClass = null;
      _selectedGender = null;
      _applyFilters();
    });
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Records',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete $count selected admission record${count > 1 ? 's' : ''}? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Delete $count Record${count > 1 ? 's' : ''}'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final idsToDelete = _selectedIds.toList();
      await AdmissionDbService().deleteAdmissions(idsToDelete);
      _selectedIds.clear();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Deleted $count record${count > 1 ? 's' : ''} successfully.',
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteSingle(int id, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Record',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the admission record for "$studentName"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdmissionDbService().deleteAdmission(id);
      _selectedIds.remove(id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Deleted record for "$studentName".'),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exportCsv() {
    if (_filteredAdmissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records to export.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID,Name,DOB,Gender,Class,Phone,Admission Date');
    for (final row in _filteredAdmissions) {
      final id = row['id'] ?? '';
      final name = '"${(row['name'] ?? '').toString().replaceAll('"', '""')}"';
      final dob = row['dob'] ?? '';
      final gender = row['gender'] ?? '';
      final className = row['className'] ?? '';
      final phone = row['phone'] ?? '';
      final date = row['createdAt'] ?? '';
      buffer.writeln('$id,$name,$dob,$gender,$className,$phone,$date');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Exported ${_filteredAdmissions.length} records (CSV copied to clipboard)',
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStudentProfileDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AdmissionProfileDialog(
        student: student,
        onDelete: _confirmDeleteSingle,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classOptions = [
      'All Classes',
      ..._allAdmissions
          .map((e) => e['className']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet(),
    ];
    final genderOptions = ['All Genders', 'Male', 'Female'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Ambient backdrop mesh
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFBAE6FD).withValues(alpha: 0.4),
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
                      color: const Color(0xFFDBEAFE).withValues(alpha: 0.45),
                    ),
                  ),
                ),

                // Main Layout: Table stretches all the way to the bottom bar
                SafeArea(
                  child: Column(
                    children: [
                      AdmissionNavHeader(
                        allCount: _allAdmissions.length,
                        selectedCount: _selectedIds.length,
                        onBack: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        onDeleteSelected: _confirmDeleteSelected,
                        onExport: _exportCsv,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AdmissionFilterCard(
                                classOptions: classOptions,
                                genderOptions: genderOptions,
                                searchQuery: _searchQuery,
                                selectedClass: _selectedClass,
                                selectedGender: _selectedGender,
                                searchController: _searchController,
                                onSearchChanged: (val) {
                                  _searchQuery = val;
                                  _applyFilters();
                                },
                                onClearSearch: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _applyFilters();
                                },
                                onClassChanged: (val) {
                                  setState(() {
                                    _selectedClass = val;
                                    _applyFilters();
                                  });
                                },
                                onGenderChanged: (val) {
                                  setState(() {
                                    _selectedGender = val;
                                    _applyFilters();
                                  });
                                },
                                filteredCount: _filteredAdmissions.length,
                                onResetFilters: _resetFilters,
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: AdmissionDataTable(
                                  filteredAdmissions: _filteredAdmissions,
                                  allCount: _allAdmissions.length,
                                  selectedIds: _selectedIds,
                                  verticalScrollController: _verticalScrollController,
                                  horizontalScrollController: _horizontalScrollController,
                                  onSelectAll: (bool? isSelected) {
                                    setState(() {
                                      final allFilteredIds = _filteredAdmissions
                                          .map((e) => e['id'] as int?)
                                          .whereType<int>()
                                          .toSet();
                                      if (isSelected == true) {
                                        _selectedIds.addAll(allFilteredIds);
                                      } else {
                                        _selectedIds.removeAll(allFilteredIds);
                                      }
                                    });
                                  },
                                  onSelectRow: (idNum, selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedIds.add(idNum);
                                      } else {
                                        _selectedIds.remove(idNum);
                                      }
                                    });
                                  },
                                  onShowProfile: _showStudentProfileDialog,
                                  onDeleteSingle: _confirmDeleteSingle,
                                  onDeselectAll: () => setState(() => _selectedIds.clear()),
                                  onDeleteSelected: _confirmDeleteSelected,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const AdmissionStatusBar(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
