import 'package:flutter/painting.dart';

class ActionCardData {
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color hoverColor;
  final Color borderColor;
  final Color titleColor;
  final Color arrowColor;
  final Color accentDashColor;

  ActionCardData({
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.hoverColor,
    required this.borderColor,
    required this.titleColor,
    required this.arrowColor,
    required this.accentDashColor,
  });
}
