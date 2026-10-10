import 'dart:async';
import 'dart:convert';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';
import 'package:nira/helpers/constants/constants.dart';
import 'package:nira/helpers/enums/enums.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nira/services/services.dart';

class GeminiService {
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _audioStreamSubscription;
  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _activeStream;
  SoundHandle? _activeSoundHandle;

  bool _isPlaying = false;
  bool _isModelResponding = false;
  bool _isMicrophoneLocked = false;
  bool _hasUserSpoken = false;
  int _audioChunkCount = 0;
  Timer? _inactivityTimer;
  Timer? _gracePeriodTimer;
  Timer? _silenceTimer;
  StreamSubscription? _amplitudeSubscription;

  ConversationState _conversationState = ConversationState.standby;

  Function(String)? onStatusUpdate;
  Function(String)? onTranscriptUpdate;
  Function(bool)? onSpeakingStateChanged;
  Function(ConversationState)? onConversationStateChanged;
  Function(double)? onAmplitudeUpdate;
  Function()? onTurnComplete;
  Function()? onDisconnected;

  bool get isConnected => _channel != null;
  bool get isPlaying => _isPlaying;
  ConversationState get conversationState => _conversationState;

  GeminiService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _soloud.init();
      logger.i("SoLoud engine initialized successfully");
    } catch (e, stack) {
      logger.e("Failed to initialize SoLoud", error: e, stackTrace: stack);
    }
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
        logger.i(
          "Inactivity timeout (${GeminiConstants.inactivityTimeout.inSeconds}s). Returning to Standby mode.",
        );
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
    logger.i(
      "Sending Gemini setup configuration for model: ${GeminiConstants.geminiModel}",
    );
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

  void interrupt() {
    if (_isPlaying ||
        _conversationState == ConversationState.speaking ||
        _isModelResponding) {
      logger.i(
        "Intentional user interrupt triggered via voice command. Stopping speech immediately.",
      );
      _gracePeriodTimer?.cancel();
      _stopPlayback();
      _isModelResponding = false;
      _isMicrophoneLocked = false;
      _setConversationState(ConversationState.active);
      onSpeakingStateChanged?.call(false);
      onStatusUpdate?.call("Listening... (Say your question)");
    }
  }

  Future<void> _handleIncomingMessage(dynamic rawMessage) async {
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

        String? outputTranscriptionText;
        if (serverContent['outputTranscription'] != null &&
            serverContent['outputTranscription']['text'] != null) {
          outputTranscriptionText =
              serverContent['outputTranscription']['text'] as String;
        } else if (serverContent['outputAudioTranscription'] != null &&
            serverContent['outputAudioTranscription']['text'] != null) {
          outputTranscriptionText =
              serverContent['outputAudioTranscription']['text'] as String;
        }

        if (outputTranscriptionText != null &&
            outputTranscriptionText.isNotEmpty) {
          logger.i("Gemini Spoken Transcription: $outputTranscriptionText");
          onTranscriptUpdate?.call(outputTranscriptionText);
        }

        if (serverContent['modelTurn'] != null) {
          _isModelResponding = true;
          _isMicrophoneLocked = true;
          _gracePeriodTimer?.cancel();

          final parts = serverContent['modelTurn']['parts'] as List?;
          if (parts != null) {
            for (final part in parts) {
              final isThought = part['thought'] == true;
              if (part['text'] != null &&
                  !isThought &&
                  outputTranscriptionText == null) {
                final transcript = part['text'] as String;
                logger.i("Gemini Spoken Text Part: $transcript");
                onTranscriptUpdate?.call(transcript);
              }
              if (part['inlineData'] != null &&
                  part['inlineData']['data'] != null) {
                final pcmChunk = base64Decode(
                  part['inlineData']['data'] as String,
                );
                if (_activeStream == null) {
                  try {
                    _activeStream = _soloud.setBufferStream(
                      sampleRate: GeminiConstants.outputSampleRate,
                      channels: Channels.mono,
                      format: BufferType.s16le,
                      bufferingType: BufferingType.released,
                    );
                    _soloud.addAudioDataStream(_activeStream!, pcmChunk);

                    _activeSoundHandle = _soloud.play(_activeStream!);
                    _isPlaying = true;
                    _setConversationState(ConversationState.speaking);
                    onSpeakingStateChanged?.call(true);
                    onStatusUpdate?.call(
                      "NIRA AI Speaking... (Say 'Stop Nira' to interrupt)",
                    );
                    logger.i("Started SoLoud buffer stream playback.");
                  } catch (e, stack) {
                    logger.e(
                      "Failed to setup SoLoud buffer stream",
                      error: e,
                      stackTrace: stack,
                    );
                  }
                } else {
                  _soloud.addAudioDataStream(_activeStream!, pcmChunk);
                }
              }
            }
          }
        }

        if (serverContent['turnComplete'] == true) {
          logger.i("Gemini turnComplete received.");
          _isModelResponding = false;
          if (_activeStream != null) {
            _soloud.setDataIsEnded(_activeStream!);
            _waitForPlaybackToFinish();
          } else {
            _scheduleMicrophoneUnlock();
          }
          onTurnComplete?.call();
        }
      }
    } catch (e, stack) {
      logger.e("Error decoding Gemini response", error: e, stackTrace: stack);
    }
  }

  void _waitForPlaybackToFinish() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_activeSoundHandle == null ||
          !_soloud.getIsValidVoiceHandle(_activeSoundHandle!)) {
        timer.cancel();
        _isPlaying = false;
        _activeStream = null;
        _activeSoundHandle = null;
        _setConversationState(ConversationState.active);
        onSpeakingStateChanged?.call(false);
        _scheduleMicrophoneUnlock();
      }
    });
  }

  void _scheduleMicrophoneUnlock() {
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer(GeminiConstants.acousticGracePeriod, () {
      _isMicrophoneLocked = false;
      onStatusUpdate?.call("Listening... (Speak naturally or say 'Nira')");
      logger.i(
        "Audio playback and acoustic grace period completed. Microphone unlocked.",
      );
    });
  }

  Future<void> _stopPlayback() async {
    _gracePeriodTimer?.cancel();
    _isPlaying = false;
    _isModelResponding = false;
    _isMicrophoneLocked = false;
    onSpeakingStateChanged?.call(false);

    if (_activeSoundHandle != null) {
      _soloud.stop(_activeSoundHandle!);
      _activeSoundHandle = null;
    }
    if (_activeStream != null) {
      _soloud.disposeSource(_activeStream!);
      _activeStream = null;
    }
  }

  Future<void> _startMicrophone() async {
    logger.i("Checking microphone permissions...");
    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) {
      logger.w("Microphone permission was not granted.");
      onStatusUpdate?.call("Microphone permission denied.");
      return;
    }

    logger.i(
      "Starting ${GeminiConstants.micSampleRate}Hz PCM microphone stream...",
    );
    try {
      final recordStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: GeminiConstants.micSampleRate,
          numChannels: 1,
        ),
      );

      _audioChunkCount = 0;
      _hasUserSpoken = false;
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
            if (_conversationState == ConversationState.speaking ||
                _isMicrophoneLocked)
              return;

            final double currentAmp = amp.current;
            onAmplitudeUpdate?.call(currentAmp);

            if (currentAmp > -20.0) {
              _hasUserSpoken = true;
              if (_conversationState == ConversationState.thinking) {
                _setConversationState(ConversationState.active);
                onStatusUpdate?.call("Listening... (Speak naturally)");
              }
              _silenceTimer?.cancel();
              _silenceTimer = null;
            } else {
              if (_hasUserSpoken &&
                  _conversationState == ConversationState.active &&
                  _silenceTimer == null) {
                _silenceTimer = Timer(const Duration(milliseconds: 2500), () {
                  if (_conversationState == ConversationState.active) {
                    _setConversationState(ConversationState.thinking);
                    onStatusUpdate?.call("Thinking...");
                  }
                });
              }
            }
          });
      _audioStreamSubscription = recordStream.listen((data) {
        if (_channel != null) {
          if (_isMicrophoneLocked ||
              _isPlaying ||
              _isModelResponding ||
              _conversationState == ConversationState.speaking ||
              _conversationState == ConversationState.thinking) {
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
              "audio": {
                "mimeType": GeminiConstants.micMimeType,
                "data": base64Audio,
              },
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
    _silenceTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
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
    onStatusUpdate?.call("Say 'Nira' or tap mic");
    onDisconnected?.call();
    logger.i("GeminiService disconnected (Standby).");
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _gracePeriodTimer?.cancel();
    disconnect();
    _soloud.deinit();
    _audioRecorder.dispose();
  }
}
