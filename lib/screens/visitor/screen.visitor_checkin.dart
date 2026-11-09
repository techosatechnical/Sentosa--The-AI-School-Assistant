import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nira/helpers/models/model.visitor.dart';
import 'package:nira/services/service.visitor.dart';
import 'package:nira/widgets/widget.admissiondesk.dart';
import 'package:nira/widgets/widget.touch_keyboard.dart';

class VisitorCheckInScreen extends StatefulWidget {
  final String? initialCategoryId;

  const VisitorCheckInScreen({super.key, this.initialCategoryId});

  @override
  State<VisitorCheckInScreen> createState() => _VisitorCheckInScreenState();
}

class _VisitorCheckInScreenState extends State<VisitorCheckInScreen>
    with SingleTickerProviderStateMixin {
  // Steps:
  // 0: Mobile Number + Returning Visitor Fast-Track
  // 1: Visitor Category
  // 2: Purpose of Visit
  // 3: Student Details (Conditional) & Visitor Name
  // 4: Issued Token Pass
  int _currentStep = 0;
  String _lang = 'en'; // 'en' or 'ml'
  bool _isMuted = false;

  String _phone = '';
  ReturningVisitorProfile? _matchedProfile;

  VisitorCategoryOption _selectedCategory = VisitorCatalog.categories.first;
  VisitorPurposeOption _selectedPurpose = VisitorCatalog.purposes.first;

  String _selectedClass = 'Class V';
  String _selectedDiv = 'A';
  final TextEditingController _studentNameCtrl = TextEditingController();
  final TextEditingController _visitorNameCtrl = TextEditingController();
  bool _editingStudentName = false;

  VisitorRecord? _issuedRecord;
  bool _isSubmitting = false;

  // Hesitation & Inactivity Timers
  Timer? _hesitationTimer;
  Timer? _inactivityTimer;
  Timer? _tokenCountdownTimer;
  int _tokenAutoCloseSeconds = 20;
  bool _showHesitationBanner = false;
  bool _isWarningDialogOpen = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _isMuted = VisitorService().isMuted;
    if (widget.initialCategoryId != null) {
      _selectedCategory = VisitorCatalog.getCategoryById(
        widget.initialCategoryId!,
      );
      final purposes = VisitorCatalog.getPurposesForCategory(
        _selectedCategory.id,
      );
      if (purposes.isNotEmpty) {
        _selectedPurpose = purposes.first;
      }
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceCurrentStep();
      _resetActivityTimers();
    });
  }

  @override
  void dispose() {
    _hesitationTimer?.cancel();
    _inactivityTimer?.cancel();
    _tokenCountdownTimer?.cancel();
    _pulseController.dispose();
    _studentNameCtrl.dispose();
    _visitorNameCtrl.dispose();
    VisitorService().stopSpeech();
    super.dispose();
  }

  bool get _needsStudentInfo =>
      _selectedCategory.requiresStudentInfo ||
      _selectedPurpose.requiresStudentInfo;

  void _resetActivityTimers() {
    if (!mounted) return;
    if (_showHesitationBanner) {
      setState(() => _showHesitationBanner = false);
    }
    _hesitationTimer?.cancel();
    _inactivityTimer?.cancel();

    if (_currentStep == 4) return; // Token screen has its own countdown

    _hesitationTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || _currentStep == 4) return;
      setState(() => _showHesitationBanner = true);
      VisitorService().playChime(ChimeType.nudge);
      VisitorService().speakPrompt(
        "Please tap an option on the screen to continue, or ask the reception desk for help.",
      );
    });

    _inactivityTimer = Timer(const Duration(seconds: 38), () {
      if (!mounted || _currentStep == 4 || _isWarningDialogOpen) return;
      _showInactivityWarningDialog();
    });
  }

  void _showInactivityWarningDialog() {
    _isWarningDialogOpen = true;
    int remaining = 10;
    Timer? dialogTimer;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            dialogTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (!ctx.mounted) {
                t.cancel();
                return;
              }
              if (remaining <= 1) {
                t.cancel();
                Navigator.of(ctx).pop();
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              } else {
                setDialogState(() => remaining--);
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                width: 460,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        size: 38,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _lang == 'ml'
                          ? 'നിങ്ങൾ ഇപ്പോഴും ഇവിടെയുണ്ടോ?'
                          : 'Are you still checking in?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F2942),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lang == 'ml'
                          ? 'തുടരാൻ താഴെയുള്ള ബട്ടണിൽ അമർത്തുക ($remaining സെക്കൻഡ്)'
                          : 'Tap "Continue Check-In" to stay on this screen. Returning to Home in $remaining seconds.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              dialogTimer?.cancel();
                              Navigator.of(ctx).pop();
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _lang == 'ml' ? 'ഹോം സ്ക്രീൻ' : 'Cancel',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              dialogTimer?.cancel();
                              Navigator.of(ctx).pop();
                              _resetActivityTimers();
                            },
                            icon: const Icon(Icons.touch_app_rounded),
                            label: Text(
                              _lang == 'ml'
                                  ? 'തുടരുക (Continue)'
                                  : 'Continue Check-In',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      dialogTimer?.cancel();
      _isWarningDialogOpen = false;
    });
  }

  void _announceCurrentStep() {
    String prompt;
    switch (_currentStep) {
      case 0:
        prompt =
            "Welcome to Nirmala Bhavan Visitor Check-In. Please enter your 10 digit mobile number, or tap Skip.";
        break;
      case 1:
        prompt = "Please tap your visitor category on the screen.";
        break;
      case 2:
        prompt = "Please select the purpose of your visit.";
        break;
      case 3:
        prompt = _needsStudentInfo
            ? "Please select the student's class, enter your name, and tap Generate Token."
            : "Please enter your name and tap Generate Token.";
        break;
      case 4:
        prompt =
            "Thank you! Your visitor token ${_issuedRecord?.shortToken ?? ''} has been generated. Please show your token at the reception desk.";
        break;
      default:
        prompt = "Welcome to Nirmala Bhavan.";
    }
    VisitorService().playChime(
      _currentStep == 4 ? ChimeType.success : ChimeType.step,
    );
    VisitorService().speakPrompt(prompt);
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      if (step == 3) {
        _editingStudentName =
            _needsStudentInfo && _studentNameCtrl.text.trim().isEmpty;
      }
    });
    _resetActivityTimers();
    _announceCurrentStep();
  }

  void _onPhoneDigit(String digit) {
    _resetActivityTimers();
    if (_phone.length >= 10) return;
    final nextPhone = _phone + digit;
    ReturningVisitorProfile? matched;
    if (nextPhone.length == 10) {
      matched = VisitorService().lookupByPhone(nextPhone);
      if (matched != null) {
        _visitorNameCtrl.text = matched.visitorName;
        _selectedCategory = VisitorCatalog.getCategoryById(
          matched.lastCategoryId,
        );
        final purposes = VisitorCatalog.getPurposesForCategory(
          _selectedCategory.id,
        );
        if (purposes.isNotEmpty) {
          _selectedPurpose = purposes.first;
        }
        if (matched.studentName != null && matched.studentName!.isNotEmpty) {
          _studentNameCtrl.text = matched.studentName!;
        }
        if (matched.studentClass != null && matched.studentClass!.isNotEmpty) {
          _selectedClass = matched.studentClass!;
        }
        if (matched.studentDiv != null && matched.studentDiv!.isNotEmpty) {
          _selectedDiv = matched.studentDiv!;
        }
      }
    }
    setState(() {
      _phone = nextPhone;
      _matchedProfile = matched;
    });
  }

  void _onPhoneBackspace() {
    _resetActivityTimers();
    if (_phone.isEmpty) return;
    setState(() {
      _phone = _phone.substring(0, _phone.length - 1);
      _matchedProfile = null;
    });
  }

  void _onPhoneClear() {
    _resetActivityTimers();
    setState(() {
      _phone = '';
      _matchedProfile = null;
    });
  }

  Future<void> _submitVisitorCheckIn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final vName = _visitorNameCtrl.text.trim().isEmpty
          ? 'Guest Visitor'
          : _visitorNameCtrl.text.trim();

      final record = await VisitorService().registerVisitor(
        visitorName: vName,
        phoneNumber: _phone.length == 10 ? _phone : 'Not Provided',
        categoryId: _selectedCategory.id,
        categoryLabel: _selectedCategory.titleEn,
        purposeId: _selectedPurpose.id,
        purposeLabel: _selectedPurpose.titleEn,
        personToMeet: _selectedPurpose.personToMeetEn,
        studentName: _needsStudentInfo ? _studentNameCtrl.text.trim() : null,
        studentClass: _needsStudentInfo ? _selectedClass : null,
        studentDiv: _needsStudentInfo ? _selectedDiv : null,
        languageUsed: _lang,
      );

      if (!mounted) return;
      setState(() {
        _issuedRecord = record;
        _isSubmitting = false;
        _currentStep = 4;
        _tokenAutoCloseSeconds = 22;
      });
      _hesitationTimer?.cancel();
      _inactivityTimer?.cancel();
      _announceCurrentStep();

      _tokenCountdownTimer?.cancel();
      _tokenCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_tokenAutoCloseSeconds <= 1) {
          t.cancel();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          setState(() => _tokenAutoCloseSeconds--);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDBEAFC),
      body: Listener(
        onPointerDown: (_) => _resetActivityTimers(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF2F8FE),
                  Color(0xFFF7FBFF),
                  Color(0xFFE7F1FB),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 3,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  if (_currentStep < 4) _buildStepProgressIndicator(),
                  if (_showHesitationBanner && _currentStep < 4)
                    _buildHesitationBanner(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: Align(
                        key: ValueKey<int>(_currentStep),
                        alignment: Alignment.topCenter,
                        child: _buildCurrentStepBody(),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFBAE6FD), width: 1.8),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2942).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    if (_currentStep > 0 && _currentStep < 4) {
                      _goToStep(_currentStep - 1);
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          size: 24,
                          color: Color(0xFF0F2942),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentStep > 0 && _currentStep < 4
                              ? (_lang == 'ml' ? 'പിന്നോട്ട്' : 'Back')
                              : (_lang == 'ml' ? 'ഹോം' : 'Home'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lang == 'ml'
                            ? 'സന്ദർശക ടോക്കൺ സിസ്റ്റം (Visitor Check-In)'
                            : 'Visitor Token & Reception Check-In',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2942),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Nirmala Bhavan Higher Secondary School • സന്ദർശക പാസ്',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              // Language Toggle Pill
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7DD3FC),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _buildLangChip('en', 'English'),
                    const SizedBox(width: 6),
                    _buildLangChip('ml', 'മലയാളം'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Replay Audio Prompt Button
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.filledTonal(
                  onPressed: () {
                    if (_isMuted) {
                      setState(() => _isMuted = false);
                      VisitorService().setMuted(false);
                    }
                    _announceCurrentStep();
                  },
                  tooltip: 'Replay Audio Instruction',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.campaign_rounded, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              // Mute Toggle Button
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.filledTonal(
                  onPressed: () {
                    setState(() => _isMuted = !_isMuted);
                    VisitorService().setMuted(_isMuted);
                  },
                  tooltip: _isMuted ? 'Unmute Audio' : 'Mute Audio',
                  style: IconButton.styleFrom(
                    backgroundColor: _isMuted
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF1F5F9),
                    foregroundColor: _isMuted
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF475569),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Cancel / Close
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String code, String label) {
    final selected = _lang == code;
    return InkWell(
      onTap: () {
        VisitorService().playChime(ChimeType.tap);
        setState(() => _lang = code);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : const Color(0xFF0369A1),
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressIndicator() {
    final steps = [
      (
        num: '1',
        title: _lang == 'ml' ? 'ഫോൺ നമ്പർ' : 'Mobile Number',
        sub: _lang == 'ml' ? 'Quick Lookup' : 'Fast-Track',
      ),
      (
        num: '2',
        title: _lang == 'ml' ? 'സന്ദർശക വിഭാഗം' : 'Category',
        sub: _lang == 'ml' ? 'Who are you?' : 'Who is visiting',
      ),
      (
        num: '3',
        title: _lang == 'ml' ? 'സന്ദർശന ആവശ്യം' : 'Purpose',
        sub: _lang == 'ml' ? 'Office / Person' : 'Whom to meet',
      ),
      (
        num: '4',
        title: _lang == 'ml' ? 'പേര് & ടോക്കൺ' : 'Get Token',
        sub: _lang == 'ml' ? 'Instant Pass' : 'Name & Pass',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F9FF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone = i < _currentStep;
          final isCurrent = i == _currentStep;
          final step = steps[i];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isDone ? () => _goToStep(i) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF0284C7)
                        : (isDone ? const Color(0xFFDCFCE7) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF0369A1)
                          : (isDone
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFCBD5E1)),
                      width: isCurrent ? 2.2 : 1.5,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF0284C7,
                              ).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? Colors.white
                              : (isDone
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: Colors.white,
                              )
                            : Text(
                                step.num,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: isCurrent
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF475569),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              step.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                color: isCurrent
                                    ? Colors.white
                                    : (isDone
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF0F2942)),
                              ),
                            ),
                            Text(
                              step.sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? const Color(0xFFE0F2FE)
                                    : (isDone
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHesitationBanner() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.65, end: 1.0).animate(_pulseController),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 10, 24, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.touch_app_rounded,
              color: Color(0xFFD97706),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _lang == 'ml'
                    ? 'സഹായം ആവശ്യമുണ്ടോ? സ്ക്രീനിലെ ഏതെങ്കിലും ബട്ടണിൽ തൊടുക, അല്ലെങ്കിൽ റിസപ്ഷനിൽ ചോദിക്കുക.'
                    : 'Need help? Simply tap any option on the screen to continue, or ask the Reception Desk.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Phone();
      case 1:
        return _buildStep1Category();
      case 2:
        return _buildStep2Purpose();
      case 3:
        return _buildStep3Details();
      case 4:
      default:
        return _buildStep4TokenIssued();
    }
  }

  // --- STEP 0: MOBILE NUMBER & RETURNING VISITOR FAST-TRACK ---
  Widget _buildStep0Phone() {
    final isComplete = _phone.length == 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxWidth < 920;

        final infoAndPhoneSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _lang == 'ml'
                        ? 'ഘട്ടം 1 • മൊബൈൽ നമ്പർ'
                        : 'STEP 1 OF 4 • QUICK CHECK-IN',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _lang == 'ml'
                  ? 'നിങ്ങളുടെ 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക'
                  : 'Enter Your 10-Digit Mobile Number',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F2942),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _lang == 'ml'
                  ? 'നിങ്ങൾ മുമ്പ് സന്ദർശിച്ചിട്ടുണ്ടെങ്കിൽ വിവരങ്ങൾ തനിയെ വരുന്നതാണ് (Returning parents get instant autofill).'
                  : 'Returning parents & visitors automatically get their name and student details filled in!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),

            // Phone slots box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isComplete
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0284C7),
                  width: 2.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_iphone_rounded,
                    color: Color(0xFF0284C7),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    width: 2,
                    height: 34,
                    color: const Color(0xFFCBD5E1),
                  ),
                  Expanded(
                    child: Text(
                      _phone.isEmpty ? '• • • • • • • • • •' : _phone,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.2,
                        color: _phone.isEmpty
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF0F2942),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_phone.length}/10',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isComplete
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Returning visitor banner if matched!
            if (_matchedProfile != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 2.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF059669),
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Welcome back, ${_matchedProfile!.visitorName}!',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_matchedProfile!.studentName != null &&
                        _matchedProfile!.studentName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Saved Student: ${_matchedProfile!.studentName} (${_matchedProfile!.studentClass ?? ''}-${_matchedProfile!.studentDiv ?? ''})',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _goToStep(2),
                        icon: const Icon(Icons.flash_on_rounded, size: 22),
                        label: Text(
                          _lang == 'ml'
                              ? 'സന്ദർശന ആവശ്യം തിരഞ്ഞെടുക്കുക (Fast-Track)'
                              : 'Continue as ${_matchedProfile!.visitorName} (Select Purpose)',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _phone = '';
                      _matchedProfile = null;
                      _goToStep(1);
                    },
                    icon: const Icon(Icons.skip_next_rounded, size: 22),
                    label: Text(
                      _lang == 'ml'
                          ? 'ഒഴിവാക്കുക (Skip)'
                          : 'Skip Mobile Number',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.8,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isComplete ? () => _goToStep(1) : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                    label: Text(
                      _lang == 'ml'
                          ? 'അടുത്ത ഘട്ടം (Next)'
                          : 'Next: Visitor Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: isPortrait
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      infoAndPhoneSection,
                      const SizedBox(height: 22),
                      Center(
                        child: KioskNumericKeypad(
                          maxWidth: 500,
                          onDigitPressed: _onPhoneDigit,
                          onBackspace: _onPhoneBackspace,
                          onClear: _onPhoneClear,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: infoAndPhoneSection),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 9,
                        child: Center(
                          child: KioskNumericKeypad(
                            maxWidth: 400,
                            onDigitPressed: _onPhoneDigit,
                            onBackspace: _onPhoneBackspace,
                            onClear: _onPhoneClear,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // --- STEP 1: VISITOR CATEGORY ---
  Widget _buildStep1Category() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxWidth < 920;
        final crossAxisCount = isPortrait ? 2 : 3;
        final aspectRatio = isPortrait ? 1.42 : 1.50;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lang == 'ml'
                      ? 'നിങ്ങൾ ആരാണ്? (Select Visitor Category)'
                      : 'Who is Visiting Today? (Tap One)',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lang == 'ml'
                      ? 'താഴെ കാണുന്ന കാർഡുകളിൽ നിങ്ങളുടെ വിഭാഗം തിരഞ്ഞെടുക്കുക'
                      : 'Touch the card below that best describes you',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: VisitorCatalog.categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final cat = VisitorCatalog.categories[index];
                    final isSelected = _selectedCategory.id == cat.id;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            final applicable =
                                VisitorCatalog.getPurposesForCategory(cat.id);
                            if (applicable.isNotEmpty) {
                              _selectedPurpose = applicable.first;
                            }
                          });
                          _goToStep(2);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isSelected ? cat.bgColor : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? cat.primaryColor
                                  : cat.borderColor,
                              width: isSelected ? 3.0 : 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cat.primaryColor.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cat.bgColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      cat.icon,
                                      size: 34,
                                      color: cat.primaryColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cat.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                cat.titleEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F2942),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cat.titleMl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: cat.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _lang == 'ml' ? cat.subtitleMl : cat.subtitleEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- STEP 2: PURPOSE OF VISIT ---
  Widget _buildStep2Purpose() {
    final purposes = VisitorCatalog.getPurposesForCategory(
      _selectedCategory.id,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxWidth < 920;
        final crossAxisCount = isPortrait ? 2 : 3;
        final aspectRatio = isPortrait ? 1.55 : 1.70;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedCategory.bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedCategory.borderColor,
                        ),
                      ),
                      child: Text(
                        '${_selectedCategory.titleEn} • ${_selectedCategory.titleMl}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _selectedCategory.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _lang == 'ml'
                      ? 'സന്ദർശനത്തിന്റെ ആവശ്യം തിരഞ്ഞെടുക്കുക (Purpose of Visit)'
                      : 'What is the Purpose of Your Visit?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: purposes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final pItem = purposes[index];
                    final isSelected = _selectedPurpose.id == pItem.id;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          setState(() => _selectedPurpose = pItem);
                          _goToStep(3);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE0F2FE)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFFCBD5E1),
                              width: isSelected ? 2.8 : 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F2942,
                                ).withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F9FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      pItem.icon,
                                      color: const Color(0xFF0284C7),
                                      size: 28,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF0284C7),
                                    size: 26,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                pItem.titleEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F2942),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pItem.titleMl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pItem.personToMeetEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- STEP 3: STUDENT & VISITOR DETAILS + TOUCH KEYBOARD ---
  Widget _buildStep3Details() {
    final activeController = _editingStudentName && _needsStudentInfo
        ? _studentNameCtrl
        : _visitorNameCtrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxWidth < 920;

        final studentClassCard = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _lang == 'ml'
                    ? 'കുട്ടിയുടെ ക്ലാസും ഡിവിഷനും (Tap Class & Div)'
                    : 'Select Student Class & Division',
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2942),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: VisitorCatalog.studentClasses.map((cls) {
                  final sel = _selectedClass == cls;
                  return ChoiceChip(
                    label: Text(
                      cls,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : const Color(0xFF0F2942),
                      ),
                    ),
                    selected: sel,
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (_) {
                      VisitorService().playChime(ChimeType.tap);
                      setState(() => _selectedClass = cls);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Division: ',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: VisitorCatalog.studentDivisions.map((div) {
                        final sel = _selectedDiv == div;
                        return ChoiceChip(
                          label: Text(
                            div,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF0F2942),
                            ),
                          ),
                          selected: sel,
                          selectedColor: const Color(0xFF0D9488),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (_) {
                            VisitorService().playChime(ChimeType.tap);
                            setState(() => _selectedDiv = div);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final nameInputsAndButton = Column(
          children: [
            if (_needsStudentInfo) ...[
              _buildSelectableInputBox(
                isFocused: _editingStudentName,
                title: _lang == 'ml'
                    ? 'കുട്ടിയുടെ പേര് (Student Name)'
                    : 'Student Name (Tap to type)',
                controller: _studentNameCtrl,
                placeholder: 'e.g. Ananya Nair',
                icon: Icons.child_care_rounded,
                onTap: () => setState(() => _editingStudentName = true),
              ),
              const SizedBox(height: 12),
            ],
            _buildSelectableInputBox(
              isFocused: !_editingStudentName || !_needsStudentInfo,
              title: _lang == 'ml'
                  ? 'സന്ദർശകന്റെ പേര് (Your Name)'
                  : 'Your Name (Visitor Name)',
              controller: _visitorNameCtrl,
              placeholder: 'e.g. Mr. Sreekumar K',
              icon: Icons.person_rounded,
              onTap: () => setState(() => _editingStudentName = false),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitVisitorCheckIn,
                icon: const Icon(Icons.confirmation_number_rounded, size: 28),
                label: Text(
                  _lang == 'ml'
                      ? 'ടോക്കൺ എടുക്കുക (Generate Token)'
                      : 'Generate Visitor Token Now',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 44, 28, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPortrait) ...[
                  if (_needsStudentInfo) ...[
                    studentClassCard,
                    const SizedBox(height: 14),
                  ],
                  nameInputsAndButton,
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_needsStudentInfo) ...[
                        Expanded(flex: 11, child: studentClassCard),
                        const SizedBox(width: 16),
                      ],
                      Expanded(flex: 10, child: nameInputsAndButton),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Embedded Touch Keyboard
                KioskTouchKeyboard(
                  controller: activeController,
                  quickChips: (_editingStudentName && _needsStudentInfo)
                      ? const ['Master ', 'Miss ']
                      : const [
                          'Mr. ',
                          'Mrs. ',
                          'Ms. ',
                          'Dr. ',
                          'Sr. ',
                          'Parent',
                        ],
                  onSubmitted: () {
                    if (_editingStudentName && _needsStudentInfo) {
                      setState(() => _editingStudentName = false);
                    } else {
                      _submitVisitorCheckIn();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectableInputBox({
    required bool isFocused,
    required String title,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isFocused ? const Color(0xFFF0F9FF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isFocused
                    ? const Color(0xFF0284C7)
                    : const Color(0xFFCBD5E1),
                width: isFocused ? 2.8 : 1.6,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isFocused
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF64748B),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isFocused
                              ? const Color(0xFF0284C7)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.text.isEmpty ? placeholder : value.text,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: value.text.isEmpty
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F2942),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFocused)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TYPING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- STEP 4: ISSUED VISITOR TOKEN PASS ---
  Widget _buildStep4TokenIssued() {
    final rec = _issuedRecord;
    if (rec == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF38BDF8), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 38,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lang == 'ml'
                              ? 'സന്ദർശക ടോക്കൺ തയ്യാറായി!'
                              : 'Visitor Token Generated Successfully!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                        Text(
                          'Nirmala Bhavan Higher Secondary School • ${rec.formattedDate} at ${rec.formattedTime}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOKEN NO.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFBAE6FD),
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          rec.shortToken,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          rec.tokenId,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE0F2FE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildPassDetailItem(
                      'Visitor Name',
                      rec.visitorName,
                      Icons.person_outline_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildPassDetailItem(
                      'Mobile Number',
                      rec.phoneNumber,
                      Icons.phone_iphone_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildPassDetailItem(
                      'Visitor Category',
                      rec.categoryLabel,
                      Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildPassDetailItem(
                      'Purpose of Visit',
                      rec.purposeLabel,
                      Icons.assignment_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildPassDetailItem(
                      'Person / Office to Meet',
                      rec.personToMeet,
                      Icons.meeting_room_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildPassDetailItem(
                      'Student Details',
                      rec.studentSummary,
                      Icons.school_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF0284C7),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPurpose.instructionEn,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F2942),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPurpose.instructionMl,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (rec.categoryId == 'admission' ||
                      rec.purposeId == 'admission_desk') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _tokenCountdownTimer?.cancel();
                          showDialog(
                            context: context,
                            builder: (_) => const AdmissionAssistantDialog(),
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text(
                          'Open Online Admission Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D9488),
                          side: const BorderSide(
                            color: Color(0xFF0D9488),
                            width: 1.8,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        'Done • Returning Home ($_tokenAutoCloseSeconds s)',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
  }

  Widget _buildPassDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
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
