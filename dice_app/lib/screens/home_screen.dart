import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Center content vertically
          children: [
            // Image widget
            Image.asset(
              'assets/images/6.jpeg', // apni image ka path yahan dalen
              width: 200, // width customize kar sakte ho
              height: 200, // height customize kar sakte ho
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20), // Button aur image ke beech space
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dice');
              },
              child: const Text("Do You Want To Start Dice Game"),
            ),
          ],
        ),
      ),
    );
  }
}