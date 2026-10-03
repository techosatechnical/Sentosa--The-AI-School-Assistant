import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sentosa/services/service.config.dart';
import 'package:sentosa/widgets/widget.toast.dart';

class SystemInstructionScreen extends StatefulWidget {
  const SystemInstructionScreen({super.key});

  @override
  State<SystemInstructionScreen> createState() =>
      _SystemInstructionScreenState();
}

class _SystemInstructionScreenState extends State<SystemInstructionScreen> {
  final ConfigService _config = ConfigService();
  late TextEditingController _instructionController;
  late String _currentInstruction;
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentInstruction = _config.systemInstruction;
    _instructionController = TextEditingController(text: _currentInstruction);
    _instructionController.addListener(() {
      final changed = _instructionController.text != _currentInstruction;
      if (changed != _hasChanges) {
        setState(() {
          _hasChanges = changed;
        });
      }
    });
  }

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _commitInstructions() async {
    final updatedText = _instructionController.text.trim();
    if (updatedText.isEmpty) {
      SentosaToast.show(
        context: context,
        message: 'System instructions cannot be empty.',
        isError: true,
      );
      return;
    }

    await _config.setAiConfig(
      voice: _config.voice,
      model: _config.model,
      systemInstruction: updatedText,
    );

    setState(() {
      _currentInstruction = updatedText;
      _isEditing = false;
      _hasChanges = false;
    });

    if (mounted) {
      SentosaToast.show(
        context: context,
        message: 'System instructions committed successfully!',
        isError: false,
      );
    }
  }

  Widget _buildTopNav(BuildContext context) {
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
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
          Row(
            children: [
              if (!_isEditing)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text(
                    'Edit Prompt',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else ...[
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _instructionController.text = _currentInstruction;
                      _isEditing = false;
                      _hasChanges = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _commitInstructions,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Commit Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background ambient circles matching accessibility menu
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
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNav(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            "System Instructions",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F2942),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isEditing
                            ? "Modify the active persona and prompt directives. Click 'Commit Changes' to apply."
                            : "Locked Markdown preview of the active Gemini agent system instructions.",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isEditing
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFFE2E8F0),
                          width: _isEditing ? 2.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2942).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _isEditing
                            ? TextField(
                                controller: _instructionController,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xFF1E293B),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(20),
                                  hintText: 'Enter AI system instruction markdown...',
                                ),
                              )
                            : Markdown(
                                data: _currentInstruction,
                                selectable: true,
                                padding: const EdgeInsets.all(20),
                              ),
                      ),
                    ),
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
