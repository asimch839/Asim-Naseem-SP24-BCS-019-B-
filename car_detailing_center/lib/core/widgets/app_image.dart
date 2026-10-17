import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const AppImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imagePath == null || imagePath!.trim().isEmpty) {
      content = placeholder ?? _defaultPlaceholder();
    } else if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
      content = Image.network(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
      );
    } else {
      final file = File(imagePath!);
      if (file.existsSync()) {
        content = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
        );
      } else {
        content = placeholder ?? _defaultPlaceholder();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.cardDark,
      child: const Center(
        child: Icon(Icons.photo_outlined, color: AppColors.textDarkSecondary, size: 24),
      ),
    );
  }
}
