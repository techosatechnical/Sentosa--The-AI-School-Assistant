import 'package:flutter/material.dart';

class ChangePinKeypad extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final ValueChanged<String> onInput;

  const ChangePinKeypad({
    super.key,
    required this.onClear,
    required this.onBackspace,
    required this.onInput,
  });

  Widget _buildKeypadButton({
    String? text,
    double fontSize = 18,
    bool isIcon = false,
    IconData? icon,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: isIcon
                ? Icon(icon, color: Colors.grey.shade700, size: 20)
                : Text(
                    text ?? '',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK TOUCH KEYPAD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                'Hardware keyboard ready',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              if (index == 9) {
                return _buildKeypadButton(
                  text: 'CLEAR',
                  fontSize: 12,
                  onTap: onClear,
                  backgroundColor: Colors.grey.shade100,
                );
              } else if (index == 11) {
                return _buildKeypadButton(
                  isIcon: true,
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                  backgroundColor: Colors.grey.shade100,
                );
              } else {
                final keyNumber = index == 10 ? '0' : '${index + 1}';
                return _buildKeypadButton(
                  text: keyNumber,
                  onTap: () => onInput(keyNumber),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
