import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';
import '../services/ai_service.dart';
import 'voice_controller.dart';

class AIController extends GetxController {
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  
  // Using XFile instead of File for Web compatibility
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final Rx<Uint8List?> webImageBytes = Rx<Uint8List?>(null);
  
  final AIService _aiService = Get.put(AIService());
  final VoiceController _voiceController = Get.put(VoiceController());
  final ImagePicker _picker = ImagePicker();

  void pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = image;
      // Reading bytes immediately for preview and API
      webImageBytes.value = await image.readAsBytes();
    }
  }

  void clearImage() {
    selectedImage.value = null;
    webImageBytes.value = null;
  }

  void sendMessage(String text, {bool isVoiceInput = false}) async {
    if (text.trim().isEmpty && selectedImage.value == null) return;

    Uint8List? imageBytes = webImageBytes.value;

    final userMessage = MessageModel(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    );

    messages.add(userMessage);
    isLoading.value = true;
    
    // Clear preview
    clearImage();

    try {
      String response;
      if (imageBytes != null) {
        response = await _aiService.getAIImageResponse(text, imageBytes);
      } else {
        response = await _aiService.getAIResponse(text);
      }
      
      final aiMessage = MessageModel(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(aiMessage);

      if (isVoiceInput) {
        _voiceController.speak(response);
      }
    } catch (e) {
      messages.add(MessageModel(
        text: "Error: $e",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading.value = false;
    }
  }
}
