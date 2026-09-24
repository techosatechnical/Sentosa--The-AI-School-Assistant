import 'dart:io';
import 'package:flutter/material.dart';
import 'admission_helpers.dart';

class AdmissionProfileDialog extends StatelessWidget {
  final Map<String, dynamic> student;
  final void Function(int idNum, String name) onDelete;
  final VoidCallback onClose;

  const AdmissionProfileDialog({
    super.key,
    required this.student,
    required this.onDelete,
    required this.onClose,
  });

  Widget _buildProfileInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = student['photoPath']?.toString();
    final hasPhoto = photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();

    final name = student['name']?.toString() ?? 'Unknown Student';
    final initials = AdmissionHelpers.getInitials(name);
    final id = student['id']?.toString() ?? '-';
    final idNum = student['id'] as int? ?? int.tryParse(id) ?? 0;
    final className = student['className']?.toString() ?? '-';
    final gender = student['gender']?.toString() ?? '-';
    final dob = student['dob']?.toString() ?? '-';
    final phone = student['phone']?.toString() ?? '-';
    final createdAt = student['createdAt'] != null
        ? DateTime.tryParse(student['createdAt'].toString())?.toString().split('.')[0] ??
            student['createdAt'].toString()
        : '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified, size: 14, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'Verified Admitted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDBEAFE),
                border: Border.all(color: const Color(0xFF93C5FD), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2942),
              ),
            ),
            Text(
              'Student ID: #STU-${id.padLeft(4, '0')}',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildProfileInfoRow('Class / Grade', className),
                  const Divider(height: 16, color: Color(0xFFE2E8F0)),
                  _buildProfileInfoRow('Gender', gender),
                  const Divider(height: 16, color: Color(0xFFE2E8F0)),
                  _buildProfileInfoRow('Date of Birth', dob),
                  const Divider(height: 16, color: Color(0xFFE2E8F0)),
                  _buildProfileInfoRow('Contact Phone', phone),
                  const Divider(height: 16, color: Color(0xFFE2E8F0)),
                  _buildProfileInfoRow('Registered At', createdAt),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      onClose();
                      onDelete(idNum, name);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
