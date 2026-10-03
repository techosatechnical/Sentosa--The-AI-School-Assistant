import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sentosa/services/services.dart';
import 'package:sentosa/helpers/enums/enums.dart';
import 'package:sentosa/screens/home/widgets/home_top_header.dart';
import 'package:sentosa/screens/home/widgets/home_bottom_bar.dart';
import 'package:sentosa/screens/home/widgets/home_quick_actions.dart';
import 'package:sentosa/screens/home/widgets/home_speech_bubble.dart';
import 'package:sentosa/screens/home/widgets/home_sentosa_mic.dart';
import 'package:sentosa/main.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  final GeminiService _geminiService = GeminiService();
  final WakeWordService _wakeWordService = WakeWordService();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  double _currentAmplitude = -50.0;
  String _statusText = "Say 'Hey Sentosa' or tap mic";
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

  final ValueNotifier<Offset> _gazeNotifier = ValueNotifier<Offset>(
    Offset.zero,
  );
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
      'hi': 'Welcome back! ✨',
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
          _isListening = state == ConversationState.active || state == ConversationState.thinking;
          _isThinking = state == ConversationState.thinking;
          _isSpeaking = state == ConversationState.speaking;
          
          if (_isThinking) {
            _gazeNotifier.value = const Offset(0.0, -8.0);
          } else if (_isListening && !_isTrackingPointer) {
             _gazeNotifier.value = const Offset(0.0, 0.0);
          }
          
          if (state == ConversationState.standby) {
            _messages.clear();
            _currentModelTurn = "";
          }
        });
      }
    };
    
    _geminiService.onAmplitudeUpdate = (amp) {
      if (mounted) {
        setState(() {
           _currentAmplitude = amp;
           if (amp > -25.0 && _isListening && !_isThinking && !_isReacting) {
             _gazeNotifier.value = const Offset(0.0, 0.0);
             _triggerBlink();
           }
        });
      }
    };

    _geminiService.onDisconnected = () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isSpeaking = false;
          _isThinking = false;
          _statusText = "Say 'Hey Sentosa' or tap mic";
        });
      }
    };

    _wakeWordService.onWakeWordDetected = (phrase, conf) {
      if (!_geminiService.isConnected) {
        _startListening(fromWakeWord: true);
      }
    };

    _wakeWordService.onInterruptDetected = (phrase) {};
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
    _wakeWordService.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _wakeWordService.stop();
    if (_isListening || _isSpeaking) {
      _toggleListening();
    }
  }

  @override
  void didPopNext() {
    _wakeWordService.start();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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
    text = text.replaceAll(
      RegExp(r'<think>[\s\S]*?(?:</think>|$)', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<thought>[\s\S]*?(?:</thought>|$)', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'^\s*Thought:[\s\S]*?(?:\n\n|$)', caseSensitive: false),
      '',
    );
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');
    text = text.replaceAll('*', '');
    text = text.replaceAll('#', '');
    return text.trim();
  }

  Future<void> _startListening({bool fromWakeWord = false}) async {
    setState(() {
      _isListening = true;
      _messages.clear();
      _currentModelTurn = "";
      _statusText = fromWakeWord
          ? "Awakened! Connecting to Gemini Live..."
          : "Connecting to Gemini Live...";
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
        _isThinking = false;
        _statusText = "Say 'Hey Sentosa' or tap mic";
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
    } catch (_) {}
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

    final renderBox =
        _visorKey.currentContext?.findRenderObject() as RenderBox?;
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final blobScale = (screenWidth / 430).clamp(1.0, 1.9);

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
                      width: 250 * blobScale,
                      height: 250 * blobScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 280,
                    right: -60,
                    child: Container(
                      width: 260 * blobScale,
                      height: 260 * blobScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDBEAFE).withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: -50,
                    child: Container(
                      width: 240 * blobScale,
                      height: 240 * blobScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFCCFBF1).withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        HomeTopHeader(currentTime: _currentTime),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final heroScale = (constraints.maxHeight / 760)
                                  .clamp(1.0, 1.6);
                              return SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 60 * heroScale),
                                        _buildRobotHeadHeroSection(heroScale),
                                        SizedBox(height: 8 * heroScale),
                                        HomeSpeechBubble(
                                          aiResponse: _getLatestAIResponse(),
                                          currentGreeting: _greetings[_greetingIndex],
                                          isSpeaking: _isSpeaking,
                                          waveAnimation: _waveController,
                                          onTap: () {
                                            if (_getLatestAIResponse().isNotEmpty) {
                                              setState(() {
                                                _messages.clear();
                                                _currentModelTurn = "";
                                              });
                                            }
                                            _triggerRobotReaction();
                                          },
                                        ),
                                        SizedBox(height: 10 * heroScale),
                                        HomeSentosaMicSection(
                                          isListening: _isListening,
                                          isSpeaking: _isSpeaking,
                                          isThinking: _isThinking,
                                          currentAmplitude: _currentAmplitude,
                                          statusText: _statusText,
                                          pulseAnimation: _rayPulseController,
                                          waveAnimation: _waveController,
                                          onMicTap: _toggleListening,
                                        ),
                                        SizedBox(height: 32 * heroScale),
                                        HomeQuickActions(
                                          onRobotReaction: _triggerRobotReaction,
                                        ),
                                        SizedBox(height: 16 * heroScale),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const HomeBottomBar(),
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


  Widget _buildRobotHeadHeroSection(double scale) {
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
                left: 10 * scale,
                child: _buildRays(isLeft: true, scale: scale),
              ),

              Positioned(
                right: 10 * scale,
                child: _buildRays(isLeft: false, scale: scale),
              ),

              GestureDetector(
                onTap: _triggerRobotReaction,
                child: Container(
                  key: _visorKey,
                  width: 538 * scale,
                  height: 297 * scale,
                  padding: EdgeInsets.all(26 * scale),
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
                    borderRadius: BorderRadius.circular(132 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2575FC).withValues(alpha: 0.24),
                        blurRadius: 36 * scale,
                        offset: Offset(0, 16 * scale),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0F2942).withValues(alpha: 0.1),
                        blurRadius: 16 * scale,
                        offset: Offset(0, 6 * scale),
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
                      borderRadius: BorderRadius.circular(106 * scale),
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
                          height: 112 * scale,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(104 * scale),
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
                            _buildExpressiveEye(scale),
                            SizedBox(width: 55 * scale),
                            _buildExpressiveEye(scale),
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

  Widget _buildRays({required bool isLeft, required double scale}) {
    final pulseScale = 1.0 + (_rayPulseController.value * 0.12);
    final pulseOpacity = 0.75 + (_rayPulseController.value * 0.25);

    return Opacity(
      opacity: pulseOpacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: pulseScale,
        child: Column(
          children: [
            Transform.rotate(
              angle: isLeft ? -0.58 : 0.58,
              child: _rayPill(width: 41 * scale, scale: scale),
            ),
            SizedBox(height: 10 * scale),
            _rayPill(width: 52 * scale, scale: scale),
            SizedBox(height: 10 * scale),
            Transform.rotate(
              angle: isLeft ? 0.58 : -0.58,
              child: _rayPill(width: 41 * scale, scale: scale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rayPill({required double width, required double scale}) {
    return Container(
      width: width,
      height: 14.5 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFF4096FE),
        borderRadius: BorderRadius.circular(18 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xBF4096FE),
            blurRadius: 10 * scale,
            spreadRadius: 1 * scale,
          ),
        ],
      ),
    );
  }

  Widget _buildExpressiveEye(double scale) {
    return RepaintBoundary(
      child: ValueListenableBuilder<Offset>(
        valueListenable: _gazeNotifier,
        builder: (context, gaze, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: const Cubic(0.25, 1.0, 0.35, 1.0),
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

                final scaleY = (1.0 - (0.94 * tBlink) - (0.78 * tSquint)).clamp(
                  0.06,
                  1.2,
                );
                final scaleX = (1.0 + (0.08 * tBlink) + (0.04 * tSquint)).clamp(
                  0.8,
                  1.2,
                );
                final translateY = 20.0 * scale * tSquint;

                final blinkRadius = (45.0 - (38.0 * tBlink)) * scale;
                final topRadius = (blinkRadius + (25.0 * scale * tSquint))
                    .clamp(4.0, 70.0 * scale);
                final bottomRadius = (blinkRadius - (27.0 * scale * tSquint))
                    .clamp(4.0, 45.0 * scale);
                final borderRadius = BorderRadius.vertical(
                  top: Radius.circular(topRadius),
                  bottom: Radius.circular(bottomRadius),
                );

                final specularOpacity = ((1.0 - tBlink) * (1.0 - tSquint))
                    .clamp(0.0, 1.0);

                final glowSpread = (3.5 + (tGlow * 5.2)) * scale;
                final glowBlur = (28.0 + (tGlow * 20.0)) * scale;

                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    alignment: Alignment.center,
                    child: Container(
                      width: 124 * scale,
                      height: 124 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF020914),
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: const Color(0xFF38BDF8),
                          width: (tSquint > 0.4 ? 6.0 : 8.7) * scale,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF38BDF8,
                            ).withValues(alpha: 0.85),
                            blurRadius: glowBlur,
                            spreadRadius: glowSpread,
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFF0EA5E9,
                            ).withValues(alpha: 0.5),
                            blurRadius: glowBlur * 1.6,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 13 * scale,
                            right: 13 * scale,
                            child: Opacity(
                              opacity: specularOpacity,
                              child: Container(
                                width: 20 * scale,
                                height: 20 * scale,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    8 * scale,
                                  ),
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
                            bottom: 13 * scale,
                            left: 13 * scale,
                            child: Opacity(
                              opacity: specularOpacity * 0.5,
                              child: Container(
                                width: 8 * scale,
                                height: 8 * scale,
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


  String _getLatestAIResponse() {
    if (_messages.isEmpty) return "";
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['role'] == 'model') {
        return _messages[i]['text'] ?? "";
      }
    }
    return "";
  }

}
