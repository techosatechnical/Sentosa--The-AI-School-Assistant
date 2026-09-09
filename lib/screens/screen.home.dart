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
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final GeminiService _geminiService = GeminiService();
  final WakeWordService _wakeWordService = WakeWordService();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _showAdmissionModal = false;
  String _statusText = "Say 'Sentosa' or tap mic to start";
  final List<Map<String, String>> _messages = [];
  String _currentModelTurn = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _geminiService.onStatusUpdate = (status) {
      if (mounted) {
        setState(() {
          _statusText = status;
        });
      }
    };

    _geminiService.onTranscriptUpdate = (text) {
      if (mounted) {
        setState(() {
          _currentModelTurn += text;
          final cleaned = _cleanJunkText(_currentModelTurn);
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
      if (mounted) {
        setState(() {
          _currentModelTurn = "";
        });
      }
    };

    _geminiService.onSpeakingStateChanged = (speaking) {
      if (mounted) {
        setState(() {
          _isSpeaking = speaking;
        });
      }
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
          _statusText = "Say 'Sentosa' or tap mic to start";
        });
      }
    };

    _wakeWordService.onWakeWordDetected = (phrase, conf) {
      logger.i("Wake word detected: $phrase (conf: $conf)");
      if (!_geminiService.isConnected) {
        _startListening(fromWakeWord: true);
      }
    };

    _wakeWordService.onInterruptDetected = (phrase) {
      logger.i("Interrupt word detected: $phrase");
      if (_isSpeaking) {
        _geminiService.interrupt();
      }
    };

    _wakeWordService.onAdmissionCommand = () {
      logger.i("Admission voice command detected!");
      _startAdmissionProcedure();
    };

    _wakeWordService.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _waveController.dispose();
    _wakeWordService.dispose();
    _geminiService.dispose();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    logger.i("Window exit requested. Cleaning up wake-word and Gemini services...");
    _wakeWordService.dispose();
    _geminiService.dispose();
    return AppExitResponse.exit;
  }

  String _cleanJunkText(String input) {
    var text = input.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');
    text = text.replaceAll('*', '');
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
        _statusText = "Say 'Sentosa' or tap mic to start";
      });
      await _geminiService.disconnect();
    } else {
      await _startListening();
    }
  }

  Future<void> _startAdmissionProcedure() async {
    setState(() {
      _showAdmissionModal = true;
    });

    if (!_geminiService.isConnected) {
      await _startListening();
    }

    if (mounted) {
      setState(() {
        _messages.add({'role': 'user', 'text': "Start Admission Procedure"});
      });
    }

    _geminiService.triggerAdmissionProcedure();
  }

  Future<void> _handleSuggestionTap(String label) async {
    if (!_isListening) {
      await _toggleListening();
    }

    final textToSend = label.replaceFirst(RegExp(r'^[^\w]+'), '').trim();

    if (mounted) {
      setState(() {
        _messages.add({'role': 'user', 'text': textToSend});
      });
    }
    _geminiService.sendTextMessage(textToSend);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isSpeaking
        ? const Color(0xFFA855F7)
        : (_isListening ? const Color(0xFF38BDF8) : const Color(0xFF10B981));

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final isCompact = screenHeight < 1180;
                final micSize = isCompact 
                    ? (screenHeight * 0.22).clamp(180.0, 240.0)
                    : 340.0;
                final gapSmall = isCompact ? 4.0 : 8.0;
                final gapMedium = isCompact ? 8.0 : 14.0;
                final gapLarge = isCompact ? 10.0 : 18.0;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isCompact ? 12 : 20,
                        24,
                        gapSmall,
                      ),
                      child: SentosaHeader(
                        isListening: _isListening,
                        isSpeaking: _isSpeaking,
                        activeColor: activeColor,
                        onAdmissionTap: _startAdmissionProcedure,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: gapSmall),
                          StatusBadge(
                            isListening: _isListening,
                            isSpeaking: _isSpeaking,
                            activeColor: activeColor,
                          ),
                          SizedBox(height: gapMedium),
                          Text(
                            "Welcome to Sentosa",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isCompact ? 28 : 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),

                          Text(
                            _statusText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isCompact ? 13.5 : 14.5,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          SizedBox(height: gapMedium),

                          MicButton(
                            size: micSize,
                            pulseAnimation: _pulseController,
                            waveAnimation: _waveController,
                            isListening: _isListening,
                            isSpeaking: _isSpeaking,
                            activeColor: activeColor,
                            onTap: _toggleListening,
                          ),

                          SizedBox(height: gapSmall),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: isCompact ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: (_isListening || _isSpeaking)
                                  ? activeColor.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_isListening || _isSpeaking)
                                    ? activeColor.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              _isSpeaking
                                  ? "Sentosa speaking • Say 'Sentosa' to interrupt"
                                  : (_isListening
                                      ? "Active conversation • Tap mic to end"
                                      : "Say 'Sentosa' or tap to speak"),
                              style: TextStyle(
                                fontSize: isCompact ? 13 : 14,
                                fontWeight: FontWeight.w700,
                                color: _isListening || _isSpeaking
                                    ? activeColor
                                    : Colors.white.withValues(alpha: 0.65),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          SizedBox(height: gapLarge),
                          AdmissionHeroCard(onTap: _startAdmissionProcedure),
                          SizedBox(height: gapLarge),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "CAMPUS SERVICES & DIRECTORY",
                                style: TextStyle(
                                  fontSize: isCompact ? 11 : 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                              Text(
                                "Tap to ask",
                                style: TextStyle(
                                  fontSize: isCompact ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: gapSmall),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 500;
                              if (isWide) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ServiceCard(
                                            title: "Library & Tech Labs",
                                            subtitle: "1st Floor • Study Pods",
                                            icon: Icons.local_library_rounded,
                                            accentColor: const Color(0xFF38BDF8),
                                            onTap: () => _handleSuggestionTap(
                                              "Where is the Library?",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ServiceCard(
                                            title: "School Hours",
                                            subtitle: "8:00 AM – 3:30 PM",
                                            icon: Icons.access_time_rounded,
                                            accentColor: const Color(0xFFFBBF24),
                                            onTap: () => _handleSuggestionTap(
                                              "What are the School Hours?",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ServiceCard(
                                            title: "Principal's Office",
                                            subtitle:
                                                "Dr. Elena Vance • Admin Wing",
                                            icon: Icons.account_balance_rounded,
                                            accentColor: const Color(0xFFA855F7),
                                            onTap: () => _handleSuggestionTap(
                                              "Where is the Principal's Office?",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ServiceCard(
                                            title: "Cafeteria & Dining",
                                            subtitle:
                                                "South Wing • Lunch Timings",
                                            icon: Icons.restaurant_rounded,
                                            accentColor: const Color(0xFF10B981),
                                            onTap: () => _handleSuggestionTap(
                                              "Where is the Cafeteria?",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ServiceCard(
                                            title: "Buses & Transport",
                                            subtitle: "Routes 1–12 • Parking",
                                            icon: Icons.directions_bus_rounded,
                                            accentColor: const Color(0xFFF43F5E),
                                            onTap: () => _handleSuggestionTap(
                                              "What are the school bus routes?",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ServiceCard(
                                            title: "Science & Art Labs",
                                            subtitle: "2nd Floor • North Wing",
                                            icon: Icons.biotech_rounded,
                                            accentColor: const Color(0xFF6366F1),
                                            onTap: () => _handleSuggestionTap(
                                              "Where are the Science Labs?",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    ServiceCard(
                                      title: "Library & Tech Labs",
                                      subtitle: "1st Floor • Study Pods",
                                      icon: Icons.local_library_rounded,
                                      accentColor: const Color(0xFF38BDF8),
                                      onTap: () => _handleSuggestionTap(
                                        "Where is the Library?",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ServiceCard(
                                      title: "School Hours",
                                      subtitle: "8:00 AM – 3:30 PM",
                                      icon: Icons.access_time_rounded,
                                      accentColor: const Color(0xFFFBBF24),
                                      onTap: () => _handleSuggestionTap(
                                        "What are the School Hours?",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ServiceCard(
                                      title: "Principal's Office",
                                      subtitle: "Dr. Elena Vance • Admin Wing",
                                      icon: Icons.account_balance_rounded,
                                      accentColor: const Color(0xFFA855F7),
                                      onTap: () => _handleSuggestionTap(
                                        "Where is the Principal's Office?",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ServiceCard(
                                      title: "Cafeteria & Dining",
                                      subtitle: "South Wing • Lunch Timings",
                                      icon: Icons.restaurant_rounded,
                                      accentColor: const Color(0xFF10B981),
                                      onTap: () => _handleSuggestionTap(
                                        "Where is the Cafeteria?",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ServiceCard(
                                      title: "Buses & Transport",
                                      subtitle: "Routes 1–12 • Parking",
                                      icon: Icons.directions_bus_rounded,
                                      accentColor: const Color(0xFFF43F5E),
                                      onTap: () => _handleSuggestionTap(
                                        "What are the school bus routes?",
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_messages.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            28,
                            gapMedium,
                            28,
                            gapSmall,
                          ),
                          child: TranscriptView(messages: _messages),
                        ),
                      )
                    else ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          28,
                          gapMedium,
                          28,
                          gapSmall,
                        ),
                        child: TranscriptView(messages: _messages),
                      ),
                      if (screenHeight > 880) const Spacer(),
                    ],

                    const KioskFooter(),
                  ],
                );
              },
            ),
          ),

          if (_showAdmissionModal)
            AdmissionModal(
              onClose: () {
                setState(() {
                  _showAdmissionModal = false;
                });
              },
            ),
        ],
      ),
    );
  }
}
