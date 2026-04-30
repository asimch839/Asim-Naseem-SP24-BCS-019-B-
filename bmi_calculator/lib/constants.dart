import 'package:flutter/material.dart';

// Theme Colors (Slate Blue Theme)
const kBackgroundColor = Color(0xFF2C3E50);
const kCardColor = Color(0xFF34495E);
const kInputFillColor = Color(0xFF465C71);
const kAccentColor = Color(0xFF3498DB);

// Map old names to new theme for compatibility
const kActiveCardColour = Color(0xFF34495E);
const kInactiveCardColour = Color(0xFF2C3E50);
const kBottomContainerColour = Color(0xFF3498DB);
const kBottomContainerHeight = 70.0;

// Text Styles
const kLabelTextStyle = TextStyle(
  fontSize: 16.0,
  color: Colors.white70,
  fontWeight: FontWeight.w500,
);

const kLabelStyle = kLabelTextStyle; // Alias for dashboard

const kNumberTextStyle = TextStyle(
  fontSize: 35.0,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const kNumberStyle = kNumberTextStyle; // Alias for dashboard

const kLargeButtonTextStyle = TextStyle(
  fontSize: 22.0,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const kTitleTextStyle = TextStyle(
  fontSize: 40.0,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const kResultTextStyle = TextStyle(
  color: Color(0xFF24D876),
  fontSize: 24.0,
  fontWeight: FontWeight.bold,
);

const kBMITextStyle = TextStyle(
  fontSize: 90.0,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const kBodyTextStyle = TextStyle(
  fontSize: 20.0,
  color: Colors.white70,
);

const kTableTextStyle = TextStyle(
  fontSize: 14.0,
  color: Colors.white,
);
