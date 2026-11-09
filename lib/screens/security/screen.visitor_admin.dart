import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nira/helpers/models/model.visitor.dart';
import 'package:nira/services/service.config.dart';
import 'package:nira/services/service.visitor.dart';
import 'package:nira/services/service.visitor_report.dart';
import 'package:nira/widgets/widget.toast.dart';
import 'package:nira/widgets/widget.touch_keyboard.dart';

class VisitorAdminScreen extends StatefulWidget {
  const VisitorAdminScreen({super.key});

  @override
  State<VisitorAdminScreen> createState() => _VisitorAdminScreenState();
}

class _VisitorAdminScreenState extends State<VisitorAdminScreen> {
  final ConfigService _config = ConfigService();

  int _selectedTab = 0; // 0: Daily Logs, 1: Email Recipients, 2: SMTP & Schedule
  List<String> _availableDates = [];
  String _selectedDate = VisitorService.formatDateKey(DateTime.now());
  List<VisitorRecord> _records = [];
  bool _isLoadingRecords = true;
  bool _isDispatching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? targetDate}) async {
    final dateToLoad = targetDate ?? _selectedDate;
    setState(() {
      _selectedDate = dateToLoad;
      _isLoadingRecords = true;
    });

    final dates = await VisitorService().getAvailableDates();
    final mergedDates = <String>{...dates, dateToLoad}.toList()
      ..sort((a, b) => b.compareTo(a));

    final records = await VisitorService().getVisitorsForDate(dateToLoad);
    if (!mounted) return;
    setState(() {
      _availableDates = mergedDates;
      _selectedDate = dateToLoad;
      _records = records;
      _isLoadingRecords = false;
    });
  }

  void _shiftSelectedDate(int deltaDays) {
    final parsed = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final nextDt = parsed.add(Duration(days: deltaDays));
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final nextDateOnly = DateTime(nextDt.year, nextDt.month, nextDt.day);
    if (nextDateOnly.isAfter(todayDateOnly)) return;
    final nextKey = VisitorService.formatDateKey(nextDateOnly);
    _loadData(targetDate: nextKey);
  }

  Future<void> _pickDateFromCalendar() async {
    final initial = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now,
      helpText: 'SELECT VISITOR LOG DATE',
    );
    if (picked != null && mounted) {
      final key = VisitorService.formatDateKey(picked);
      await _loadData(targetDate: key);
    }
  }

  String _formatDateLabel(String dateKey) {
    final todayKey = VisitorService.formatDateKey(DateTime.now());
    final yesterdayKey = VisitorService.formatDateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (dateKey == todayKey) return '$dateKey (Today)';
    if (dateKey == yesterdayKey) return '$dateKey (Yesterday)';
    return dateKey;
  }

  Future<void> _handleSendReportNow() async {
    if (_isDispatching) return;
    setState(() => _isDispatching = true);
    final (ok, msg) = await VisitorReportService().sendReportForDate(
      _selectedDate,
      isAutomated: false,
    );
    if (!mounted) return;
    setState(() => _isDispatching = false);
    SentosaToast.show(context: context, message: msg, isError: !ok);
  }

  void _showAddOrEditRecipientDialog({
    int? editIndex,
    EmailRecipient? existing,
  }) {
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final labelCtrl = TextEditingController(
      text: existing?.label ?? 'School Admin',
    );
    bool editingEmailField = true;
    String? validationError;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final activeCtrl = editingEmailField ? emailCtrl : labelCtrl;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                width: 760,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            editIndex != null
                                ? 'Edit Report Recipient'
                                : 'Add New Report Recipient',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F2942),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildModalField(
                              label: 'Recipient Email Address',
                              controller: emailCtrl,
                              placeholder:
                                  'e.g. principal@nirmalabhavanschool.org',
                              isFocused: editingEmailField,
                              icon: Icons.email_outlined,
                              onTap: () =>
                                  setModalState(() => editingEmailField = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildModalField(
                              label: 'Role / Label',
                              controller: labelCtrl,
                              placeholder: 'e.g. Principal Office',
                              isFocused: !editingEmailField,
                              icon: Icons.badge_outlined,
                              onTap: () => setModalState(
                                () => editingEmailField = false,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          validationError!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      KioskTouchKeyboard(
                        controller: activeCtrl,
                        isEmailMode: editingEmailField,
                        quickChips: editingEmailField
                            ? const [
                                '@gmail.com',
                                '@nirmalabhavanschool.org',
                                '.com',
                                '.org',
                                '.in',
                              ]
                            : const [
                                'Principal ',
                                'Vice Principal ',
                                'Admissions ',
                                'School Office',
                                'Manager',
                              ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final email = emailCtrl.text.trim();
                              final label = labelCtrl.text.trim().isEmpty
                                  ? 'School Admin'
                                  : labelCtrl.text.trim();
                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!emailRegex.hasMatch(email)) {
                                setModalState(() {
                                  validationError =
                                      'Please enter a valid email address (e.g. name@domain.com).';
                                });
                                return;
                              }
                              final newRec = EmailRecipient(
                                email: email,
                                label: label,
                                enabled: existing?.enabled ?? true,
                              );
                              if (editIndex != null) {
                                await _config.updateVisitorRecipient(
                                  editIndex,
                                  newRec,
                                );
                              } else {
                                await _config.addVisitorRecipient(newRec);
                              }
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();
                              if (mounted) {
                                setState(() {});
                                SentosaToast.show(
                                  context: context,
                                  message: editIndex != null
                                      ? 'Updated recipient $email'
                                      : 'Added recipient $email',
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              editIndex != null
                                  ? 'Save Changes'
                                  : 'Add Recipient',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
        );
      },
    ).then((_) {
      emailCtrl.dispose();
      labelCtrl.dispose();
    });
  }

  void _showSmtpFieldEditModal({
    required String title,
    required String initialValue,
    required bool isEmailMode,
    required ValueChanged<String> onSave,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: 760,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final data = await Clipboard.getData(
                                Clipboard.kTextPlain,
                              );
                              if (data?.text != null &&
                                  data!.text!.trim().isNotEmpty) {
                                ctrl.text = data.text!.trim();
                                ctrl.selection = TextSelection.collapsed(
                                  offset: ctrl.text.length,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Paste Clipboard',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildModalField(
                    label: title,
                    controller: ctrl,
                    placeholder: 'Enter value...',
                    isFocused: true,
                    icon: Icons.edit_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(height: 14),
                  KioskTouchKeyboard(
                    controller: ctrl,
                    isEmailMode: isEmailMode,
                    quickChips: isEmailMode
                        ? const [
                            'sentosa.aitechosa@gmail.com',
                            'nirmalabhavanschool@gmail.com',
                            'smtp.gmail.com',
                            '@gmail.com',
                            '465',
                            '587',
                          ]
                        : const [],
                    onSubmitted: () {
                      final val = ctrl.text.trim();
                      Navigator.of(ctx).pop();
                      onSave(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final val = ctrl.text.trim();
                          Navigator.of(ctx).pop();
                          onSave(val);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'Save Setting',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
    ).then((_) => ctrl.dispose());
  }

  Widget _buildModalField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool isFocused,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isFocused ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? const Color(0xFF0284C7)
                : const Color(0xFFCBD5E1),
            width: isFocused ? 2.2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isFocused
                  ? const Color(0xFF0284C7)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  TextField(
                    controller: controller,
                    onTap: onTap,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F2942),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                      hintText: placeholder,
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopNav(context),
            _buildTabSelector(),
            Expanded(
              child: _selectedTab == 0
                  ? _buildLogsTab()
                  : (_selectedTab == 1
                        ? _buildRecipientsTab()
                        : _buildScheduleAndSmtpTab()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visitor Token & Report Console',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2942),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Manage reception tokens, email recipients & automated end-of-day reports',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isDispatching ? null : _handleSendReportNow,
            icon: _isDispatching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _isDispatching ? 'Sending...' : 'Email Report Now',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = [
      (
        icon: Icons.confirmation_number_outlined,
        title: 'Daily Visitor Logs (${_records.length})',
      ),
      (
        icon: Icons.mark_email_read_outlined,
        title: 'Email Recipients (${_config.visitorRecipients.length})',
      ),
      (
        icon: Icons.schedule_send_outlined,
        title: 'Schedule & SMTP Settings',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isSel = _selectedTab == i;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedTab = i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF0F2942) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF0F2942)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        i == 0
                            ? Icons.confirmation_number_outlined
                            : (i == 1
                                  ? Icons.mark_email_read_outlined
                                  : Icons.schedule_send_outlined),
                        size: 18,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tabs[i].title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- TAB 0: DAILY VISITOR LOGS ---
  Widget _buildLogsTab() {
    final todayKey = VisitorService.formatDateKey(DateTime.now());
    final isToday = _selectedDate == todayKey;
    final dispatchStatus = VisitorReportService().getStatusForDate(
      _selectedDate,
    );
    final parentsCount = _records
        .where((r) => r.categoryId == 'parent')
        .length;
    final admissionsCount = _records
        .where((r) => r.categoryId == 'admission')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date filter controls + summary metrics
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Previous day button
              InkWell(
                onTap: () => _shiftSelectedDate(-1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: Color(0xFF0F2942),
                  ),
                ),
              ),

              // Dropdown of recent/recorded dates
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF0284C7),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _availableDates.contains(_selectedDate)
                            ? _selectedDate
                            : null,
                        items: _availableDates.map((d) {
                          return DropdownMenuItem<String>(
                            value: d,
                            child: Text(
                              _formatDateLabel(d),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F2942),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _loadData(targetDate: val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Next day button
              InkWell(
                onTap: isToday ? null : () => _shiftSelectedDate(1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFF1F5F9)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: isToday
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF0F2942),
                  ),
                ),
              ),

              // Calendar Picker Button
              OutlinedButton.icon(
                onPressed: _pickDateFromCalendar,
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: const Text(
                  'Pick Date',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (!isToday)
                ActionChip(
                  label: const Text(
                    'Jump to Today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  backgroundColor: const Color(0xFFE0F2FE),
                  side: const BorderSide(color: Color(0xFF7DD3FC)),
                  onPressed: () => _loadData(targetDate: todayKey),
                ),

              _buildStatBadge(
                'Total Tokens',
                '${_records.length}',
                const Color(0xFF0284C7),
                const Color(0xFFE0F2FE),
              ),
              _buildStatBadge(
                'Parents',
                '$parentsCount',
                const Color(0xFF059669),
                const Color(0xFFD1FAE5),
              ),
              _buildStatBadge(
                'Admissions',
                '$admissionsCount',
                const Color(0xFF7C3AED),
                const Color(0xFFEDE9FE),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (dispatchStatus?.sent == true)
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (dispatchStatus?.sent == true)
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 18,
                      color: (dispatchStatus?.sent == true)
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (dispatchStatus?.sent == true)
                          ? 'Report Emailed (${dispatchStatus!.visitorCount} records)'
                          : 'Daily Report @ ${_config.dailyReportTime}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: (dispatchStatus?.sent == true)
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _isLoadingRecords
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_busy_rounded,
                            size: 46,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No visitor tokens recorded on ${_formatDateLabel(_selectedDate)}.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Color(0xFFF1F5F9), height: 16),
                      itemBuilder: (context, index) {
                        final r = _records[_records.length - 1 - index];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    r.shortToken,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                  Text(
                                    r.formattedTime,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.visitorName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F2942),
                                    ),
                                  ),
                                  Text(
                                    'Phone: ${r.phoneNumber} • ${r.categoryLabel}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.purposeLabel,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'To Meet: ${r.personToMeet}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                r.studentSummary == 'N/A'
                                    ? '—'
                                    : 'Student: ${r.studentSummary}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(
    String label,
    String value,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: CONFIGURABLE EMAIL RECIPIENTS (ADD / EDIT / DELETE / TOGGLE) ---
  Widget _buildRecipientsTab() {
    final recipients = _config.visitorRecipients;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Visitor Report Email Recipients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F2942),
                      ),
                    ),
                    Text(
                      'Add, edit, enable/disable, or delete email addresses that receive the daily visitor report & CSV attachment.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditRecipientDialog(),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(
                  'Add Email Recipient',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: recipients.isEmpty
                  ? const Center(
                      child: Text(
                        'No email recipients configured. Tap "Add Email Recipient" above.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: recipients.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Color(0xFFF1F5F9), height: 14),
                      itemBuilder: (context, index) {
                        final r = recipients[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: r.enabled
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: r.enabled
                                  ? const Color(0xFFBAE6FD)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Switch(
                                value: r.enabled,
                                onChanged: (val) async {
                                  await _config.updateVisitorRecipient(
                                    index,
                                    r.copyWith(enabled: val),
                                  );
                                  setState(() {});
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.email,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: r.enabled
                                            ? const Color(0xFF0F2942)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      r.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                onPressed: () => _showAddOrEditRecipientDialog(
                                  editIndex: index,
                                  existing: r,
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 20),
                                tooltip: 'Edit Recipient',
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: () async {
                                  await _config.removeVisitorRecipient(index);
                                  if (!context.mounted) return;
                                  setState(() {});
                                  SentosaToast.show(
                                    context: context,
                                    message: 'Removed ${r.email}',
                                  );
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  foregroundColor: const Color(0xFFDC2626),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                tooltip: 'Delete Recipient',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: AUTOMATED SCHEDULE & SMTP SETTINGS ---
  Widget _buildScheduleAndSmtpTab() {
    const presetTimes = ['15:30', '16:00', '16:30', '17:00', '18:00'];
    final lastStatus = VisitorReportService().getStatusForDate(_selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastStatus?.lastError != null &&
              lastStatus!.lastError!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last Email Dispatch Error: ${lastStatus.lastError}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automated Daily Report Schedule & Audio Guidance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 12),
                _buildToggleRow(
                  title: 'Enable Automated End-of-Day Email Report',
                  subtitle:
                      'Automatically emails the day\'s visitor log at the scheduled time, before kiosk shutdown, or on next startup if offline.',
                  value: _config.autoDailyReportEnabled,
                  onChanged: (val) async {
                    await _config.setVisitorReportSettings(
                      autoDailyReportEnabled: val,
                    );
                    setState(() {});
                  },
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text(
                      'Daily Report Dispatch Time: ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2942),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: presetTimes.map((t) {
                          final sel = _config.dailyReportTime == t;
                          return ChoiceChip(
                            label: Text(
                              t,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFF0F2942),
                              ),
                            ),
                            selected: sel,
                            selectedColor: const Color(0xFF0284C7),
                            onSelected: (_) async {
                              await _config.setVisitorReportSettings(
                                dailyReportTime: t,
                              );
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildToggleRow(
                  title: 'Enable Predefined Spoken Audio Prompts & Chimes',
                  subtitle:
                      'Plays clear voice guidance and gentle step chimes during Visitor Check-In.',
                  value: _config.visitorAudioPromptsEnabled,
                  onChanged: (val) async {
                    await _config.setVisitorReportSettings(
                      visitorAudioPromptsEnabled: val,
                    );
                    VisitorService().setMuted(!val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMTP Outgoing Mail Server Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use a Gmail / Google Workspace App Password for reliable automated email delivery.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildConfigTile(
                        label: 'SMTP Host',
                        value: _config.smtpHost,
                        icon: Icons.dns_outlined,
                        onTap: () => _showSmtpFieldEditModal(
                          title: 'Edit SMTP Host',
                          initialValue: _config.smtpHost,
                          isEmailMode: true,
                          onSave: (val) async {
                            await _config.setVisitorReportSettings(
                              smtpHost: val,
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildConfigTile(
                        label: 'SMTP Port (587 STARTTLS / 465 SSL)',
                        value: '${_config.smtpPort}',
                        icon: Icons.settings_ethernet_rounded,
                        onTap: () => _showSmtpFieldEditModal(
                          title: 'Edit SMTP Port',
                          initialValue: '${_config.smtpPort}',
                          isEmailMode: true,
                          onSave: (val) async {
                            final parsed = int.tryParse(val) ?? 587;
                            await _config.setVisitorReportSettings(
                              smtpPort: parsed,
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildConfigTile(
                        label: 'Sender Email Account',
                        value: _config.smtpSenderEmail,
                        icon: Icons.alternate_email_rounded,
                        onTap: () => _showSmtpFieldEditModal(
                          title: 'Edit Sender Email',
                          initialValue: _config.smtpSenderEmail,
                          isEmailMode: true,
                          onSave: (val) async {
                            await _config.setVisitorReportSettings(
                              smtpSenderEmail: val,
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildConfigTile(
                        label: 'SMTP App Password',
                        value: _config.smtpPassword.isEmpty
                            ? 'Not Configured (Tap to Set)'
                            : '•••••••••••••••• (Configured)',
                        icon: Icons.key_rounded,
                        onTap: () => _showSmtpFieldEditModal(
                          title: 'Edit SMTP App Password',
                          initialValue: _config.smtpPassword,
                          isEmailMode: true,
                          onSave: (val) async {
                            await _config.setVisitorReportSettings(
                              smtpPassword: val.replaceAll(' ', ''),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildConfigTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0284C7), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}
