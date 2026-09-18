// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

/// Soft café-style chime for new pending orders (web).
void playAdminOrderNotificationSound() {
  try {
    // Warm major arpeggio — like a gentle shop-door / cup chime.
    final notes = <({double hz, int ms, int delay})>[
      (hz: 523.25, ms: 220, delay: 0), // C5
      (hz: 659.25, ms: 220, delay: 140), // E5
      (hz: 783.99, ms: 420, delay: 280), // G5
    ];

    for (final note in notes) {
      Future<void>.delayed(Duration(milliseconds: note.delay), () {
        final audio = html.AudioElement(
          _softToneDataUri(frequency: note.hz, durationMs: note.ms),
        )
          ..volume = 0.72
          ..load();
        // ignore: discarded_futures
        audio.play();
      });
    }
  } catch (_) {
    // Banner still shows if the browser blocks autoplay.
  }
}

/// Soft sine-like bell tone with gentle fade-in/out.
String _softToneDataUri({
  required double frequency,
  required int durationMs,
}) {
  const sampleRate = 22050;
  final sampleCount = (sampleRate * durationMs / 1000).round();
  final data = ByteData(44 + sampleCount * 2);

  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  data.setUint32(4, 36 + sampleCount * 2, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  writeString(36, 'data');
  data.setUint32(40, sampleCount * 2, Endian.little);

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = i / sampleCount;

    // Soft attack + long decay (bell / chime envelope).
    final attack = (progress / 0.08).clamp(0.0, 1.0);
    final decay = math.exp(-2.8 * progress);
    final envelope = attack * decay;

    // Fundamental + soft harmonics for a warmer café bell.
    final wave = math.sin(2 * math.pi * frequency * t) * 0.70 +
        math.sin(2 * math.pi * frequency * 2 * t) * 0.18 +
        math.sin(2 * math.pi * frequency * 3 * t) * 0.08;

    final sample = (wave * envelope * 22000).round().clamp(-32767, 32767);
    data.setInt16(44 + i * 2, sample, Endian.little);
  }

  final b64 = base64Encode(data.buffer.asUint8List());
  return 'data:audio/wav;base64,$b64';
}
