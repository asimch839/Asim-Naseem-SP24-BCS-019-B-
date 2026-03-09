import 'package:flutter/material.dart';

class DiceWidget extends StatelessWidget {
  final int diceNumber;

  const DiceWidget({super.key, required this.diceNumber});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/images/$diceNumber.jpeg",
      height: 200,
      width: 200,
      fit: BoxFit.contain,
    );
  }
}