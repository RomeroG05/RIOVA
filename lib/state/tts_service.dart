import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings_controller.dart';

/// Lectura en voz alta (texto a voz del sistema Android) para el
/// "¿Sabías que…?", el relato histórico y la biblioteca.
class TtsService {
  TtsService() {
    _tts.setCompletionHandler(_done);
    _tts.setCancelHandler(_done);
    _tts.setErrorHandler((_) => _done());
  }

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;
  double _rate = VoiceSpeed.normal.rate;

  /// Velocidad elegida en Ajustes; se aplica desde la próxima lectura.
  void setRate(double rate) {
    _rate = rate;
    if (_configured) _tts.setSpeechRate(rate);
  }

  /// Identificador del texto que se está leyendo (o `null`).
  final ValueNotifier<String?> speaking = ValueNotifier(null);

  void _done() => speaking.value = null;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    for (final lang in const ['es-EC', 'es-US', 'es-419', 'es-ES']) {
      final ok = await _tts.isLanguageAvailable(lang);
      if (ok == true) {
        await _tts.setLanguage(lang);
        break;
      }
    }
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(1.08);
  }

  /// Lee [text]; si ya se estaba leyendo ese mismo [id], lo detiene.
  Future<void> toggle(String id, String text) async {
    if (speaking.value == id) {
      await stop();
      return;
    }
    await _configure();
    await _tts.stop();
    speaking.value = id;
    final result = await _tts.speak(text);
    if (result != 1) _done();
  }

  Future<void> stop() async {
    await _tts.stop();
    _done();
  }

  void dispose() {
    _tts.stop();
    speaking.dispose();
  }
}

final ttsProvider = Provider<TtsService>((ref) {
  final tts = TtsService();
  ref.listen(
    settingsProvider.select((s) => s.voiceSpeed),
    (_, speed) => tts.setRate(speed.rate),
    fireImmediately: true,
  );
  ref.onDispose(tts.dispose);
  return tts;
});
