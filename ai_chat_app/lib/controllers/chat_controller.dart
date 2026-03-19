import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ChatController extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  
  List<MessageModel> get messages => _messages;

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    _messages.add(MessageModel(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    
    notifyListeners();
  }
}
