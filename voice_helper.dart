import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceHelper {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool isListening = false;
  String lastWords = "";
  String currentLocale = "en-US"; // default

  Future<void> startListening(Function(String) onResult, {String localeId = "en-US"}) async {
    final available = await _speech.initialize(
      onError: (e) => print("STT error: $e"),
      onStatus: (s) => print("STT status: $s"),
    );
    if (!available) return;
    currentLocale = localeId;
    isListening = true;
    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 15),
      onResult: (result) {
        lastWords = result.recognizedWords;
        onResult(lastWords);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    isListening = false;
  }

  Future<void> speak(String text, {String lang = "en-US"}) async {
    await _tts.stop();
    await _tts.setLanguage(lang);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.98);
    await _tts.speak(text);
  }
}