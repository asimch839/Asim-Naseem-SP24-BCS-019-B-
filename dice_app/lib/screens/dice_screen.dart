import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/dice_logic.dart';
import '../widgets/dice_widget.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen>
    with SingleTickerProviderStateMixin {
  int diceNumber = 1;
  int correctGuessCount = 0;

  final TextEditingController _guessController = TextEditingController();

  String message = "Tap the dice to roll!";
  bool isRolling = false;

  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  String selectedFont = "Default";

  final List<Map<String, String>> fontOptions = const [
    {"name": "Default", "family": ""},
    {"name": "Roboto", "family": "Roboto"},
    {"name": "Lato", "family": "Lato"},
    {"name": "Montserrat", "family": "Montserrat"},
  ];

  String? getCurrentFontFamily() {
    final font = fontOptions.firstWhere((f) => f["name"] == selectedFont);
    return font["family"]!.isNotEmpty ? font["family"] : null;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 6 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _bounceAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -150)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -150, end: 0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  Future<void> rollDice() async {
    if (isRolling) return;

    setState(() {
      isRolling = true;
      message = "Rolling...";
    });

    _controller.forward(from: 0);

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isRolling) {
        timer.cancel();
      } else {
        setState(() {
          diceNumber = Random().nextInt(6) + 1;
        });
      }
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    // Using your original DiceLogic to get the number
    final finalNumber = DiceLogic.getRandomDice();

    setState(() {
      diceNumber = finalNumber;
      isRolling = false;

      if (_guessController.text.isNotEmpty) {
        final guess = int.tryParse(_guessController.text);

        if (guess == finalNumber) {
          correctGuessCount++;
          // FIXED: Now it shows the ACTUAL dice number in the message
          message = "🎉 Correct! It was $finalNumber";
        } else {
          message = "❌ Oops! It was $finalNumber";
        }
      } else {
        message = "You rolled a $finalNumber!";
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _guessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFont = getCurrentFontFamily();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.black,
                Color(0xFF0F172A),
                Colors.black,
              ],
              stops: [0.2, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  /// HEADER (Added Score display here so it's clear)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.casino, color: Colors.purpleAccent),
                          Text(
                            "SCORE: $correctGuessCount",
                            style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        "DICE ROLLER",
                        style: TextStyle(
                          fontFamily: currentFont,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white38),
                        onPressed: () {
                          _guessController.clear();
                          setState(() {
                            correctGuessCount = 0;
                            message = "Tap the dice to roll!";
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// DROPDOWN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFont,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        iconEnabledColor: Colors.white70,
                        items: fontOptions.map((font) {
                          return DropdownMenuItem(
                            value: font["name"],
                            child: Text(
                              font["name"]!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => selectedFont = v!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),

                  /// YOUR DICE WIDGET (RESTORED)
                  GestureDetector(
                    onTap: rollDice,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bounceAnimation.value),
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: DiceWidget(diceNumber: diceNumber),
                    ),
                  ),

                  const SizedBox(height: 60),

                  /// RESULT
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: currentFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.purpleAccent.withOpacity(0.6),
                          blurRadius: 12,
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// INPUT
                  TextField(
                    controller: _guessController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: "Enter your guess",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: Colors.purpleAccent, width: 1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: rollDice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        isRolling ? "ROLLING..." : "ROLL NOW",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}