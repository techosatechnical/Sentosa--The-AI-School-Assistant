import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

// ============================================================================
// WAV HEADER UTILITY
// ============================================================================

/// Converts raw PCM 16-bit mono audio bytes into a standard playable WAV container.
Uint8List pcmToWav(
  Uint8List pcmBytes, {
  int sampleRate = 24000,
  int numChannels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final totalDataLen = pcmBytes.length;
  final totalAudioLen = totalDataLen + 36;

  final header = ByteData(44);
  header.setUint8(0, 0x52); // 'R'
  header.setUint8(1, 0x49); // 'I'
  header.setUint8(2, 0x46); // 'F'
  header.setUint8(3, 0x46); // 'F'
  header.setUint32(4, totalAudioLen, Endian.little);
  header.setUint8(8, 0x57); // 'W'
  header.setUint8(9, 0x41); // 'A'
  header.setUint8(10, 0x56); // 'V'
  header.setUint8(11, 0x45); // 'E'

  header.setUint8(12, 0x66); // 'f'
  header.setUint8(13, 0x6D); // 'm'
  header.setUint8(14, 0x74); // 't'
  header.setUint8(15, 0x20); // ' '
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM format
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  header.setUint8(36, 0x64); // 'd'
  header.setUint8(37, 0x61); // 'a'
  header.setUint8(38, 0x74); // 't'
  header.setUint8(39, 0x61); // 'a'
  header.setUint32(40, totalDataLen, Endian.little);

  final wavBytes = Uint8List(44 + totalDataLen);
  wavBytes.setRange(0, 44, header.buffer.asUint8List());
  wavBytes.setRange(44, 44 + totalDataLen, pcmBytes);
  return wavBytes;
}

// ============================================================================
// AUDIO GENERATION METHODS
// ============================================================================

/// Method 1: Generates speech using the Gemini Live Bidirectional WebSocket API.
Future<bool> generateViaWebSocket(
  String apiKey,
  String model,
  String prompt,
  String voiceName,
  File outputFile,
) async {
  final completer = Completer<bool>();
  final uri = Uri.parse(
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
  );

  WebSocket ws;
  try {
    ws = await WebSocket.connect(
      uri.toString(),
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('  [WebSocket] Connection error: $e');
    return false;
  }

  final pcmBuffer = BytesBuilder();
  StreamSubscription? sub;

  sub = ws.listen(
    (event) {
      try {
        final text = event is List<int> ? utf8.decode(event) : event.toString();
        final data = jsonDecode(text);

        if (data.containsKey('setupComplete')) {
          final turn = {
            'clientContent': {
              'turns': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'turnComplete': true,
            },
          };
          ws.add(jsonEncode(turn));
          return;
        }

        if (data.containsKey('serverContent')) {
          final serverContent = data['serverContent'];
          if (serverContent['modelTurn'] != null) {
            final parts = serverContent['modelTurn']['parts'] as List?;
            if (parts != null) {
              for (final part in parts) {
                if (part['inlineData'] != null &&
                    part['inlineData']['data'] != null) {
                  final pcm = base64Decode(
                    part['inlineData']['data'] as String,
                  );
                  pcmBuffer.add(pcm);
                }
              }
            }
          }

          if (serverContent['turnComplete'] == true) {
            if (pcmBuffer.isNotEmpty) {
              final pcmBytes = pcmBuffer.takeBytes();
              final wavBytes = pcmToWav(pcmBytes, sampleRate: 24000);
              outputFile.writeAsBytesSync(wavBytes);
              if (!completer.isCompleted) completer.complete(true);
            } else {
              if (!completer.isCompleted) completer.complete(false);
            }
            try {
              ws.close();
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('  [WebSocket] Decode error: $e');
      }
    },
    onError: (err) {
      debugPrint('  [WebSocket] Stream error: $err');
      if (!completer.isCompleted) completer.complete(false);
    },
    onDone: () {
      if (!completer.isCompleted) completer.complete(pcmBuffer.isNotEmpty);
    },
  );

  final setup = {
    'setup': {
      'model': model,
      'generationConfig': {
        'responseModalities': ['AUDIO'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': voiceName},
          },
        },
      },
    },
  };
  ws.add(jsonEncode(setup));

  try {
    return await completer.future.timeout(const Duration(seconds: 30));
  } catch (e) {
    debugPrint('  [WebSocket] Timeout waiting for audio: $e');
    try {
      await ws.close();
    } catch (_) {}
    return false;
  } finally {
    await sub.cancel();
  }
}

/// Method 2: Generates speech using the Gemini REST generateContent API.
Future<bool> generateViaRest(
  String apiKey,
  String model,
  String prompt,
  String voiceName,
  File outputFile,
) async {
  try {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['AUDIO'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': voiceName},
          },
        },
      },
    };

    final request = await HttpClient().postUrl(url);
    request.headers.set('Content-Type', 'application/json');
    request.add(utf8.encode(jsonEncode(payload)));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final parts = data['candidates']?[0]?['content']?['parts'] as List?;
      if (parts != null) {
        for (final part in parts) {
          if (part['inlineData'] != null &&
              part['inlineData']['data'] != null) {
            final audioBase64 = part['inlineData']['data'];
            final mimeType = (part['inlineData']['mimeType'] as String?) ?? '';
            final rawBytes = base64Decode(audioBase64);
            if (mimeType.contains('pcm')) {
              outputFile.writeAsBytesSync(
                pcmToWav(rawBytes, sampleRate: 24000),
              );
            } else {
              outputFile.writeAsBytesSync(rawBytes);
            }
            return true;
          }
        }
      }
      debugPrint(
        '  [REST] 200 OK received but no audio inlineData found. Response text: $responseBody',
      );
    } else {
      debugPrint('  [REST] HTTP ${response.statusCode}: $responseBody');
    }
  } catch (e) {
    debugPrint('  [REST] Request error: $e');
  }
  return false;
}

