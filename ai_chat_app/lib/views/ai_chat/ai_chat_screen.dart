import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/services.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/voice_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/constants.dart';
import '../../routes/app_routes.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final AIController aiController = Get.put(AIController());
  final VoiceController voiceController = Get.put(VoiceController());
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _textController = TextEditingController();
  final RxString _inputText = "".obs;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      _inputText.value = _textController.text;
    });
  }

  void _handleSend() {
    if (_textController.text.trim().isNotEmpty || aiController.webImageBytes.value != null) {
      aiController.sendMessage(_textController.text, isVoiceInput: false);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatUser currentUser = ChatUser(id: '1', firstName: authController.currentUser.value?.name ?? 'User');
    final ChatUser aiUser = ChatUser(id: '2', firstName: AppConstants.appName, profileImage: 'assets/logo.png');

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppConstants.appName,
          style: const TextStyle(
            color: AppColors.accentColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_off, color: Colors.grey),
            onPressed: () => voiceController.stopSpeaking(),
          ),
          const SizedBox(width: 10),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001529), Color(0xFF002140)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.backgroundColor,
        child: Column(
          children: [
            Obx(() => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF001529), Color(0xFF002140)],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.accentColor,
                backgroundImage: authController.currentUser.value?.profilePic != null 
                    ? MemoryImage(authController.currentUser.value!.profilePic!) 
                    : null,
                child: authController.currentUser.value?.profilePic == null 
                    ? Text(
                        authController.currentUser.value?.name[0].toUpperCase() ?? "U",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      )
                    : null,
              ),
              accountName: Text(
                authController.currentUser.value?.name ?? "User",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              accountEmail: Text(
                authController.currentUser.value?.email ?? "user@example.com",
                style: const TextStyle(color: Colors.white70),
              ),
            )),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.accentColor),
              title: const Text("Profile", style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back(); // Close drawer
                Get.toNamed(AppRoutes.profile); // Go to Profile Screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.accentColor),
              title: const Text("Settings", style: TextStyle(color: Colors.white)),
              onTap: () => Get.back(),
            ),
            const Spacer(),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: () => authController.logout(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png'),
            fit: BoxFit.cover,
            opacity: 0.03,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                List<ChatMessage> dashMessages = aiController.messages.map((msg) {
                  return ChatMessage(
                    text: msg.text,
                    user: msg.isUser ? currentUser : aiUser,
                    createdAt: msg.timestamp,
                    medias: msg.imageBytes != null 
                        ? [ChatMedia(url: "", type: MediaType.image, fileName: "image.jpg")] 
                        : null,
                  );
                }).toList();

                dashMessages = dashMessages.reversed.toList();

                return RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (RawKeyEvent event) {
                    if (event.runtimeType == RawKeyDownEvent && 
                        event.logicalKey == LogicalKeyboardKey.enter && 
                        !event.isShiftPressed) {
                      _handleSend();
                    }
                  },
                  child: DashChat(
                    currentUser: currentUser,
                    onSend: (ChatMessage msg) {
                      aiController.sendMessage(msg.text, isVoiceInput: false);
                    },
                    messages: dashMessages,
                    inputOptions: InputOptions(
                      textController: _textController,
                      alwaysShowSend: true,
                      leading: [
                        IconButton(
                          icon: const Icon(Icons.image, color: AppColors.accentColor),
                          onPressed: aiController.pickImage,
                        ),
                      ],
                      inputDecoration: InputDecoration(
                        hintText: voiceController.isListening.value ? "Listening..." : "Type a message...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: AppColors.accentColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppColors.accentColor.withOpacity(0.3)),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      inputTextStyle: const TextStyle(color: Colors.white),
                      sendButtonBuilder: (onSend) {
                        return Obx(() => GestureDetector(
                          onLongPress: () {
                            voiceController.startListening((text) {});
                          },
                          onLongPressUp: () {
                            voiceController.stopListening();
                            if (voiceController.recognizedText.value.isNotEmpty) {
                              aiController.sendMessage(voiceController.recognizedText.value, isVoiceInput: true);
                              voiceController.recognizedText.value = "";
                            }
                          },
                          onTap: _handleSend,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: AppColors.accentColor,
                              child: Icon(
                                voiceController.isListening.value 
                                    ? Icons.mic 
                                    : (_inputText.isEmpty && aiController.webImageBytes.value == null ? Icons.mic_none : Icons.send),
                                color: AppColors.backgroundColor,
                              ),
                            ),
                          ),
                        ));
                      },
                    ),
                    messageOptions: MessageOptions(
                      currentUserContainerColor: AppColors.userBubbleColor.withOpacity(0.8),
                      containerColor: AppColors.aiBubbleColor.withOpacity(0.8),
                      textColor: Colors.white,
                      currentUserTextColor: Colors.white,
                      showTime: true,
                      avatarBuilder: (user, onPress, onLongPress) {
                        if (user.id == '2') {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accentColor, width: 1.5),
                            ),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.transparent,
                              backgroundImage: AssetImage('assets/logo.png'),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      messageMediaBuilder: (ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
                        final localMsg = aiController.messages.firstWhere((m) => m.text == message.text, orElse: () => aiController.messages.first);
                        if (localMsg.imageBytes != null) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.memory(localMsg.imageBytes!, width: 200, fit: BoxFit.cover),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    typingUsers: aiController.isLoading.value ? [aiUser] : [],
                  ),
                );
              }),
            ),
            Obx(() {
              if (aiController.webImageBytes.value != null) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  height: 100,
                  color: Colors.black26,
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Image.memory(aiController.webImageBytes.value!, width: 80, height: 80, fit: BoxFit.cover),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: aiController.clearImage,
                              child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Text("Image selected", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
