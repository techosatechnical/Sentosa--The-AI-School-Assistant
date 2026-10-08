import 'package:flutter/material.dart';
import 'package:sentosa/screens/security/screen.pin_entry.dart';
import 'package:sentosa/services/service.config.dart';
import 'widgets/change_pin_backdrop.dart';
import 'widgets/change_pin_top_nav.dart';
import 'widgets/change_pin_input_section.dart';
import 'widgets/change_pin_keypad.dart';
import 'package:sentosa/widgets/widget.toast.dart';

class ChangePinScreen extends StatefulWidget {
  final bool isAiPin;
  const ChangePinScreen({super.key, this.isAiPin = false});

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

    final config = ConfigService();
    if (widget.isAiPin) {
      if (_newPin == config.pin) {
        setState(() {
          _errorMessage = 'AI PIN cannot be identical to Admin PIN.';
          _newPin = '';
          _confirmPin = '';
          _activeStep = 1;
        });
        _showFeedbackSnackBar(_errorMessage!, isError: true);
        return;
      }
    } else {
      if (_newPin == config.aiPin) {
        setState(() {
          _errorMessage = 'Admin PIN cannot be identical to AI PIN.';
          _newPin = '';
          _confirmPin = '';
          _activeStep = 1;
        });
        _showFeedbackSnackBar(_errorMessage!, isError: true);
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final savedPin = widget.isAiPin ? config.aiPin : config.pin;
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

      if (widget.isAiPin) {
        await config.setAiPin(_newPin);
      } else {
        await config.setPin(_newPin);
      }

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
    SentosaToast.show(context: context, message: message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          const ChangePinBackdrop(),
          Column(
            children: [
              ChangePinTopNav(
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
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
                          ChangePinInputSection(
                            activeStep: _activeStep,
                            currentPin: _currentPin,
                            newPin: _newPin,
                            confirmPin: _confirmPin,
                            showCurrentPin: _showCurrentPin,
                            isSaving: _isSaving,
                            errorMessage: _errorMessage,
                            onStepChanged: (step) =>
                                setState(() => _activeStep = step),
                            onToggleShowPin: () => setState(
                              () => _showCurrentPin = !_showCurrentPin,
                            ),
                            onSavePin: _savePin,
                          ),
                          const SizedBox(height: 24),
                          ChangePinKeypad(
                            onClear: _onClear,
                            onBackspace: _onBackspace,
                            onInput: _onNumpadInput,
                          ),
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
