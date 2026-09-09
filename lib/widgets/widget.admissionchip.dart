import 'package:flutter/material.dart';

class AdmissionChip extends StatelessWidget {
  final VoidCallback onTap;

  const AdmissionChip({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF59E0B).withValues(alpha: 0.25),
              const Color(0xFFD97706).withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
          ),
        ),
        child: const Text(
          "🎓 Admission Procedure",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFFDE68A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