// ============================================================================
// MAIN ENTRYPOINT
// ============================================================================

void main(List<String> args) async {
  String apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty && args.isNotEmpty) {
    apiKey = args[0].trim();
  }

  if (apiKey.isEmpty) {
    debugPrint('================================================================');
    debugPrint('Error: GEMINI_API_KEY is missing.');
    debugPrint('You can run this script in either of these ways:');
    debugPrint('  1) dart run generate_audio_assets.dart YOUR_API_KEY');
    debugPrint(
      '  2) dart run --define=GEMINI_API_KEY=YOUR_API_KEY generate_audio_assets.dart',
    );
    debugPrint('================================================================');
    return;
  }

  final prompts = [
    "Speak in natural and warm Malayalam. Say exactly: 'നിർമ്മല ഭവൻ ഹയർ സെക്കൻഡറി സ്കൂളിലേക്ക് ഹൃദ്യമായ സ്വാഗതം! രജിസ്ട്രേഷൻ വിജയകരമായി പൂർത്തിയായിരിക്കുന്നു.'",
    "Speak in friendly and enthusiastic Malayalam. Say exactly: 'നിർമ്മല ഭവൻ ഹയർ സെക്കൻഡറി സ്കൂളിലേക്ക് സ്വാഗതം! ഞങ്ങളുടെ വിദ്യാലയത്തിലേക്ക് താങ്കളെ സന്തോഷത്തോടെ സ്വീകരിക്കുന്നു.'",
    "Speak in polite and welcoming Malayalam. Say exactly: 'നമസ്കാരം! നിർമ്മല ഭവൻ ഹയർ സെക്കൻഡറി സ്കൂളിലേക്ക് സ്നേഹപൂർവ്വം സ്വാഗതം. താങ്കളുടെ അഡ്മിഷൻ വിവരങ്ങൾ രേഖപ്പെടുത്തിയിട്ടുണ്ട്.'",
    "Speak in joyful and encouraging Malayalam. Say exactly: 'നിർമ്മല ഭവൻ സ്കൂൾ തിരഞ്ഞെടുത്തതിന് നന്ദി. ശോഭനമായ ഒരു പഠനകാലം ആശംസിക്കുന്നു, സ്വാഗതം!'",
    "Speak in warm and gentle Malayalam. Say exactly: 'നിർമ്മല ഭവൻ ഹയർ സെക്കൻഡറി സ്കൂളിലേക്ക് ഹൃദ്യമായ സ്വാഗതം! പുതിയ അധ്യയന വർഷത്തിലേക്ക് എല്ലാവിധ ഭാവുകങ്ങളും നേരുന്നു.'",
  ];

  final outputDir = Directory('assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  debugPrint(
    'Starting generation of 5 audio greetings using Gemini (Voice: Aoede)...',
  );

  for (int i = 0; i < prompts.length; i++) {
    final fileName = 'greeting_${i + 1}.wav';
    final targetFile = File('assets/audio/$fileName');
    debugPrint('\n[${i + 1}/${prompts.length}] Generating $fileName...');

    // Method 1: WebSocket with native audio model (same as Sentosa kiosk Gemini Live)
    debugPrint(
      '  Attempting via Gemini Live WebSocket (models/gemini-2.5-flash-native-audio-latest)...',
    );
    bool success = await generateViaWebSocket(
      apiKey,
      'models/gemini-2.5-flash-native-audio-latest',
      prompts[i],
      'Aoede',
      targetFile,
    );

    // Method 2: If WebSocket failed, try REST with gemini-3.6-flash
    if (!success) {
      debugPrint(
        '  WebSocket did not return audio. Falling back to REST (models/gemini-3.6-flash)...',
      );
      success = await generateViaRest(
        apiKey,
        'gemini-3.6-flash',
        prompts[i],
        'Aoede',
        targetFile,
      );
    }

    if (success && targetFile.existsSync() && targetFile.lengthSync() > 0) {
      debugPrint(
        '  SUCCESS: Saved assets/audio/$fileName (${targetFile.lengthSync()} bytes)',
      );
    } else {
      debugPrint('  FAILED: Could not generate audio for greeting ${i + 1}.');
    }

    // Small delay between requests
    await Future.delayed(const Duration(seconds: 1));
  }

  debugPrint('\n--------------------------------------------------------------');
  debugPrint('Completed processing greetings.');
  final files = outputDir.listSync().whereType<File>().toList();
  debugPrint(
    'Files currently in assets/audio: ${files.map((f) => f.uri.pathSegments.last).toList()}',
  );
  debugPrint('--------------------------------------------------------------');
}
