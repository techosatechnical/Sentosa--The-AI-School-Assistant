import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:sentosa/helpers/constants/constants.dart';
import 'package:sentosa/helpers/data/data.sentosa.dart';
import 'package:sentosa/helpers/enums/enums.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sentosa/helpers/functions/functions.dart';
import 'package:sentosa/services/services.dart';

class GeminiService {
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _audioStreamSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final BytesBuilder _turnBuffer = BytesBuilder();
  final List<Uint8List> _playbackQueue = [];
  bool _isPlaying = false;
  bool _isModelResponding = false;
  bool _isMicrophoneLocked = false;
  int _audioChunkCount = 0;
  Timer? _inactivityTimer;
  Timer? _gracePeriodTimer;
  Timer? _audioIdleFlushTimer;

  ConversationState _conversationState = ConversationState.standby;

  Function(String)? onStatusUpdate;
  Function(String)? onTranscriptUpdate;
  Function(bool)? onSpeakingStateChanged;
  Function(ConversationState)? onConversationStateChanged;
  Function()? onTurnComplete;
  Function()? onDisconnected;

  bool get isConnected => _channel != null;
  bool get isPlaying => _isPlaying;
  ConversationState get conversationState => _conversationState;

  GeminiService() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _playNextInQueue();
    });
  }

  void _setConversationState(ConversationState state) {
    if (_conversationState != state) {
      _conversationState = state;
      logger.i("ConversationState changed: $state");
      onConversationStateChanged?.call(state);

      if (state == ConversationState.active) {
        _resetInactivityTimer();
      } else if (state == ConversationState.speaking) {
        _inactivityTimer?.cancel();
      }
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(GeminiConstants.inactivityTimeout, () {
      if (_conversationState == ConversationState.active && !_isPlaying) {
        logger.i("Inactivity timeout (${GeminiConstants.inactivityTimeout.inSeconds}s). Returning to Standby mode.");
        disconnect();
      }
    });
  }

  Future<void> connect() async {
    if (_channel != null) return;

    logger.i("Initiating Gemini Live WebSocket connection...");
    onStatusUpdate?.call("Connecting to Gemini Live...");

    final uri = Uri.parse(GeminiConstants.geminiWebSocketUrl);

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      logger.i(
        "WebSocket connection established successfully with Google Generative Language API!",
      );
    } catch (e, stack) {
      logger.e(
        "Failed to connect to Gemini WebSocket",
        error: e,
        stackTrace: stack,
      );
      onStatusUpdate?.call("Connection failed: $e");
      disconnect();
      rethrow;
    }

    final setupMessage = GeminiConstants.getSetupMessage();
    logger.i("Sending Gemini setup configuration for model: ${GeminiConstants.geminiModel}");
    _channel!.sink.add(jsonEncode(setupMessage));

    _channel!.stream.listen(
      (message) {
        _handleIncomingMessage(message);
      },
      onDone: () {
        logger.w(
          "Gemini WebSocket stream finished (onDone). CloseCode: ${_channel?.closeCode}, Reason: ${_channel?.closeReason}",
        );
        disconnect();
      },
      onError: (error) {
        logger.e("Gemini WebSocket Error", error: error);
        onStatusUpdate?.call("Connection error: $error");
        disconnect();
      },
    );

    await _startMicrophone();
    _setConversationState(ConversationState.active);
  }

  void sendTextMessage(String text) {
    if (_channel != null) {
      _isModelResponding = true;
      _isMicrophoneLocked = true;
      _gracePeriodTimer?.cancel();

      final payload = {
        "clientContent": {
          "turns": [
            {
              "role": "user",
              "parts": [
                {"text": text},
              ],
            },
          ],
          "turnComplete": true,
        },
      };
      _channel!.sink.add(jsonEncode(payload));
      logger.i("Sent text message to Gemini: $text");
      _setConversationState(ConversationState.active);
    } else {
      logger.w("Cannot send text message, Gemini channel is not connected.");
    }
  }

  Future<void> triggerAdmissionProcedure() async {
    if (!isConnected) {
      await connect();
    }
    _setConversationState(ConversationState.active);
    sendTextMessage(SentosaData.defaultAdmissionPrompt);
  }

  void interrupt() {
    if (_isPlaying || _conversationState == ConversationState.speaking || _isModelResponding) {
      logger.i("Intentional user interrupt triggered via voice command. Stopping speech immediately.");
      _audioIdleFlushTimer?.cancel();
      _gracePeriodTimer?.cancel();
      _stopPlayback();
      _isModelResponding = false;
      _isMicrophoneLocked = false;
      _setConversationState(ConversationState.active);
      onSpeakingStateChanged?.call(false);
      onStatusUpdate?.call("Listening... (Say your question)");
    }
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final String text = rawMessage is List<int>
          ? utf8.decode(rawMessage)
          : rawMessage.toString();
      final Map<String, dynamic> data = jsonDecode(text);

      if (data.containsKey('setupComplete')) {
        logger.i("Gemini session ready: setupComplete received!");
        onStatusUpdate?.call("Listening to you... (Speak naturally)");
        return;
      }

      if (data.containsKey('serverContent')) {
        final serverContent = data['serverContent'];

        if (serverContent['interrupted'] == true) {
          logger.i("Gemini server signalled interrupted.");
        }

        if (serverContent['modelTurn'] != null) {
          _isModelResponding = true;
          _isMicrophoneLocked = true;
          _gracePeriodTimer?.cancel();

          final parts = serverContent['modelTurn']['parts'] as List?;
          if (parts != null) {
            for (final part in parts) {
              if (part['text'] != null) {
                final transcript = part['text'] as String;
                logger.i("Gemini Transcript: $transcript");
                onTranscriptUpdate?.call(transcript);
              }
              if (part['inlineData'] != null &&
                  part['inlineData']['data'] != null) {
                final pcmChunk = base64Decode(
                  part['inlineData']['data'] as String,
                );
                _turnBuffer.add(pcmChunk);
                logger.d(
                  "Received audio chunk (${pcmChunk.length} bytes, total turn buffer: ${_turnBuffer.length} bytes)",
                );

                // Reset idle flush timer: if stream pauses for 750ms, flush to prevent stalling
                _audioIdleFlushTimer?.cancel();
                _audioIdleFlushTimer = Timer(const Duration(milliseconds: 750), () {
                  if (_turnBuffer.isNotEmpty && _isModelResponding) {
                    logger.i(
                      "Audio stream idle (750ms). Flushing ${_turnBuffer.length} bytes for playback.",
                    );
                    _isModelResponding = false;
                    _enqueueBufferedAudio();
                  }
                });

                // Safety flush for extremely long responses (> 10s of audio) to avoid excessive wait
                if (_turnBuffer.length >= 480000) {
                  _audioIdleFlushTimer?.cancel();
                  _enqueueBufferedAudio();
                }
              }
            }
          }
        }

        // When turnComplete arrives, flush all remaining audio immediately as a single complete WAV file
        if (serverContent['turnComplete'] == true) {
          _audioIdleFlushTimer?.cancel();
          logger.i(
            "Gemini turnComplete received. Total turn buffer: ${_turnBuffer.length} bytes",
          );
          _isModelResponding = false;
          if (_turnBuffer.isNotEmpty) {
            _enqueueBufferedAudio();
          }
          onTurnComplete?.call();
        }
      }
    } catch (e, stack) {
      logger.e("Error decoding Gemini response", error: e, stackTrace: stack);
    }
  }

  void _enqueueBufferedAudio() {
    if (_turnBuffer.isEmpty) return;
    final pcmBytes = _turnBuffer.takeBytes();
    final wavBytes = pcmToWav(pcmBytes, sampleRate: GeminiConstants.outputSampleRate);
    logger.i(
      "Packaging ${pcmBytes.length} bytes PCM into ${wavBytes.length} bytes WAV for playback",
    );
    _playbackQueue.add(wavBytes);
    if (!_isPlaying) {
      _playNextInQueue();
    }
  }

  Future<void> _playNextInQueue() async {
    if (_playbackQueue.isEmpty) {
      _isPlaying = false;
      // If Gemini has finished generating the full turn and no chunks remain
      if (!_isModelResponding && _turnBuffer.isEmpty) {
        _setConversationState(ConversationState.active);
        onSpeakingStateChanged?.call(false);
        _scheduleMicrophoneUnlock();
      }
      return;
    }

    _isPlaying = true;
    _setConversationState(ConversationState.speaking);
    onSpeakingStateChanged?.call(true);
    onStatusUpdate?.call("Sentosa Speaking... (Say 'Stop Sentosa' to interrupt)");

    final nextAudio = _playbackQueue.removeAt(0);
    try {
      logger.i("Playing audio segment (${nextAudio.length} bytes)");
      await _audioPlayer.play(BytesSource(nextAudio));
    } catch (e, stack) {
      logger.e("Error playing audio chunk", error: e, stackTrace: stack);
      _isPlaying = false;
      onSpeakingStateChanged?.call(false);
      _playNextInQueue();
    }
  }

  void _scheduleMicrophoneUnlock() {
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer(GeminiConstants.acousticGracePeriod, () {
      _isMicrophoneLocked = false;
      onStatusUpdate?.call("Listening... (Speak naturally or say 'Sentosa')");
      logger.i("Audio playback and acoustic grace period completed. Microphone unlocked.");
    });
  }

  Future<void> _stopPlayback() async {
    _audioIdleFlushTimer?.cancel();
    _gracePeriodTimer?.cancel();
    _turnBuffer.clear();
    _playbackQueue.clear();
    _isPlaying = false;
    _isModelResponding = false;
    _isMicrophoneLocked = false;
    onSpeakingStateChanged?.call(false);
    await _audioPlayer.stop();
  }

  Future<void> _startMicrophone() async {
    logger.i("Checking microphone permissions...");
    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) {
      logger.w("Microphone permission was not granted.");
      onStatusUpdate?.call("Microphone permission denied.");
      return;
    }

    logger.i("Starting ${GeminiConstants.micSampleRate}Hz PCM microphone stream...");
    try {
      final recordStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: GeminiConstants.micSampleRate,
          numChannels: 1,
        ),
      );

      _audioChunkCount = 0;
      _audioStreamSubscription = recordStream.listen((data) {
        if (_channel != null) {
          if (_isMicrophoneLocked ||
              _isPlaying ||
              _isModelResponding ||
              _playbackQueue.isNotEmpty ||
              _conversationState == ConversationState.speaking) {
            return;
          }

          _resetInactivityTimer();
          _audioChunkCount++;
          if (_audioChunkCount % 20 == 1) {
            logger.d(
              "Streaming microphone audio chunk #$_audioChunkCount (${data.length} bytes)",
            );
          }
          final base64Audio = base64Encode(data);
          final payload = {
            "realtimeInput": {
              "mediaChunks": [
                {"mimeType": GeminiConstants.micMimeType, "data": base64Audio},
              ],
            },
          };
          _channel!.sink.add(jsonEncode(payload));
        }
      });

      logger.i("Microphone streaming active!");
      onStatusUpdate?.call("Listening... (Speak naturally)");
    } catch (e, stack) {
      logger.e(
        "Failed to start microphone stream",
        error: e,
        stackTrace: stack,
      );
      onStatusUpdate?.call("Microphone error: $e");
    }
  }

  Future<void> disconnect() async {
    logger.i("Disconnecting GeminiService session...");
    _inactivityTimer?.cancel();
    _gracePeriodTimer?.cancel();
    await _stopPlayback();
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isModelResponding = false;
    _isMicrophoneLocked = false;
    _setConversationState(ConversationState.standby);
    onSpeakingStateChanged?.call(false);
    onStatusUpdate?.call("Say 'Sentosa' or tap mic");
    onDisconnected?.call();
    logger.i("GeminiService disconnected (Standby).");
  }

  void dispose() {
    _audioIdleFlushTimer?.cancel();
    _inactivityTimer?.cancel();
    _gracePeriodTimer?.cancel();
    disconnect();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
  }
}
