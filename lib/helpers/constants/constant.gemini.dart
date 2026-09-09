import 'package:sentosa/helpers/data/data.sentosa.dart';

class GeminiConstants {
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiApiUrl =
      "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent";
  static const String geminiModel =
      "models/gemini-2.5-flash-native-audio-latest";
  static String get geminiWebSocketUrl {
    if (geminiApiKey.isEmpty) {
      throw Exception(
        "GEMINI_API_KEY is not defined. Run or build with --dart-define=GEMINI_API_KEY=your_key",
      );
    }
    return "$geminiApiUrl?key=$geminiApiKey";
  }
  static const List<String> responseModalities = ["AUDIO"];
  static const String defaultVoiceName = "Puck";
  static const int micSampleRate = 16000;
  static const int outputSampleRate = 24000;
  static const String micMimeType = "audio/pcm;rate=16000";
  static const int audioBufferThreshold = 96000; 
  static const Duration inactivityTimeout = Duration(seconds: 15);

  static Map<String, dynamic> getSetupMessage({
    String model = geminiModel,
    String voiceName = defaultVoiceName,
    String instruction = SentosaData.systemInstruction,
  }) {
    return {
      "setup": {
        "model": model,
        "generationConfig": {
          "responseModalities": responseModalities,
          "speechConfig": {
            "voiceConfig": {
              "prebuiltVoiceConfig": {"voiceName": voiceName},
            },
          },
        },
        "systemInstruction": {
          "parts": [
            {"text": instruction},
          ],
        },
      },
    };
  }
}
