import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sentosa/services/services.dart';
import 'package:sentosa/helpers/enums/enums.dart';
import 'package:sentosa/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  final GeminiService _geminiService = GeminiService();
  final WakeWordService _wakeWordService = WakeWordService();
  
  bool _isMicModeActive = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _statusText = "Say 'Sentosa' or tap mic";
  final List<Map<String, String>> _messages = [];
  String _currentModelTurn = "";

  late AnimationController _headFloatController;
  late AnimationController _rayPulseController;
  late AnimationController _waveController;
  late AnimationController _eyeGlowController;
  late Animation<double> _eyeGlowAnimation;
  late AnimationController _nodController;
  late AnimationController _squintController;
  late Animation<double> _squintAnimation;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;


  final ValueNotifier<Offset> _gazeNotifier = ValueNotifier<Offset>(Offset.zero);
  bool _isTrackingPointer = false;
  bool _isReacting = false;

  Timer? _idleTimer;
  Timer? _roamTimer;
  Timer? _blinkCadenceTimer;


  final List<Map<String, dynamic>> _roamTargets = [
    {'x': 0.0, 'y': 0.0, 'dwell': 2600, 'blink': false},
    {'x': -9.0, 'y': -2.0, 'dwell': 1800, 'blink': true},
    {'x': -11.0, 'y': 4.0, 'dwell': 1400, 'blink': false},
    {'x': 0.0, 'y': 0.0, 'dwell': 2200, 'blink': true},
    {'x': 10.0, 'y': -4.0, 'dwell': 1900, 'blink': false},
    {'x': 8.0, 'y': 5.0, 'dwell': 1600, 'blink': true},
    {'x': -5.0, 'y': -5.0, 'dwell': 1500, 'blink': false},
    {'x': 0.0, 'y': 0.0, 'dwell': 2800, 'blink': true},
    {'x': 11.0, 'y': 1.0, 'dwell': 2000, 'blink': false},
    {'x': 0.0, 'y': 3.0, 'dwell': 1700, 'blink': true},
  ];
  int _roamIndex = 0;


  final List<Map<String, String>> _greetings = [
    {
      'hi': 'Hi! 👋',
      'text': 'I’m Sentosa, your school assistant.\nHow can I help you today?',
    },
    {
      'hi': 'I\'m listening! ✨',
      'text': 'Ask me anything about classes,\nrooms, or events!',
    },
    {
      'hi': 'Great to see you! 🌟',
      'text': 'Tap any card below or speak\ndirectly to me!',
    },
    {
      'hi': 'Here to help! 🚀',
      'text': 'Looking for buses, cafeteria menus,\nor your next class?',
    },
  ];
  int _greetingIndex = 0;


  final GlobalKey _visorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _geminiService.onStatusUpdate = (status) {
      if (mounted) setState(() => _statusText = status);
    };

    _geminiService.onTranscriptUpdate = (text) {
      if (mounted) {
        setState(() {
          _currentModelTurn += text;
          final cleaned = _cleanAIResponse(_currentModelTurn);
          if (cleaned.isNotEmpty) {
            if (_messages.isNotEmpty && _messages.last['role'] == 'model') {
              _messages.last['text'] = cleaned;
            } else {
              _messages.add({'role': 'model', 'text': cleaned});
            }
          }
        });
      }
    };

    _geminiService.onTurnComplete = () {
      if (mounted) setState(() => _currentModelTurn = "");
    };

    _geminiService.onSpeakingStateChanged = (speaking) {
      if (mounted) setState(() => _isSpeaking = speaking);
    };

    _geminiService.onConversationStateChanged = (state) {
      if (mounted) {
        setState(() {
          _isListening = state != ConversationState.standby;
          _isSpeaking = state == ConversationState.speaking;
        });
      }
    };

    _geminiService.onDisconnected = () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isSpeaking = false;
          _statusText = "Say 'Sentosa' or tap mic";
        });
      }
    };

    _wakeWordService.onWakeWordDetected = (phrase, conf) {
      if (_isMicModeActive && !_geminiService.isConnected) {
        _startListening(fromWakeWord: true);
      }
    };

    _wakeWordService.onInterruptDetected = (phrase) {
      // Intentionally ignored. Voice-based interruption disabled 
      // due to noisy school environment false-positives. 
      // Users must tap the Mic button to interrupt.
    };
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });


    _headFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);


    _rayPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);


    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);


    _eyeGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _eyeGlowAnimation = CurvedAnimation(
      parent: _eyeGlowController,
      curve: Curves.easeInOut,
    );


    _nodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );


    _squintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _squintAnimation = CurvedAnimation(
      parent: _squintController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );


    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _blinkAnimation = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );


    _scheduleNextBlink();
    _startAutonomousRoam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wakeWordService.dispose();
    _geminiService.dispose();
    _clockTimer.cancel();
    _idleTimer?.cancel();
    _roamTimer?.cancel();
    _blinkCadenceTimer?.cancel();

    _headFloatController.dispose();
    _rayPulseController.dispose();
    _waveController.dispose();
    _eyeGlowController.dispose();
    _nodController.dispose();
    _squintController.dispose();
    _blinkController.dispose();
    _gazeNotifier.dispose();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    _wakeWordService.dispose();
    _geminiService.dispose();
    return AppExitResponse.exit;
  }

  String _cleanAIResponse(String input) {
    var text = input;
    // Strip <think>...</think> and unclosed <think>... during live streaming
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?(?:</think>|$)', caseSensitive: false), '');
    // Strip <thought>...</thought> and unclosed <thought>...
    text = text.replaceAll(RegExp(r'<thought>[\s\S]*?(?:</thought>|$)', caseSensitive: false), '');
    // Strip Thought: ... up to next paragraph or end
    text = text.replaceAll(RegExp(r'^\s*Thought:[\s\S]*?(?:\n\n|$)', caseSensitive: false), '');
    // Strip bracketed instructions like [whispers] or [speaks Malayalam]
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');
    // Strip markdown formatting symbols
    text = text.replaceAll('*', '');
    text = text.replaceAll('#', '');
    return text.trim();
  }

  Future<void> _startListening({bool fromWakeWord = false}) async {
    setState(() {
      _isMicModeActive = true;
      _isListening = true;
      _messages.clear();
      _currentModelTurn = "";
      _statusText = fromWakeWord ? "Awakened! Connecting to Gemini Live..." : "Connecting to Gemini Live...";
    });
    try {
      await _geminiService.connect();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = "Error: $e";
        });
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _isSpeaking = false;
        _statusText = "Say 'Sentosa' or tap mic";
      });
      await _geminiService.disconnect();
    } else {
      await _startListening();
    }
  }

  Future<void> _triggerBlink({bool doubleBlink = false}) async {
    if (_isReacting || !mounted || _blinkController.isAnimating) return;

    try {

      await _blinkController.forward();
      if (!mounted) return;


      await _blinkController.reverse();
      if (!mounted) return;


      if (doubleBlink && math.Random().nextDouble() > 0.45) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted || _isReacting) return;
        await _blinkController.forward();
        if (!mounted) return;
        await _blinkController.reverse();
      }
    } catch (_) {

    }
  }

  void _scheduleNextBlink() {
    final delay = 2400 + math.Random().nextInt(3200);
    _blinkCadenceTimer = Timer(Duration(milliseconds: delay), () {
      if (!_isReacting && mounted) {
        _triggerBlink(doubleBlink: math.Random().nextDouble() > 0.65);
      }
      _scheduleNextBlink();
    });
  }

  void _startAutonomousRoam() {
    if (_isTrackingPointer || _isReacting || !mounted) return;

    final target = _roamTargets[_roamIndex];
    _roamIndex = (_roamIndex + 1) % _roamTargets.length;


    if (target['blink'] == true && math.Random().nextDouble() > 0.35) {
      _triggerBlink();
    }


    _gazeNotifier.value = Offset(
      (target['x'] as num).toDouble(),
      (target['y'] as num).toDouble(),
    );

    _roamTimer = Timer(Duration(milliseconds: target['dwell'] as int), () {
      _startAutonomousRoam();
    });
  }

  void _handlePointerMove(Offset globalPos) {
    if (_isReacting) return;

    _isTrackingPointer = true;
    _roamTimer?.cancel();
    _idleTimer?.cancel();

    final renderBox = _visorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final visorCenter = renderBox.localToGlobal(
        Offset(renderBox.size.width / 2, renderBox.size.height / 2),
      );
      final dx = globalPos.dx - visorCenter.dx;
      final dy = globalPos.dy - visorCenter.dy;


      final targetX = (dx / 26.0).clamp(-14.0, 14.0);
      final targetY = (dy / 24.0).clamp(-10.0, 10.0);


      _gazeNotifier.value = Offset(targetX, targetY);
    }


    _idleTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _isTrackingPointer = false;
        _gazeNotifier.value = Offset.zero;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && !_isTrackingPointer && !_isReacting) {
            _startAutonomousRoam();
          }
        });
      }
    });
  }

  void _triggerRobotReaction() {
    if (_isReacting) return;
    _isReacting = true;
    _isTrackingPointer = false;
    _roamTimer?.cancel();
    _idleTimer?.cancel();


    _gazeNotifier.value = const Offset(0.0, -3.0);


    setState(() {
      _greetingIndex = (_greetingIndex + 1) % _greetings.length;
    });


    _nodController.forward(from: 0.0);
    _squintController.forward();


    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        _squintController.reverse().then((_) {
          if (mounted) {
            _triggerBlink(doubleBlink: true);
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                _isReacting = false;
                _gazeNotifier.value = Offset.zero;
                _startAutonomousRoam();
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDBEAFC),
      body: MouseRegion(
        onHover: (e) => _handlePointerMove(e.position),
        child: Listener(
          onPointerMove: (e) => _handlePointerMove(e.position),
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
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2942).withValues(alpha: 0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 3,
                ),
              ),
              child: Stack(
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
                    bottom: false,
                    child: Column(
                      children: [
                        _buildTopHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 4),
                                  _buildRobotHeadHeroSection(),
                                  const SizedBox(height: 4),
                                  _buildSpeechBubble(),
                                  const SizedBox(height: 10),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    transitionBuilder: (child, animation) {
                                      final offsetAnimation = Tween<Offset>(
                                        begin: const Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOutQuart,
                                      ));
                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _isMicModeActive
                                        ? _buildSentosaMicSection()
                                        : Column(
                                            key: const ValueKey('QuickActions'),
                                            children: [
                                              _buildQuickActionsHeader(),
                                              const SizedBox(height: 8),
                                              _buildQuickActionsGrid(),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildPersistentBottomBar(),
                      ],
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


  Widget _buildTopHeader() {
    final hour = _currentTime.hour % 12 == 0 ? 12 : _currentTime.hour % 12;
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final period = _currentTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "$hour:$minute $period";

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        "${weekdays[_currentTime.weekday - 1]}, ${_currentTime.day} ${months[_currentTime.month - 1]} ${_currentTime.year}";

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 14, 32, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: SentosaLogoPainter(),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sentosa",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.6,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Your School Assistant",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F2942).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),


          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F2942).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 1.5,
                height: 28,
                color: const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2942).withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_done_rounded,
                      size: 15,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6EE7B7),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Cloud Connected",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildRobotHeadHeroSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _headFloatController,
        _rayPulseController,
        _nodController,
      ]),
      builder: (context, child) {

        final floatY = math.sin(_headFloatController.value * math.pi) * -5.0;

        final nodY = math.sin(_nodController.value * math.pi * 2) * 5.0;
        final totalY = floatY + nodY;

        return Transform.translate(
          offset: Offset(0, totalY),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [

              Positioned(
                left: 10,
                child: _buildRays(isLeft: true),
              ),


              Positioned(
                right: 10,
                child: _buildRays(isLeft: false),
              ),


              GestureDetector(
                onTap: _triggerRobotReaction,
                child: Container(
                  key: _visorKey,
                  width: 310,
                  height: 172,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFEBF4FD),
                        Color(0xFFD6E7FA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(76),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2575FC).withValues(alpha: 0.24),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0F2942).withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 3.5,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF111928),
                          Color(0xFF09111C),
                          Color(0xFF03070D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(62),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF334155).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 65,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(60),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.16),
                                  Colors.white.withValues(alpha: 0.04),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildExpressiveEye(),
                            const SizedBox(width: 32),
                            _buildExpressiveEye(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildRays({required bool isLeft}) {
    final pulseScale = 1.0 + (_rayPulseController.value * 0.12);
    final pulseOpacity = 0.75 + (_rayPulseController.value * 0.25);

    return Opacity(
      opacity: pulseOpacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: pulseScale,
        child: Column(
          children: [
            Transform.rotate(
              angle: isLeft ? -0.58 : 0.58, // ~35 deg
              child: _rayPill(width: 24),
            ),
            const SizedBox(height: 6),
            _rayPill(width: 30),
            const SizedBox(height: 6),
            Transform.rotate(
              angle: isLeft ? 0.58 : -0.58,
              child: _rayPill(width: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rayPill({required double width}) {
    return Container(
      width: width,
      height: 8.5,
      decoration: BoxDecoration(
        color: const Color(0xFF4096FE),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0xBF4096FE),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }


  Widget _buildExpressiveEye() {
    return RepaintBoundary(
      child: ValueListenableBuilder<Offset>(
        valueListenable: _gazeNotifier,
        builder: (context, gaze, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: const Cubic(0.25, 1.0, 0.35, 1.0), // Exact Stitch saccade curve
            transform: Matrix4.translationValues(gaze.dx, gaze.dy, 0),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _blinkAnimation,
                _squintAnimation,
                _eyeGlowAnimation,
              ]),
              builder: (context, _) {
                final tBlink = _blinkAnimation.value;
                final tSquint = _squintAnimation.value;
                final tGlow = _eyeGlowAnimation.value;




                final scaleY =
                    (1.0 - (0.94 * tBlink) - (0.78 * tSquint)).clamp(0.06, 1.2);
                final scaleX =
                    (1.0 + (0.08 * tBlink) + (0.04 * tSquint)).clamp(0.8, 1.2);
                final translateY = 12.0 * tSquint;





                final blinkRadius = 26.0 - (22.0 * tBlink);
                final topRadius =
                    (blinkRadius + (14.0 * tSquint)).clamp(4.0, 40.0);
                final bottomRadius =
                    (blinkRadius - (16.0 * tSquint)).clamp(4.0, 26.0);
                final borderRadius = BorderRadius.vertical(
                  top: Radius.circular(topRadius),
                  bottom: Radius.circular(bottomRadius),
                );


                final specularOpacity =
                    ((1.0 - tBlink) * (1.0 - tSquint)).clamp(0.0, 1.0);


                final glowSpread = 2.0 + (tGlow * 3.0);
                final glowBlur = 16.0 + (tGlow * 12.0);

                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    alignment: Alignment.center,
                    child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF020914),
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: const Color(0xFF38BDF8),
                        width: tSquint > 0.4 ? 3.5 : 5.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.85),
                          blurRadius: glowBlur,
                          spreadRadius: glowSpread,
                        ),
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                          blurRadius: glowBlur * 1.6,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [

                        Positioned(
                          top: 8,
                          right: 8,
                          child: Opacity(
                            opacity: specularOpacity,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),


                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Opacity(
                            opacity: specularOpacity * 0.5,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFBAE6FD),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }


  Widget _buildSpeechBubble() {
    final aiResponse = _getLatestAIResponse();
    final hasResponse = aiResponse.isNotEmpty;
    final currentGreeting = _greetings[_greetingIndex];

    return GestureDetector(
      onTap: () {
        if (hasResponse) {
          setState(() {
            _messages.clear();
            _currentModelTurn = "";
          });
        }
        _triggerRobotReaction();
      },
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE0F2FE)),
                    left: BorderSide(color: Color(0xFFE0F2FE)),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2942).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: hasResponse
                    ? (_isSpeaking
                        ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.4))
                    : const Color(0xFFE0F2FE),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasResponse) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentGreeting['hi'] ?? 'Hi!',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2942),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          final waveAngle = math.sin(_waveController.value * math.pi * 2) * 0.25;
                          return Transform.rotate(
                            angle: waveAngle,
                            child: const Text(
                              "👋",
                              style: TextStyle(fontSize: 24),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentGreeting['text'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSpeaking ? "Sentosa Speaking..." : "Sentosa",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _isSpeaking ? const Color(0xFFA855F7) : const Color(0xFF0F2942),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: _isSpeaking ? const Color(0xFFA855F7) : const Color(0xFF38BDF8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        aiResponse,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F2942),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLatestAIResponse() {
    if (_messages.isEmpty) return "";
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['role'] == 'model') {
        return _messages[i]['text'] ?? "";
      }
    }
    return "";
  }

  Widget _buildSentosaMicSection() {
    final activeColor = _isSpeaking
        ? const Color(0xFFA855F7)
        : (_isListening ? const Color(0xFF38BDF8) : const Color(0xFF10B981));
        
    return Container(
      key: const ValueKey('MicSection'),
      constraints: const BoxConstraints(minHeight: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_backspace_rounded, color: Color(0xFF0F2942), size: 28),
                onPressed: () async {
                  if (_isListening) {
                    await _toggleListening();
                  }
                  _wakeWordService.stop();
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (mounted) {
                    setState(() {
                      _isMicModeActive = false;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TALK TO SENTOSA",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Your personal AI assistant.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          StatusBadge(
            isListening: _isListening,
            isSpeaking: _isSpeaking,
            activeColor: activeColor,
          ),
          const SizedBox(height: 14),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: const Color(0xFF0F2942).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          MicButton(
            size: 200.0,
            pulseAnimation: _rayPulseController, 
            waveAnimation: _waveController,
            isListening: _isListening,
            isSpeaking: _isSpeaking,
            activeColor: activeColor,
            onTap: _toggleListening,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHeader() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            Icons.auto_awesome,
            size: 28,
            color: Color(0xFF38BDF8),
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F2942),
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 3),
            Text(
              "Tap on a question or choose an option below.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildQuickActionsGrid() {
    final cards = [
      ActionCardData(
        title: "Talk to Sentosa",
        subtitle: "Ask anything\n(or just say it!).",
        bgColor: const Color(0xFFF1EFFF),
        hoverColor: const Color(0xFFE4E0FD),
        borderColor: const Color(0xFFE3DEFA),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF8B5CF6),
        accentDashColor: const Color(0xFFC4B5FD),
      ),
      ActionCardData(
        title: "Mini Admission\nAssistant",
        subtitle: "Quick admission process\nwith photo & details.",
        bgColor: const Color(0xFFE6F9F9),
        hoverColor: const Color(0xFFD3F5F5),
        borderColor: const Color(0xFFCEF4F4),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF14B8A6),
        accentDashColor: const Color(0xFF5EEAD4),
      ),
      ActionCardData(
        title: "Principal’s\nOffice",
        subtitle: "Get office location,\ncontact or assistance.",
        bgColor: const Color(0xFFF3EFFF),
        hoverColor: const Color(0xFFE8E1FD),
        borderColor: const Color(0xFFE5DEFB),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF818CF8),
        accentDashColor: const Color(0xFFC4B5FD),
      ),
      ActionCardData(
        title: "Where is\nthe library?",
        subtitle: "Find books, study areas\nand more.",
        bgColor: const Color(0xFFEBF5FF),
        hoverColor: const Color(0xFFDCEEFE),
        borderColor: const Color(0xFFD6EBFF),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF38BDF8),
        accentDashColor: const Color(0xFF93C5FD),
      ),
      ActionCardData(
        title: "Cafeteria",
        subtitle: "Check meal timings,\nmenu and location.",
        bgColor: const Color(0xFFEDFAF3),
        hoverColor: const Color(0xFFDCF6E8),
        borderColor: const Color(0xFFD1F2E2),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF10B981),
        accentDashColor: const Color(0xFF86EFAC),
      ),
      ActionCardData(
        title: "School Events",
        subtitle: "See upcoming events,\nholidays and activities.",
        bgColor: const Color(0xFFFFF6EB),
        hoverColor: const Color(0xFFFEEED6),
        borderColor: const Color(0xFFFEE8CC),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFFF59E0B),
        accentDashColor: const Color(0xFFFDE68A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 768 ? 4 : 2;
        final totalSpacing = 16.0 * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
        const desiredItemHeight = 252.0;
        final childAspectRatio = itemWidth / desiredItemHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildTouchCard(card, index);
          },
        );
      },
    );
  }

  Widget _buildCardGraphic(int index, Color dashColor) {
    CustomPainter painter;
    switch (index) {
      case 0:
        painter = TalkGraphicPainter(dashColor);
        break;
      case 1:
        painter = AdmissionGraphicPainter(dashColor);
        break;
      case 2:
        painter = PrincipalGraphicPainter(dashColor);
        break;
      case 3:
        painter = MapGraphicPainter(dashColor);
        break;
      case 4:
        painter = CafeteriaGraphicPainter(dashColor);
        break;
      case 5:
      default:
        painter = EventsGraphicPainter(dashColor);
        break;
    }
    return SizedBox(
      width: 76,
      height: 72,
      child: CustomPaint(painter: painter),
    );
  }

  Widget _buildTouchCard(ActionCardData card, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (card.title == "Talk to Sentosa") {
            _wakeWordService.start();
            setState(() {
              _isMicModeActive = true;
            });
          } else {
            _triggerRobotReaction();
          }
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: card.arrowColor.withValues(alpha: 0.18),
        highlightColor: card.hoverColor.withValues(alpha: 0.6),
        child: Container(
          decoration: BoxDecoration(
            color: card.bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: card.borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2942).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    SizedBox(
                      height: 72,
                      child: Center(
                        child: _buildCardGraphic(index, card.accentDashColor),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      card.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: card.titleColor,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      card.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),


              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.arrowColor,
                    boxShadow: [
                      BoxShadow(
                        color: card.arrowColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPersistentBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F3FD),
            Color(0xFFDBEDFD),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFBAE6FD).withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: const [
              Icon(
                Icons.school_rounded,
                size: 26,
                color: Color(0xFF1E40AF),
              ),
              SizedBox(width: 12),
              Text(
                "A Smarter School",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "✦",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              Text(
                "A Brighter Future",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),


          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 22,
                      color: Color(0xFF1D4ED8),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Accessibility Mode",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF1D4ED8),
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




