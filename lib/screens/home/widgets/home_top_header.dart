import 'package:flutter/material.dart';

class HomeTopHeader extends StatelessWidget {
  final DateTime currentTime;

  const HomeTopHeader({super.key, required this.currentTime});

  @override
  Widget build(BuildContext context) {
    final hour = currentTime.hour % 12 == 0 ? 12 : currentTime.hour % 12;
    final minute = currentTime.minute.toString().padLeft(2, '0');
    final period = currentTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "$hour:$minute $period";

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        "${weekdays[currentTime.weekday - 1]}, ${currentTime.day} ${months[currentTime.month - 1]} ${currentTime.year}";

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 14, 32, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/images/app-icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sentosa",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.6,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Your School Assistant",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F2942).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F2942).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(width: 1.5, height: 28, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2942).withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_done_rounded,
                      size: 15,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6EE7B7),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Cloud Connected",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
