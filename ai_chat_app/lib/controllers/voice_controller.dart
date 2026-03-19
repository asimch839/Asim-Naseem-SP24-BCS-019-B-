import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  final RxBool isListening = false.obs;
  final RxString recognizedText = "".obs;

  @override
  void onInit() {
    super.onInit();
    _initVoice();
  }

  void _initVoice() async {
    await Permission.microphone.request();
    bool available = await _speechToText.initialize();
    
    // Setting up better voice settings
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0); // Natural pitch
    await _flutterTts.setSpeechRate(0.45); // Slightly slower for clarity
    await _flutterTts.setVolume(1.0);
    
    // Try to set a more natural female voice if available on the device
    try {
      await _flutterTts.setVoice({"name": "en-us-x-sfg#female_1-local", "locale": "en-US"});
    } catch (e) {
      print("Specific voice not found, using default.");
    }

    if (!available) {
      Get.snackbar("Error", "Speech recognition not available");
    }
  }

  void startListening(Function(String) onResult) async {
    if (!isListening.value) {
      bool available = await _speechToText.initialize();
      if (available) {
        isListening.value = true;
        _speechToText.listen(
          onResult: (result) {
            recognizedText.value = result.recognizedWords;
            if (result.finalResult) {
              isListening.value = false;
              onResult(result.recognizedWords);
            }
          },
        );
      }
    }
  }

  void stopListening() {
    _speechToText.stop();
    isListening.value = false;
  }

  void speak(String text) async {
    await _flutterTts.speak(text);
  }

  void stopSpeaking() async {
    await _flutterTts.stop();
  }
}
