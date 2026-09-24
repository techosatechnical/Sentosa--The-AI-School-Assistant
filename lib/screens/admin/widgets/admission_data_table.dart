import 'package:flutter/material.dart';
import 'admission_helpers.dart';

class AdmissionDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> filteredAdmissions;
  final int allCount;
  final Set<int> selectedIds;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final ValueChanged<bool?>? onSelectAll;
  final void Function(int idNum, bool? selected) onSelectRow;
  final void Function(Map<String, dynamic> admission) onShowProfile;
  final void Function(int idNum, String name) onDeleteSingle;
  final VoidCallback onDeselectAll;
  final VoidCallback onDeleteSelected;

  const AdmissionDataTable({
    super.key,
    required this.filteredAdmissions,
    required this.allCount,
    required this.selectedIds,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.onSelectAll,
    required this.onSelectRow,
    required this.onShowProfile,
    required this.onDeleteSingle,
    required this.onDeselectAll,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'ADMISSION DATA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (selectedIds.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          '${selectedIds.length} selected',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (selectedIds.isNotEmpty)
                  Row(
                    children: [
                      TextButton(
                        onPressed: onDeselectAll,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Deselect all',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: onDeleteSelected,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Delete (${selectedIds.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Table Content / Empty State
          Expanded(
            child: filteredAdmissions.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No admission records found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try changing your search query or reset active filters.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, outerConstraints) {
                      final tableMinWidth = outerConstraints.maxWidth;
                      return Scrollbar(
                        controller: verticalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: verticalScrollController,
                          scrollDirection: Axis.vertical,
                          child: Scrollbar(
                            controller: horizontalScrollController,
                            thumbVisibility: true,
                            notificationPredicate: (notif) => notif.depth == 1,
                            child: SingleChildScrollView(
                              controller: horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: tableMinWidth,
                                ),
                                child: DataTable(
                                  showCheckboxColumn: true,
                                  headingRowHeight: 38,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 52,
                                  horizontalMargin: 16,
                                  columnSpacing: 18,
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFF8FAFC),
                                  ),
                                  onSelectAll: onSelectAll,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'ID',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Student Name',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'DOB',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Gender',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Class',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Phone',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Admission Date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: filteredAdmissions.map((admission) {
                                    final idNum = admission['id'] as int? ?? 0;
                                    final isSelected = selectedIds.contains(idNum);
                                    final name = admission['name']?.toString() ?? '-';
                                    final initials = AdmissionHelpers.getInitials(name);
                                    final avatarColor = AdmissionHelpers.getAvatarColor(idNum);
                                    final gender = admission['gender']?.toString() ?? '-';
                                    final className = admission['className']?.toString() ?? '-';
                                    final phone = admission['phone']?.toString() ?? '-';
                                    final dob = admission['dob']?.toString() ?? '-';
                                    final createdAt = admission['createdAt'] != null
                                        ? DateTime.tryParse(admission['createdAt'].toString())
                                                ?.toString()
                                                .split('.')[0] ??
                                            '-'
                                        : '-';

                                    return DataRow(
                                      selected: isSelected,
                                      onSelectChanged: (bool? selected) => onSelectRow(idNum, selected),
                                      cells: [
                                        // ID
                                        DataCell(
                                          Text(
                                            '#${idNum.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        // Name with Avatar
                                        DataCell(
                                          InkWell(
                                            onTap: () => onShowProfile(admission),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 26,
                                                    height: 26,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: avatarColor.withValues(alpha: 0.15),
                                                      border: Border.all(
                                                        color: avatarColor.withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        initials,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: avatarColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // DOB
                                        DataCell(
                                          Text(
                                            dob,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        // Gender
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              gender,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Class
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFC7D2FE)),
                                            ),
                                            child: Text(
                                              className,
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4338CA),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Phone
                                        DataCell(
                                          Text(
                                            phone,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        // Created At
                                        DataCell(
                                          Text(
                                            createdAt,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontFamily: 'monospace',
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        // Actions
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 16,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                tooltip: 'View Profile',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 28,
                                                  minHeight: 28,
                                                ),
                                                onPressed: () => onShowProfile(admission),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: Color(0xFFDC2626),
                                                ),
                                                tooltip: 'Delete Record',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 28,
                                                  minHeight: 28,
                                                ),
                                                onPressed: () => onDeleteSingle(idNum, name),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredAdmissions.length} of $allCount entries${selectedIds.isNotEmpty ? ' • ${selectedIds.length} selected' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
