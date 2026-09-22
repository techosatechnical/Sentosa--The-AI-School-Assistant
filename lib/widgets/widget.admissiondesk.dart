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
  final TextEditingController _ageController = TextEditingController();
  String _selectedClass = 'Grade 1';
  final TextEditingController _phoneController = TextEditingController();
  String? _photoPath;

  // Focus Nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
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
    _ageController.addListener(() => setState(() {}));
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
    _ageController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _ageFocus.dispose();
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Auto focus logic
      if (_currentStep == 0) _nameFocus.requestFocus();
      if (_currentStep == 1) _ageFocus.requestFocus();
      if (_currentStep == 2) _phoneFocus.requestFocus();

      if (_currentStep == 3) {
        _progressController.forward();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _cameraId < 0) return;
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
      _photoPath = file.path;
      _isCapturing = false;
      _nextStep(); // Proceed to review step
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
        'name': _nameController.text,
        'age': _ageController.text,
        'className': _selectedClass,
        'phone': _phoneController.text,
        'photoPath': _photoPath,
      });

      if (mounted) {
        // Play random local audio non-blockingly
        _playRandomLocalGreeting();

        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.celebration,
                    color: Colors.orangeAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Sentosa!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Registration successful for ${_nameController.text}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        );

        // Auto close after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
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
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Next', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildStepAgeClass() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Age and Class",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ageController,
            focusNode: _ageFocus,
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: "ENTER AGE",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _classOptions
                .map(
                  (c) => ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 16)),
                    selected: _selectedClass == c,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedClass = c);
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _ageController.text.trim().isNotEmpty ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPhone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Contact Phone Number",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          style: const TextStyle(fontSize: 24),
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
        const Spacer(),
        ElevatedButton(
          onPressed: _phoneController.text.trim().length == 10
              ? _nextStep
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Ready for Photo', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildStepCamera() {
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
                        Colors.greenAccent,
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
        _buildReviewRow("Age", _ageController.text),
        _buildReviewRow("Class", _selectedClass),
        _buildReviewRow("Phone", _phoneController.text),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _registerAdmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(32),
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.blueAccent),
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
                  _buildStepAgeClass(),
                  _buildStepPhone(),
                  _buildStepCamera(),
                  _buildStepReview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
