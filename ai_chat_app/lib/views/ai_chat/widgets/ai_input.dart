import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AIInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const AIInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }
}
