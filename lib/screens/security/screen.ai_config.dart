import 'package:flutter/material.dart';
import 'package:sentosa/services/service.config.dart';
import 'package:sentosa/screens/security/screen.system_instructions.dart';
import 'package:sentosa/screens/security/screen.pin_entry.dart';
import 'package:sentosa/widgets/widget.toast.dart';

class AiConfigScreen extends StatefulWidget {
  const AiConfigScreen({super.key});

  @override
  State<AiConfigScreen> createState() => _AiConfigScreenState();
}

class _VoiceCardItem {
  final String name;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
  final Color borderColor;
  final Color selectedBgColor;

  const _VoiceCardItem({
    required this.name,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
    required this.borderColor,
    required this.selectedBgColor,
  });
}

class _AiConfigScreenState extends State<AiConfigScreen> {
  final ConfigService _config = ConfigService();
  late String _selectedVoice;
  late String _selectedModel;

  final List<_VoiceCardItem> _voices = const [
    _VoiceCardItem(
      name: 'Aoede',
      title: 'Aoede',
      subtitle: 'Harmonious & melodic',
      icon: Icons.music_note_rounded,
      primaryColor: Color(0xFF6366F1),
      bgColor: Color(0xFFEEF2FF),
      borderColor: Color(0xFFE0E7FF),
      selectedBgColor: Color(0xFFE0E7FF),
    ),
    _VoiceCardItem(
      name: 'Kore',
      title: 'Kore',
      subtitle: 'Gentle & serene',
      icon: Icons.spa_rounded,
      primaryColor: Color(0xFF0284C7),
      bgColor: Color(0xFFE0F2FE),
      borderColor: Color(0xFFBAE6FD),
      selectedBgColor: Color(0xFFBAE6FD),
    ),
    _VoiceCardItem(
      name: 'Leda',
      title: 'Leda',
      subtitle: 'Warm & conversational',
      icon: Icons.record_voice_over_rounded,
      primaryColor: Color(0xFF10B981),
      bgColor: Color(0xFFECFDF5),
      borderColor: Color(0xFFA7F3D0),
      selectedBgColor: Color(0xFFA7F3D0),
    ),
    _VoiceCardItem(
      name: 'Capella',
      title: 'Capella',
      subtitle: 'Bright & articulate',
      icon: Icons.auto_awesome_rounded,
      primaryColor: Color(0xFFF59E0B),
      bgColor: Color(0xFFFFFBEB),
      borderColor: Color(0xFFFDE68A),
      selectedBgColor: Color(0xFFFDE68A),
    ),
    _VoiceCardItem(
      name: 'Eclipse',
      title: 'Eclipse',
      subtitle: 'Calm & expressive',
      icon: Icons.dark_mode_rounded,
      primaryColor: Color(0xFF8B5CF6),
      bgColor: Color(0xFFF5F3FF),
      borderColor: Color(0xFFDDD6FE),
      selectedBgColor: Color(0xFFDDD6FE),
    ),
    _VoiceCardItem(
      name: 'Lyra',
      title: 'Lyra',
      subtitle: 'Crisp & energetic',
      icon: Icons.graphic_eq_rounded,
      primaryColor: Color(0xFFEC4899),
      bgColor: Color(0xFFFDF2F8),
      borderColor: Color(0xFFFBCFE8),
      selectedBgColor: Color(0xFFFBCFE8),
    ),
    _VoiceCardItem(
      name: 'Ursa',
      title: 'Ursa',
      subtitle: 'Confident & composed',
      icon: Icons.waves_rounded,
      primaryColor: Color(0xFF14B8A6),
      bgColor: Color(0xFFF0FDFA),
      borderColor: Color(0xFF99F6E4),
      selectedBgColor: Color(0xFF99F6E4),
    ),
    _VoiceCardItem(
      name: 'Vega',
      title: 'Vega',
      subtitle: 'Radiant & natural',
      icon: Icons.flare_rounded,
      primaryColor: Color(0xFF3B82F6),
      bgColor: Color(0xFFEFF6FF),
      borderColor: Color(0xFFBFDBFE),
      selectedBgColor: Color(0xFFBFDBFE),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedVoice = _config.voice;
    _selectedModel = _config.model;
  }

  Future<void> _selectVoice(String voiceName) async {
    if (_selectedVoice == voiceName) return;
    setState(() {
      _selectedVoice = voiceName;
    });
    await _config.setAiConfig(
      voice: _selectedVoice,
      model: _selectedModel,
      systemInstruction: _config.systemInstruction,
    );
    _showFeedbackToast('Voice changed to $voiceName');
  }

  Future<void> _selectModel(String modelId) async {
    if (_selectedModel == modelId) return;
    setState(() {
      _selectedModel = modelId;
    });
    await _config.setAiConfig(
      voice: _selectedVoice,
      model: _selectedModel,
      systemInstruction: _config.systemInstruction,
    );
    final shortName = modelId.contains('3.1')
        ? 'Techosa 3.1 Flash'
        : 'Techosa 2.5 Live';
    _showFeedbackToast('Model switched to $shortName');
  }

  void _showFeedbackToast(String message) {
    SentosaToast.show(context: context, message: message, isError: false);
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
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PinEntryScreen()),
                );
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "AI Config Mode",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2942),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCard(_VoiceCardItem voice) {
    final isSelected = _selectedVoice.toLowerCase() == voice.name.toLowerCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectVoice(voice.name),
        borderRadius: BorderRadius.circular(20),
        splashColor: voice.primaryColor.withValues(alpha: 0.18),
        highlightColor: voice.selectedBgColor.withValues(alpha: 0.6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? voice.selectedBgColor : voice.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? voice.primaryColor : voice.borderColor,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? voice.primaryColor.withValues(alpha: 0.15)
                    : const Color(0xFF0F2942).withValues(alpha: 0.04),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: voice.primaryColor.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        voice.icon,
                        color: voice.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      voice.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F2942),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voice.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? voice.primaryColor : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? voice.primaryColor
                          : voice.borderColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? voice.primaryColor.withValues(alpha: 0.4)
                            : Colors.transparent,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 15,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoicesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 600 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _voices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            return _buildVoiceCard(_voices[index]);
          },
        );
      },
    );
  }

  Widget _buildModelCard({
    required String modelId,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color primaryColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    final isSelected = _selectedModel == modelId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectModel(modelId),
        borderRadius: BorderRadius.circular(22),
        splashColor: primaryColor.withValues(alpha: 0.18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? primaryColor : borderColor,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.12)
                    : const Color(0xFF0F2942).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : bgColor,
                  border: Border.all(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.3)
                        : borderColor,
                  ),
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F2942),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primaryColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 15,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SystemInstructionScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9FF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2942).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEDE9FE),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Instructions",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F2942),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "View and edit agent prompt directives & persona in locked Markdown.",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F3FD), Color(0xFFDBEDFD)],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFBAE6FD).withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.tune_rounded, size: 22, color: Color(0xFF1E40AF)),
                SizedBox(width: 10),
                Text(
                  "Intelligent Campus Assistant",
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
                  "Zero Latency Engine",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNav(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.settings_suggest_rounded,
                                color: Color(0xFF0284C7),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "AI Configuration",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F2942),
                                letterSpacing: -0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Configure Gemini Live voice, engine model, and prompt instructions.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          icon: Icons.record_voice_over_rounded,
                          iconColor: const Color(0xFF0284C7),
                          iconBg: const Color(0xFFE0F2FE),
                          title: "Voices",
                          subtitle:
                              "Select one of the 8 natural voices for real-time speech output.",
                        ),
                        const SizedBox(height: 14),
                        _buildVoicesGrid(),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          icon: Icons.memory_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFECFDF5),
                          title: "Model",
                          subtitle:
                              "Choose the generative AI engine for real-time multimodal interaction.",
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 700;
                            final card1 = _buildModelCard(
                              modelId: 'models/gemini-3.1-flash-live-preview',
                              title: "Techosa 3.1",
                              subtitle:
                                  "Thinking Level • Next-gen speed & quality",
                              badge: "Default",
                              icon: Icons.bolt_rounded,
                              primaryColor: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFF0F9FF),
                              borderColor: const Color(0xFFBAE6FD),
                            );
                            final card2 = _buildModelCard(
                              modelId:
                                  'models/gemini-2.5-flash-native-audio-latest',
                              title: "Techosa 2.5",
                              subtitle:
                                  "Thinking Budget • Native audio legacy model",
                              badge: "Legacy",
                              icon: Icons.history_rounded,
                              primaryColor: const Color(0xFF10B981),
                              bgColor: const Color(0xFFF0FDF4),
                              borderColor: const Color(0xFFBBF7D0),
                            );

                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(child: card1),
                                  const SizedBox(width: 14),
                                  Expanded(child: card2),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  card1,
                                  const SizedBox(height: 12),
                                  card2,
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          icon: Icons.psychology_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          iconBg: const Color(0xFFEDE9FE),
                          title: "System Instructions",
                          subtitle:
                              "Manage agent instructions, persona, and contextual knowledge.",
                        ),
                        const SizedBox(height: 14),
                        _buildInstructionsCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPersistentBottomBar(),
    );
  }
}
