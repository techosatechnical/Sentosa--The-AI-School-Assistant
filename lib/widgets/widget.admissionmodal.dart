import 'dart:ui';
import 'package:flutter/material.dart';

class AdmissionModal extends StatelessWidget {
  final VoidCallback onClose;

  const AdmissionModal({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent backdrop taps inside card from closing
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                          blurRadius: 50,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Modal Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: Color(0xFFFBBF24),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Admission Procedure",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 22,
                              ),
                              onPressed: onClose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        const Text(
                          "Welcome to Sentosa International Academy! Follow these steps to begin your enrollment journey:",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFCBD5E1),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Vertical Step Cards List (Scrollable)
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: const [
                                AdmissionStepCard(
                                  stepNumber: "1",
                                  title: "Application Submission",
                                  desc: "Submit online at sentosa.edu/admissions or collect physical application forms at Reception.",
                                  icon: Icons.description_outlined,
                                ),
                                SizedBox(height: 10),
                                AdmissionStepCard(
                                  stepNumber: "2",
                                  title: "Document Verification",
                                  desc: "Provide birth certificate, past 2 years of report cards, and vaccine/immunization records.",
                                  icon: Icons.folder_shared_outlined,
                                ),
                                SizedBox(height: 10),
                                AdmissionStepCard(
                                  stepNumber: "3",
                                  title: "Assessment & Interview",
                                  desc: "Student completes a baseline placement evaluation followed by a family interaction.",
                                  icon: Icons.edit_note_rounded,
                                ),
                                SizedBox(height: 10),
                                AdmissionStepCard(
                                  stepNumber: "4",
                                  title: "Enrollment Offer",
                                  desc: "Receive official offer letter within 3–5 business days upon assessment review.",
                                  icon: Icons.verified_outlined,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Office Location Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFF38BDF8),
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Office: Ground Floor, Admin Wing. Head of Admissions: Mr. Arthur Pendleton.",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF94A3B8),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Got It Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: onClose,
                            child: const Text(
                              "Got It",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step card inside the admission procedure modal.
class AdmissionStepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String desc;
  final IconData icon;

  const AdmissionStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: const Color(0xFFFBBF24), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$stepNumber. $title",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.35,
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
