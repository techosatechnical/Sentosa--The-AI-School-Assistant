import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:sentosa/screens/admin/screen.accessibility_menu.dart';
import 'package:sentosa/screens/security/screen.change_pin.dart';
import 'package:sentosa/screens/security/screen.ai_config.dart';
import 'package:sentosa/services/service.config.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  final int _pinLength = 6;
  bool _hasError = false;
  final String _errorMessage = 'Incorrect PIN. Please try again.';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += value;
        _hasError = false;
      });
      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  void _navigateToAccessibilityMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AccessibilityMenuScreen()),
    );
  }

  Future<void> _verifyPin() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final config = ConfigService();
    final correctPin = config.pin;
    final aiPin = config.aiPin;

    if (_pin == correctPin) {
      _navigateToAccessibilityMenu();
    } else if (_pin == aiPin) {
      _navigateToAiConfig();
    } else if (_pin == '999999') {
      _showKioskExitDialog();
    } else {
      setState(() {
        _hasError = true;
        _pin = '';
      });
      _shakeController.forward(from: 0.0);
    }
  }

  void _navigateToAiConfig() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AiConfigScreen()),
    );
  }

  void _showKioskExitDialog() {
    setState(() {
      _pin = '';
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.power_settings_new_rounded,
                      color: Color(0xFFF59E0B),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Exit Kiosk Mode",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Are you sure you want to exit Sentosa and launch Windows Explorer?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Go Back",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            Process.runSync('powershell', [
                              '-Command',
                              "Start-Process reg -ArgumentList 'add', '\"HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\"', '/v', 'Shell', '/t', 'REG_SZ', '/d', 'explorer.exe', '/f', '/reg:64' -Verb RunAs -Wait -WindowStyle Hidden",
                            ]);
                            await Process.start('shutdown', ['/l']);
                            exit(0);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Exit",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSlots() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = _hasError
            ? (10 *
                  (1 - _shakeController.value) *
                  (math.sin(_shakeController.value * 4 * math.pi)))
            : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              final isFilled = index < _pin.length;
              final isActive = index == _pin.length;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 44,
                height: 56,
                decoration: BoxDecoration(
                  color: isFilled || isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? Colors.blue.shade500
                        : (isFilled
                              ? Colors.blue.shade300
                              : Colors.grey.shade300),
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.blue.shade500.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: isFilled
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                          ),
                        )
                      : (isActive
                            ? Container(
                                width: 2,
                                height: 24,
                                color: Colors.blue.shade500,
                              )
                            : null),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildKeypad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          if (index == 9) {
            return _buildKeypadButton(
              isIcon: true,
              icon: Icons.clear_all_rounded,
              label: 'Clear',
              onTap: () {
                setState(() {
                  _pin = '';
                  _hasError = false;
                });
              },
              backgroundColor: Colors.blue.shade50.withValues(alpha: 0.8),
              textColor: Colors.blue.shade700,
            );
          } else if (index == 11) {
            return _buildKeypadButton(
              isIcon: true,
              icon: Icons.backspace_outlined,
              onTap: _onBackspace,
              backgroundColor: Colors.grey.shade100.withValues(alpha: 0.8),
              textColor: Colors.grey.shade700,
            );
          } else {
            final keyNumber = index == 10 ? '0' : '${index + 1}';
            final letters = [
              '',
              'ABC',
              'DEF',
              'GHI',
              'JKL',
              'MNO',
              'PQRS',
              'TUV',
              'WXYZ',
              '',
              '+',
              '',
            ];
            return _buildKeypadButton(
              text: keyNumber,
              label: letters[index],
              onTap: () => _onKeyPressed(keyNumber),
            );
          }
        },
      ),
    );
  }

  Widget _buildKeypadButton({
    String? text,
    String? label,
    bool isIcon = false,
    IconData? icon,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isIcon && icon != null)
                Icon(icon, color: textColor ?? Colors.grey.shade800, size: 24)
              else
                Text(
                  text ?? '',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.grey.shade800,
                    height: 1.0,
                  ),
                ),
              if (label != null && label.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: textColor ?? Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.5,
            colors: [
              Colors.lightBlue.shade50.withValues(alpha: 0.7),
              Colors.blue.shade50.withValues(alpha: 0.3),
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildTopNav(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.lightBlue.shade100,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade200.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              size: 36,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Enter PIN',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'Enter your 6-digit security PIN to access the Sentosa enterprise console.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 24,
                            child: _hasError
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _errorMessage,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 8),
                          _buildPinSlots(),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ChangePinScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.lock_reset,
                              size: 14,
                              color: Colors.blue.shade500,
                            ),
                            label: Text(
                              'Change or Reset PIN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildKeypad(),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Secured with Sentosa 2.0',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sentosa Desktop Runtime • Windows Mode',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
