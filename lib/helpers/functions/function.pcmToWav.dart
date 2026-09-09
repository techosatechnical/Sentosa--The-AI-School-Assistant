import 'dart:typed_data';
import 'package:sentosa/helpers/constants/constant.gemini.dart';

Uint8List pcmToWav(
  Uint8List pcmBytes, {
  int sampleRate = GeminiConstants.outputSampleRate,
  int numChannels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final totalDataLen = pcmBytes.length;
  final totalAudioLen = totalDataLen + 36;

  final header = ByteData(44);
  header.setUint8(0, 0x52); 
  header.setUint8(1, 0x49); 
  header.setUint8(2, 0x46); 
  header.setUint8(3, 0x46); 
  header.setUint32(4, totalAudioLen, Endian.little);
  header.setUint8(8, 0x57); 
  header.setUint8(9, 0x41); 
  header.setUint8(10, 0x56); 
  header.setUint8(11, 0x45); 

  header.setUint8(12, 0x66);
  header.setUint8(13, 0x6D);
  header.setUint8(14, 0x74); 
  header.setUint8(15, 0x20); 
  header.setUint32(16, 16, Endian.little); 
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  header.setUint8(36, 0x64);
  header.setUint8(37, 0x61);
  header.setUint8(38, 0x74); 
  header.setUint8(39, 0x61);
  header.setUint32(40, totalDataLen, Endian.little);

  final wavBytes = Uint8List(44 + totalDataLen);
  wavBytes.setRange(0, 44, header.buffer.asUint8List());
  wavBytes.setRange(44, 44 + totalDataLen, pcmBytes);
  return wavBytes;
}