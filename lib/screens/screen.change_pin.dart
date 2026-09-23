import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sentosa/screens/screen.pin_entry.dart';
import 'package:sentosa/services/service.config.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  int _activeStep = 0;
  bool _showCurrentPin = false;
  bool _isSaving = false;
  String? _errorMessage;

  void _onNumpadInput(String digit) {
    setState(() {
      _errorMessage = null;
      if (_activeStep == 0) {
        if (_currentPin.length < 6) _currentPin += digit;
        if (_currentPin.length == 6) _activeStep = 1;
      } else if (_activeStep == 1) {
        if (_newPin.length < 6) _newPin += digit;
        if (_newPin.length == 6) _activeStep = 2;
      } else if (_activeStep == 2) {
        if (_confirmPin.length < 6) _confirmPin += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      if (_activeStep == 0) {
        if (_currentPin.isNotEmpty) {
          _currentPin = _currentPin.substring(0, _currentPin.length - 1);
        }
      } else if (_activeStep == 1) {
        if (_newPin.isNotEmpty) {
          _newPin = _newPin.substring(0, _newPin.length - 1);
        } else {
          _activeStep = 0;
          if (_currentPin.isNotEmpty) {
            _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          }
        }
      } else if (_activeStep == 2) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _activeStep = 1;
          if (_newPin.isNotEmpty) {
            _newPin = _newPin.substring(0, _newPin.length - 1);
          }
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      _errorMessage = null;
      _newPin = '';
      _confirmPin = '';
      _activeStep = 1;
    });
  }

  Future<void> _savePin() async {
    setState(() {
      _errorMessage = null;
    });

    if (_currentPin.length < 6) {
      setState(() {
        _errorMessage = 'Please enter your 6-digit current PIN.';
        _activeStep = 0;
      });
      _showFeedbackSnackBar(_errorMessage!, isError: true);
      return;
    }

    if (_newPin.length < 6) {
      setState(() {
        _errorMessage = 'New PIN must be 6 digits.';
        _activeStep = 1;
      });
      _showFeedbackSnackBar(_errorMessage!, isError: true);
      return;
    }

    if (_confirmPin.length < 6) {
      setState(() {
        _errorMessage = 'Please confirm your 6-digit new PIN.';
        _activeStep = 2;
      });
      _showFeedbackSnackBar(_errorMessage!, isError: true);
      return;
    }

    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = 'New PIN and Confirm PIN do not match.';
        _confirmPin = '';
        _activeStep = 2;
      });
      _showFeedbackSnackBar(_errorMessage!, isError: true);
      return;
    }

    if (_currentPin == _newPin) {
      setState(() {
        _errorMessage = 'New PIN cannot be the same as current PIN.';
        _newPin = '';
        _confirmPin = '';
        _activeStep = 1;
      });
      _showFeedbackSnackBar(_errorMessage!, isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final savedPin = await ConfigService().getPin();
      if (_currentPin != savedPin) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Current PIN is incorrect. Please try again.';
          _currentPin = '';
          _activeStep = 0;
          _isSaving = false;
        });
        _showFeedbackSnackBar(_errorMessage!, isError: true);
        return;
      }

      await ConfigService().setPin(_newPin);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      _showFeedbackSnackBar('PIN successfully changed!', isError: false);

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PinEntryScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save PIN: $e';
        _isSaving = false;
      });
      _showFeedbackSnackBar(_errorMessage!, isError: true);
    }
  }

  void _showFeedbackSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAmbientBackdrop() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade200.withValues(alpha: 0.4),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -150,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan.shade100.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          top: 300,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100.withValues(alpha: 0.6),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: 50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo.shade50.withValues(alpha: 0.7),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
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

  Widget _buildPinRow({
    required String value,
    required bool isActive,
    required bool obscureText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final isFilled = index < value.length;
        final isCurrent = isActive && index == value.length;

        return Container(
          width: 40,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent
                  ? Colors.blue.shade500
                  : (isActive ? Colors.blue.shade100 : Colors.grey.shade300),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.blue.shade100,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isFilled
                ? (obscureText
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                        )
                      : Text(
                          value[index],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ))
                : (isCurrent
                      ? Text(
                          '•',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade400,
                          ),
                        )
                      : null),
          ),
        );
      }),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current PIN
          GestureDetector(
            onTap: () => setState(() => _activeStep = 0),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Current PIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showCurrentPin = !_showCurrentPin;
                          });
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _showCurrentPin ? 'Hide' : 'Show',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPinRow(
                    value: _currentPin,
                    isActive: _activeStep == 0,
                    obscureText: !_showCurrentPin,
                  ),                
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.black12, height: 1),
          ),
          GestureDetector(
            onTap: () => setState(() => _activeStep = 1),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'New PIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Must be 6 digits',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPinRow(
                    value: _newPin,
                    isActive: _activeStep == 1,
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.black12, height: 1),
          ),
          // Confirm PIN
          GestureDetector(
            onTap: () => setState(() => _activeStep = 2),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '3',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Confirm New PIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _confirmPin.length == 6
                            ? (_confirmPin == _newPin
                                  ? 'Matches'
                                  : 'Does not match')
                            : 'Re-enter 6 digits',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _confirmPin.length == 6
                              ? (_confirmPin == _newPin
                                    ? Colors.green
                                    : Colors.red)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPinRow(
                    value: _confirmPin,
                    isActive: _activeStep == 2,
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePin,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward, size: 18),
              label: Text(
                _isSaving ? 'Saving PIN...' : 'Save PIN',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.blue.shade500.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
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
                  onTap: _onClear,
                  backgroundColor: Colors.grey.shade100,
                );
              } else if (index == 11) {
                return _buildKeypadButton(
                  isIcon: true,
                  icon: Icons.backspace_outlined,
                  onTap: _onBackspace,
                  backgroundColor: Colors.grey.shade100,
                );
              } else {
                final keyNumber = index == 10 ? '0' : '${index + 1}';
                return _buildKeypadButton(
                  text: keyNumber,
                  onTap: () => _onNumpadInput(keyNumber),
                );
              }
            },
          ),
        ],
      ),
    );
  }

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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          _buildAmbientBackdrop(),
          Column(
            children: [
              _buildTopNav(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          _buildInputSection(),
                          const SizedBox(height: 24),
                          _buildKeypad(),
                          const SizedBox(height: 24),
                          Text(
                            'Sentosa Windows Client • Terminal ID #8841-A • TLS 1.3 Encrypted',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
