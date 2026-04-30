import 'package:flutter/material.dart';
import '../constants.dart';

class BottomButton extends StatelessWidget {
  BottomButton({required this.onTap, required this.buttonTitle});

  final VoidCallback onTap;
  final String buttonTitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(15, 10, 15, 20),
        height: kBottomContainerHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kBottomContainerColour,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: kBottomContainerColour.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            buttonTitle,
            style: kLargeButtonTextStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
