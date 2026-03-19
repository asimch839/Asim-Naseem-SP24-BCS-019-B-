import 'dart:typed_data';

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes; // To store image data

  MessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageBytes,
  });
}
