import 'package:flutter/material.dart';
import 'package:nira/services/service.visitor.dart';

class KioskNumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final double maxWidth;

  const KioskNumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
    required this.onClear,
    this.maxWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'CLR',
      '0',
      'DEL',
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final k = keys[index];
          if (k == 'CLR') {
            return _buildButton(
              label: 'Clear',
              icon: Icons.refresh_rounded,
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              textColor: const Color(0xFFDC2626),
              onTap: () {
                VisitorService().playChime(ChimeType.tap);
                onClear();
              },
            );
          }
          if (k == 'DEL') {
            return _buildButton(
              label: 'Delete',
              icon: Icons.backspace_outlined,
              bgColor: const Color(0xFFF1F5F9),
              borderColor: const Color(0xFFCBD5E1),
              textColor: const Color(0xFF334155),
              onTap: () {
                VisitorService().playChime(ChimeType.tap);
                onBackspace();
              },
            );
          }
          return _buildButton(
            text: k,
            bgColor: Colors.white,
            borderColor: const Color(0xFFBAE6FD),
            textColor: const Color(0xFF0F2942),
            onTap: () {
              VisitorService().playChime(ChimeType.tap);
              onDigitPressed(k);
            },
          );
        },
      ),
    );
  }

  Widget _buildButton({
    String? text,
    String? label,
    IconData? icon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2942).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: textColor),
                      if (label != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    text ?? '',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class KioskTouchKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final List<String> quickChips;
  final bool isEmailMode;
  final VoidCallback? onSubmitted;

  const KioskTouchKeyboard({
    super.key,
    required this.controller,
    this.quickChips = const ['Mr. ', 'Mrs. ', 'Ms. ', 'Dr. ', 'Sr. '],
    this.isEmailMode = false,
    this.onSubmitted,
  });

  @override
  State<KioskTouchKeyboard> createState() => _KioskTouchKeyboardState();
}

class _KioskTouchKeyboardState extends State<KioskTouchKeyboard> {
  bool _isShift = true;

  @override
  void initState() {
    super.initState();
    _isShift = !widget.isEmailMode && widget.controller.text.isEmpty;
  }

  void _insertText(String value) {
    VisitorService().playChime(ChimeType.tap);
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, value);
    final newOffset = start + value.length;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );

    if (!widget.isEmailMode) {
      setState(() {
        _isShift = newText.isEmpty || newText.endsWith(' ') || newText.endsWith('.');
      });
    }
  }

  void _backspace() {
    VisitorService().playChime(ChimeType.tap);
    final text = widget.controller.text;
    if (text.isEmpty) return;

    final selection = widget.controller.selection;
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;

    if (start != end) {
      final newText = text.replaceRange(start, end, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }

    if (!widget.isEmailMode) {
      final updated = widget.controller.text;
      setState(() {
        _isShift = updated.isEmpty || updated.endsWith(' ');
      });
    }
  }

  void _clear() {
    VisitorService().playChime(ChimeType.tap);
    widget.controller.clear();
    if (!widget.isEmailMode) {
      setState(() => _isShift = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row0 = widget.isEmailMode
        ? const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
        : const <String>[];
    const row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
    const row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
    const row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.quickChips.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.quickChips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        chip,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      backgroundColor: const Color(0xFFE0F2FE),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      onPressed: () => _insertText(chip),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (row0.isNotEmpty) ...[
            _buildKeyRow(row0),
            const SizedBox(height: 8),
          ],
          _buildKeyRow(row1),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _buildKeyRow(row2),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildActionKey(
                flex: 14,
                icon: _isShift
                    ? Icons.keyboard_capslock_rounded
                    : Icons.arrow_upward_rounded,
                label: 'Shift',
                bgColor: _isShift
                    ? const Color(0xFF0284C7)
                    : const Color(0xFFE2E8F0),
                textColor: _isShift ? Colors.white : const Color(0xFF334155),
                onTap: () => setState(() => _isShift = !_isShift),
              ),
              const SizedBox(width: 6),
              ...row3.map(
                (k) => Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildCharKey(k),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildActionKey(
                flex: 16,
                icon: Icons.backspace_outlined,
                label: 'Del',
                bgColor: const Color(0xFFFEE2E2),
                textColor: const Color(0xFFDC2626),
                onTap: _backspace,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildActionKey(
                flex: 16,
                icon: Icons.clear_all_rounded,
                label: 'Clear',
                bgColor: const Color(0xFFF1F5F9),
                textColor: const Color(0xFF475569),
                onTap: _clear,
              ),
              const SizedBox(width: 8),
              if (widget.isEmailMode) ...[
                _buildSpecialCharKey('@', flex: 12),
                const SizedBox(width: 6),
                _buildSpecialCharKey('.', flex: 10),
                const SizedBox(width: 6),
                _buildSpecialCharKey('_', flex: 10),
                const SizedBox(width: 6),
                _buildSpecialCharKey('-', flex: 10),
                const SizedBox(width: 8),
              ] else ...[
                _buildSpecialCharKey('.', flex: 10),
                const SizedBox(width: 8),
              ],
              _buildActionKey(
                flex: widget.isEmailMode ? 28 : 48,
                icon: Icons.space_bar_rounded,
                label: 'SPACE',
                bgColor: Colors.white,
                textColor: const Color(0xFF0F2942),
                onTap: () => _insertText(' '),
              ),
              if (widget.onSubmitted != null) ...[
                const SizedBox(width: 8),
                _buildActionKey(
                  flex: 20,
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Done',
                  bgColor: const Color(0xFF0284C7),
                  textColor: Colors.white,
                  onTap: widget.onSubmitted!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys.map((k) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _buildCharKey(k),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCharKey(String rawChar) {
    final display = _isShift ? rawChar.toUpperCase() : rawChar.toLowerCase();
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _insertText(display),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            alignment: Alignment.center,
            child: Text(
              display,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F2942),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialCharKey(String ch, {int flex = 10}) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: 48,
        child: Material(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _insertText(ch),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7DD3FC)),
              ),
              alignment: Alignment.center,
              child: Text(
                ch,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0369A1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required int flex,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: 48,
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

