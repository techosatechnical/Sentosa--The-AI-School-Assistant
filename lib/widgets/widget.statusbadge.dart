import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isThinking;
  final Color activeColor;

  const StatusBadge({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.isThinking = false,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Text(
        isSpeaking
            ? "SENTOSA SPEAKING — SAY 'HEY SENTOSA' TO INTERRUPT"
            : isThinking
            ? "PROCESSING..."
            : (isListening
                  ? "ACTIVE CONVERSATION (SPEAK NATURALLY)"
                  : "STANDBY — SAY 'HEY SENTOSA' OR TAP MIC"),
        style: TextStyle(
          color: activeColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
