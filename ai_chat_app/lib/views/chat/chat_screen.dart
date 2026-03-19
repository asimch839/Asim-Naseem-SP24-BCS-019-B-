import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _controller = ChatController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _controller.messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _controller.messages[index]);
              },
            ),
          ),
          MessageInput(
            controller: _textController,
            onSend: () {
              _controller.sendMessage(_textController.text);
              _textController.clear();
            },
          ),
        ],
      ),
    );
  }
}
