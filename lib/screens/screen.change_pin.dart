import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/service.config.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({Key? key}) : super(key: key);

  @override
  _ChangePinScreenState createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final List<TextEditingController> _currentControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _currentFocus = List.generate(6, (_) => FocusNode());

  final List<TextEditingController> _newControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _newFocus = List.generate(6, (_) => FocusNode());

  final List<TextEditingController> _confirmControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _confirmFocus = List.generate(6, (_) => FocusNode());

  String _errorText = '';

  @override
  void dispose() {
    for (var c in _currentControllers) { c.dispose(); }
    for (var f in _currentFocus) { f.dispose(); }
    for (var c in _newControllers) { c.dispose(); }
    for (var f in _newFocus) { f.dispose(); }
    for (var c in _confirmControllers) { c.dispose(); }
    for (var f in _confirmFocus) { f.dispose(); }
    super.dispose();
  }

  void _onChanged(String value, int index, List<FocusNode> focusNodes, List<FocusNode>? nextRowFocus) {
    if (value.isNotEmpty) {
      if (index < 5) {
        focusNodes[index + 1].requestFocus();
      } else if (nextRowFocus != null) {
        nextRowFocus[0].requestFocus();
      } else {
        // Last box of confirm
        focusNodes[index].unfocus();
        _savePin();
      }
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _savePin() async {
    final currentPin = _currentControllers.map((c) => c.text).join();
    final newPin = _newControllers.map((c) => c.text).join();
    final confirmPin = _confirmControllers.map((c) => c.text).join();

    if (currentPin.length < 6 || newPin.length < 6 || confirmPin.length < 6) {
      setState(() => _errorText = 'All PIN fields must be 6 digits.');
      return;
    }

    if (newPin != confirmPin) {
      setState(() => _errorText = 'New PINs do not match.');
      return;
    }

    final savedPin = await ConfigService().getPin();
    if (currentPin != savedPin) {
      setState(() => _errorText = 'Current PIN is incorrect.');
      return;
    }

    await ConfigService().setPin(newPin);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN changed successfully!')),
    );
    Navigator.pop(context);
  }

  Widget _buildPinRow(String label, List<TextEditingController> controllers, List<FocusNode> focusNodes, List<FocusNode>? nextRowFocus, {bool autofocus = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 45,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                autofocus: autofocus && index == 0,
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 1,
                obscureText: true,
                obscuringCharacter: '•',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => _onChanged(value, index, focusNodes, nextRowFocus),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Change PIN', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBAE6FD).withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            top: 280,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCCFBF1).withValues(alpha: 0.35),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.password, size: 64, color: Colors.blueAccent),
                    const SizedBox(height: 24),
                    _buildPinRow('Current PIN', _currentControllers, _currentFocus, _newFocus, autofocus: true),
                    const SizedBox(height: 24),
                    _buildPinRow('New PIN', _newControllers, _newFocus, _confirmFocus),
                    const SizedBox(height: 24),
                    _buildPinRow('Confirm New PIN', _confirmControllers, _confirmFocus, null),
                    const SizedBox(height: 16),
                    if (_errorText.isNotEmpty)
                      Text(_errorText, style: const TextStyle(color: Colors.red, fontSize: 16)),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _savePin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Save PIN', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
