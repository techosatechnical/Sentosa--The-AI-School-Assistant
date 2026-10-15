import 'package:flutter/material.dart';
import 'package:nira/services/services.dart';

class DiagnosticLogsScreen extends StatefulWidget {
  const DiagnosticLogsScreen({super.key});

  @override
  State<DiagnosticLogsScreen> createState() => _DiagnosticLogsScreenState();
}

class _DiagnosticLogsScreenState extends State<DiagnosticLogsScreen> {
  final DiagnosticLogger _logger = DiagnosticLogger();
  List<DiagnosticLogEntry> _logs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _logger.readLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Clear Diagnostic Logs?",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F2942),
          ),
        ),
        content: const Text(
          "This will erase all saved telemetry and diagnostic logs from local storage.",
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logger.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Diagnostic logs cleared successfully."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<DiagnosticLogEntry> get _filteredLogs {
    if (_selectedFilter == 'Errors') {
      return _logs.where((l) => l.type == LogType.error).toList();
    } else if (_selectedFilter == 'Warnings') {
      return _logs.where((l) => l.type == LogType.warning).toList();
    } else if (_selectedFilter == 'WebSockets') {
      return _logs
          .where(
            (l) =>
                l.event.contains('WEBSOCKET') ||
                l.event.contains('SOCKET') ||
                l.event.contains('SESSION'),
          )
          .toList();
    }
    return _logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0F2FE).withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.4),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNav(context),
                _buildHeaderSection(),
                _buildFilterChips(),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredLogs.isEmpty
                      ? _buildEmptyState()
                      : _buildLogsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
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
          ),
          Row(
            children: [
              IconButton(
                onPressed: _loadLogs,
                tooltip: "Refresh Logs",
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF0284C7),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFE0F2FE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearLogs,
                tooltip: "Clear Logs",
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFEF4444),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final errorCount = _logs.where((l) => l.type == LogType.error).length;
    final warnCount = _logs.where((l) => l.type == LogType.warning).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFD97706),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Diagnostic Logs",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F2942),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Persistent local telemetry & connection diagnostics",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2942).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  "Total Events",
                  "${_logs.length}",
                  const Color(0xFF0284C7),
                ),
                Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                _buildStatItem(
                  "Errors",
                  "$errorCount",
                  const Color(0xFFEF4444),
                ),
                Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                _buildStatItem(
                  "Warnings",
                  "$warnCount",
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Errors', 'Warnings', 'WebSockets'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFilter = filter),
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0F2FE),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Diagnostic Logs Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F2942),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Events, connection status, and API telemetry will automatically appear here as the assistant runs.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    final logs = _filteredLogs;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log, isLatest: index == 0);
      },
    );
  }

  Widget _buildLogCard(DiagnosticLogEntry log, {required bool isLatest}) {
    Color badgeBg;
    Color badgeColor;
    IconData iconData;

    switch (log.type) {
      case LogType.error:
        badgeBg = const Color(0xFFFEE2E2);
        badgeColor = const Color(0xFFEF4444);
        iconData = Icons.error_outline_rounded;
        break;
      case LogType.warning:
        badgeBg = const Color(0xFFFEF3C7);
        badgeColor = const Color(0xFFD97706);
        iconData = Icons.warning_amber_rounded;
        break;
      case LogType.success:
        badgeBg = const Color(0xFFDCFCE7);
        badgeColor = const Color(0xFF10B981);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case LogType.info:
        badgeBg = const Color(0xFFE0F2FE);
        badgeColor = const Color(0xFF0284C7);
        iconData = Icons.info_outline_rounded;
        break;
    }

    const months = [
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
    final t = log.timestamp;
    final day = t.day.toString().padLeft(2, '0');
    final mon = months[(t.month - 1).clamp(0, 11)];
    final hour = t.hour;
    final min = t.minute.toString().padLeft(2, '0');
    final sec = t.second.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h12 = (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0');
    final timeStr = "$day $mon • $h12:$min:$sec $ampm";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLatest
              ? badgeColor.withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: isLatest ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLatest
                ? badgeColor.withValues(alpha: 0.1)
                : const Color(0xFF0F2942).withValues(alpha: 0.03),
            blurRadius: isLatest ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, size: 14, color: badgeColor),
                      const SizedBox(width: 5),
                      Text(
                        log.event,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLatest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "LATEST",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              log.message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F2942),
                height: 1.35,
              ),
            ),
            if (log.details != null && log.details!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: log.details!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${entry.key}: ",
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${entry.value}",
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
