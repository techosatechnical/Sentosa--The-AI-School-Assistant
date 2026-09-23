import 'dart:async';
import 'dart:io';
import 'dart:math' as java_math;
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audioplayers/audioplayers.dart';
import '../services/service.admission.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class AdmissionAssistantDialog extends StatefulWidget {
  const AdmissionAssistantDialog({super.key});

  @override
  State<AdmissionAssistantDialog> createState() =>
      _AdmissionAssistantDialogState();
}

class _AdmissionAssistantDialogState extends State<AdmissionAssistantDialog>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Data
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDob;
  String? _selectedGender;
  String _selectedClass = 'Grade 1';
  final TextEditingController _phoneController = TextEditingController();
  String? _photoPath;

  // Focus Nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  // Camera
  int _cameraId = -1;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  // Animation for Camera Frame
  late AnimationController _progressController;

  final List<String> _classOptions = List.generate(
    12,
    (index) => 'Grade ${index + 1}',
  );

  // Audio Player for Success Greeting
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _formatDate(DateTime date) {
    final months = [
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _initCamera();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCapturing) {
        _capturePhoto();
      }
    });

    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await CameraPlatform.instance.availableCameras();
      debugPrint("Available cameras: ${cameras.map((c) => c.name).toList()}");

      final targetCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.external,
        orElse: () => cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        ),
      );

      debugPrint("Selected camera: ${targetCamera.name}");

      _cameraId = await CameraPlatform.instance.createCameraWithSettings(
        targetCamera,
        const MediaSettings(
          resolutionPreset: ResolutionPreset.max,
          enableAudio: false,
        ),
      );

      await CameraPlatform.instance.initializeCamera(_cameraId);
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    if (_cameraId >= 0) {
      CameraPlatform.instance.dispose(_cameraId);
    }
    _progressController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );

      // Auto focus logic
      if (_currentStep == 0) _nameFocus.requestFocus();
      if (_currentStep == 1) FocusScope.of(context).unfocus();
      if (_currentStep == 2) _phoneFocus.requestFocus();
      if (_currentStep == 3) {
        FocusScope.of(context).unfocus();
        _progressController.forward();
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _cameraId < 0) return;
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
      setState(() {
        _photoPath = file.path;
        _isCapturing = false;
      });
    } catch (e) {
      debugPrint("Error capturing photo: $e");
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _playRandomLocalGreeting() async {
    try {
      final random = java_math.Random();
      final index = random.nextInt(5) + 1; // 1 to 5
      await _audioPlayer.play(AssetSource('audio/greeting_$index.wav'));
    } catch (e) {
      debugPrint("Greeting Audio Failed (Non-blocking): $e");
    }
  }

  Future<void> _registerAdmission() async {
    try {
      await AdmissionDbService().insertAdmission({
        'name': _nameController.text.trim(),
        'dob': _selectedDob != null ? _formatDate(_selectedDob!) : '',
        'gender': _selectedGender ?? '',
        'className': _selectedClass,
        'phone': _phoneController.text.trim(),
        'photoPath': _photoPath,
      });

      if (mounted) {
        _playRandomLocalGreeting();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.5),
                        width: 4,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.elasticOut,
                          builder: (context, iconScale, child) {
                            return Transform.scale(
                              scale: iconScale,
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.orangeAccent,
                                size: 100,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'YAY! Welcome!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_nameController.text} is now part of Nirmala Bhavan Higher Secondary School!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Get ready for a fun adventure! 🚀',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );

        // Auto close after 11 seconds to allow audio to finish playing
        Future.delayed(const Duration(seconds: 11), () {
          if (mounted) {
            Navigator.of(context).pop(); // Close success
            Navigator.of(context).pop(); // Close admission dialog
          }
        });
      }
    } catch (e) {
      debugPrint("Registration error: $e");
    }
  }

  Widget _buildStepName() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "What is the student's name?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
            UpperCaseTextFormatter(),
          ],
          style: const TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: "ENTER NAME",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _nameController.text.trim().isNotEmpty ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Next', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildStepDobAndGender() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Date of Birth & Gender",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Please select the student's birth date and gender",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "DATE OF BIRTH",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final initial =
                  _selectedDob ?? DateTime(DateTime.now().year - 6, 1, 1);
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(DateTime.now().year - 25),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Colors.blueAccent,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDob = picked;
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedDob != null
                      ? Colors.blueAccent
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: _selectedDob != null
                        ? Colors.blueAccent
                        : Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _selectedDob != null
                        ? _formatDate(_selectedDob!)
                        : "SELECT DATE OF BIRTH",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: _selectedDob != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _selectedDob != null
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.grey[600],
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "GENDER",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 0.8,
              ),
            ),
          ),
          Row(
            children: [
              _buildGenderOption('Male', Icons.male_rounded),
              const SizedBox(width: 12),
              _buildGenderOption('Female', Icons.female_rounded),
            ],
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: (_selectedDob != null && _selectedGender != null)
                ? _nextStep
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, IconData icon) {
    final isSelected = _selectedGender == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGender = label;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDBEAFC) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blueAccent : Colors.grey[600],
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.blueAccent : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepClassAndPhone() {
    final isPhoneValid = _phoneController.text.trim().length == 10;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Class & Contact Phone",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "SELECT GRADE / CLASS",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _classOptions
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 14)),
                      selected: _selectedClass == c,
                      selectedColor: const Color(0xFFDBEAFC),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedClass = c);
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "CONTACT PHONE NUMBER",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            style: const TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: "ENTER 10-DIGIT PHONE",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isPhoneValid ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Ready for Photo',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCamera() {
    if (_photoPath != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Looking good!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ClipOval(
            child: Image.file(
              File(_photoPath!),
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _photoPath = null;
                    _progressController.reset();
                    _progressController.forward();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Recapture', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Look at the camera!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        if (!_isCameraInitialized)
          const CircularProgressIndicator()
        else
          Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CameraPlatform.instance.buildPreview(_cameraId),
                ),
              ),
              SizedBox(
                width: 320,
                height: 320,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _progressController.value,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: 32),
        Text(
          _isCapturing ? "Capturing..." : "Hold still...",
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStepReview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          "Review Details",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (_photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(_photoPath!),
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 24),
        _buildReviewRow("Name", _nameController.text),
        _buildReviewRow(
          "Date of Birth",
          _selectedDob != null ? _formatDate(_selectedDob!) : "-",
        ),
        _buildReviewRow("Gender", _selectedGender ?? "-"),
        _buildReviewRow("Class", _selectedClass),
        _buildReviewRow("Phone", _phoneController.text),
        const Spacer(),
        ElevatedButton(
          onPressed: _registerAdmission,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Register',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 650,
        height: 700,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              spreadRadius: 8,
            ),
          ],
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
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFCCFBF1).withValues(alpha: 0.35),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Admission Assistant",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStepName(),
                        _buildStepDobAndGender(),
                        _buildStepClassAndPhone(),
                        _buildStepCamera(),
                        _buildStepReview(),
                      ],
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
