import 'package:nira/services/service.config.dart';

class GeminiConstants {
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiApiUrl =
      "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent";
  static const String geminiModel = "models/gemini-3.1-flash-live-preview";
  static String get geminiWebSocketUrl {
    if (geminiApiKey.isEmpty) {
      throw Exception(
        "GEMINI_API_KEY is not defined. Run or build with --dart-define=GEMINI_API_KEY=your_key",
      );
    }
    return "$geminiApiUrl?key=$geminiApiKey";
  }

  static const List<String> responseModalities = ["AUDIO"];
  static const String defaultVoiceName = "Aoede";
  static const int micSampleRate = 16000;
  static const int outputSampleRate = 24000;
  static const String micMimeType = "audio/pcm;rate=16000";
  static const int audioBufferThreshold = 144000;
  static const Duration acousticGracePeriod = Duration(milliseconds: 350);
  static const Duration inactivityTimeout = Duration(seconds: 15);

  static Map<String, dynamic> getSetupMessage({
    String? model,
    String? voiceName,
    String? instruction,
  }) {
    final activeModel = model ?? ConfigService().model;

    final Map<String, dynamic> generationConfig = {
      "responseModalities": responseModalities,
      "speechConfig": {
        "voiceConfig": {
          "prebuiltVoiceConfig": {
            "voiceName": voiceName ?? ConfigService().voice,
          },
        },
      },
    };

    if (activeModel.contains("gemini-3.1")) {
      generationConfig["thinkingConfig"] = {"thinkingLevel": "minimal"};
    } else if (activeModel.contains("gemini-2.5")) {
      generationConfig["thinkingConfig"] = {"thinkingBudget": 0};
    }

    return {
      "setup": {
        "model": activeModel,
        "generationConfig": generationConfig,
        "outputAudioTranscription": {},
        "systemInstruction": {
          "parts": [
            {"text": instruction ?? ConfigService().systemInstruction},
          ],
        },
      },
    };
  }
}
