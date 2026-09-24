import 'package:flutter/material.dart';

class AdmissionHelpers {
  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'ST';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static Color getAvatarColor(int id) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF0D9488),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFFDB2777),
      const Color(0xFF059669),
    ];
    return colors[id % colors.length];
  }
}
