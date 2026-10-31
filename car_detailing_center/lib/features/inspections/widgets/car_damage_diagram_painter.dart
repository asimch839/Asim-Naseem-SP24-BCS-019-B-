import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/diagram_marker_model.dart';

class CarDamageDiagramPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final List<DiagramMarker> markers;
  final bool isDarkMode;
  final String? hoveredOrSelectedMarkerId;

  CarDamageDiagramPainter({
    required this.strokes,
    this.currentStroke,
    required this.markers,
    this.isDarkMode = true,
    this.hoveredOrSelectedMarkerId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Blueprint Tint
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF141A1F) : const Color(0xFFF4F7F6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(12)), bgPaint);

    // Subtle grid pattern
    _drawBlueprintGrid(canvas, size);

    // Outline Paint for Car Schematics (Blueprint Green/Teal style matching image)
    final linePaint = Paint()
      ..color = isDarkMode ? const Color(0xFF4EBA88) : const Color(0xFF1E7E52)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinLinePaint = Paint()
      ..color = (isDarkMode ? const Color(0xFF4EBA88) : const Color(0xFF1E7E52)).withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = (isDarkMode ? const Color(0xFF1B3629) : const Color(0xFFE2F0E8)).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // 1. TOP CAR VIEW (Center)
    final topRect = Rect.fromLTWH(w * 0.26, h * 0.28, w * 0.48, h * 0.40);
    _drawTopView(canvas, topRect, linePaint, thinLinePaint, fillPaint);

    // 2. FRONT CAR VIEW (Left)
    final frontRect = Rect.fromLTWH(w * 0.04, h * 0.34, w * 0.18, h * 0.28);
    _drawFrontView(canvas, frontRect, linePaint, thinLinePaint, fillPaint);

    // 3. REAR CAR VIEW (Right)
    final rearRect = Rect.fromLTWH(w * 0.78, h * 0.34, w * 0.18, h * 0.28);
    _drawRearView(canvas, rearRect, linePaint, thinLinePaint, fillPaint);

    // 4. UPPER SIDE PROFILE (Top)
    final upperSideRect = Rect.fromLTWH(w * 0.20, h * 0.05, w * 0.60, h * 0.20);
    _drawSideProfile(canvas, upperSideRect, linePaint, thinLinePaint, fillPaint, isTopView: true);

    // 5. LOWER SIDE PROFILE (Bottom)
    final lowerSideRect = Rect.fromLTWH(w * 0.20, h * 0.72, w * 0.60, h * 0.24);
    _drawSideProfile(canvas, lowerSideRect, linePaint, thinLinePaint, fillPaint, isTopView: false);

    // View Name Labels
    _drawViewLabels(canvas, size);

    // Draw User Hand-Drawn Strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    // Draw Defect Pins / Markers
    for (final marker in markers) {
      _drawMarkerPin(canvas, size, marker);
    }
  }

  void _drawBlueprintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  // --- 1. TOP CAR VIEW (Horizontal, Facing Left like diagram) ---
  void _drawTopView(Canvas canvas, Rect r, Paint mainP, Paint thinP, Paint fillP) {
    // Outer car body silhouette (horizontal: left = front bonnet, right = trunk)
    final body = Path();
    final left = r.left;
    final top = r.top;
    final w = r.width;
    final h = r.height;

    // Front bumper (left curve)
    body.moveTo(left + w * 0.08, top + h * 0.18);
    body.quadraticBezierTo(left, top + h * 0.5, left + w * 0.08, top + h * 0.82);

    // Lower rocker panel & wheels
    body.cubicTo(left + w * 0.20, top + h * 0.90, left + w * 0.40, top + h * 0.92, left + w * 0.50, top + h * 0.92);
    body.cubicTo(left + w * 0.65, top + h * 0.92, left + w * 0.82, top + h * 0.90, left + w * 0.94, top + h * 0.82);

    // Rear bumper (right curve)
    body.quadraticBezierTo(left + w, top + h * 0.5, left + w * 0.94, top + h * 0.18);

    // Upper rocker panel
    body.cubicTo(left + w * 0.82, top + h * 0.10, left + w * 0.65, top + h * 0.08, left + w * 0.50, top + h * 0.08);
    body.cubicTo(left + w * 0.40, top + h * 0.08, left + w * 0.20, top + h * 0.10, left + w * 0.08, top + h * 0.18);
    body.close();

    canvas.drawPath(body, fillP);
    canvas.drawPath(body, mainP);

    // Front Windshield (curved)
    final frontGlass = Path();
    frontGlass.moveTo(left + w * 0.32, top + h * 0.16);
    frontGlass.quadraticBezierTo(left + w * 0.28, top + h * 0.5, left + w * 0.32, top + h * 0.84);
    frontGlass.lineTo(left + w * 0.40, top + h * 0.80);
    frontGlass.quadraticBezierTo(left + w * 0.37, top + h * 0.5, left + w * 0.40, top + h * 0.20);
    frontGlass.close();
    canvas.drawPath(frontGlass, thinP);

    // Roof & Sunroof
    final roof = Path();
    roof.moveTo(left + w * 0.40, top + h * 0.20);
    roof.lineTo(left + w * 0.68, top + h * 0.20);
    roof.lineTo(left + w * 0.68, top + h * 0.80);
    roof.lineTo(left + w * 0.40, top + h * 0.80);
    roof.close();
    canvas.drawPath(roof, thinP);

    // Sunroof outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.45, top + h * 0.32, w * 0.15, h * 0.36), const Radius.circular(4)),
      thinP,
    );

    // Rear Windshield
    final rearGlass = Path();
    rearGlass.moveTo(left + w * 0.68, top + h * 0.20);
    rearGlass.quadraticBezierTo(left + w * 0.72, top + h * 0.5, left + w * 0.68, top + h * 0.80);
    rearGlass.lineTo(left + w * 0.76, top + h * 0.82);
    rearGlass.quadraticBezierTo(left + w * 0.80, top + h * 0.5, left + w * 0.76, top + h * 0.18);
    rearGlass.close();
    canvas.drawPath(rearGlass, thinP);

    // Trunk lid lines
    canvas.drawLine(Offset(left + w * 0.88, top + h * 0.24), Offset(left + w * 0.88, top + h * 0.76), thinP);

    // Bonnet creases
    canvas.drawLine(Offset(left + w * 0.10, top + h * 0.32), Offset(left + w * 0.30, top + h * 0.26), thinP);
    canvas.drawLine(Offset(left + w * 0.10, top + h * 0.68), Offset(left + w * 0.30, top + h * 0.74), thinP);

    // Headlights top view
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.05, top + h * 0.18, w * 0.07, h * 0.12), const Radius.circular(4)),
      mainP,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.05, top + h * 0.70, w * 0.07, h * 0.12), const Radius.circular(4)),
      mainP,
    );

    // Side Mirrors (top and bottom)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.30, top + h * 0.02, w * 0.06, h * 0.07), const Radius.circular(3)),
      mainP,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.30, top + h * 0.91, w * 0.06, h * 0.07), const Radius.circular(3)),
      mainP,
    );

    // 4 Wheels visible on top view edges
    final tirePaint = Paint()
      ..color = (isDarkMode ? Colors.black : Colors.grey.shade800)
      ..style = PaintingStyle.fill;

    // Front Left & Right Tires
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.16, top + h * 0.04, w * 0.10, h * 0.06), const Radius.circular(2)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.16, top + h * 0.90, w * 0.10, h * 0.06), const Radius.circular(2)), tirePaint);
    // Rear Left & Right Tires
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.72, top + h * 0.04, w * 0.10, h * 0.06), const Radius.circular(2)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.72, top + h * 0.90, w * 0.10, h * 0.06), const Radius.circular(2)), tirePaint);
  }

  // --- 2. FRONT CAR VIEW (Left) ---
  void _drawFrontView(Canvas canvas, Rect r, Paint mainP, Paint thinP, Paint fillP) {
    final left = r.left;
    final top = r.top;
    final w = r.width;
    final h = r.height;

    // Outer Front Silhouette
    final front = Path();
    front.moveTo(left + w * 0.15, top + h * 0.90); // Left tire bottom
    front.lineTo(left + w * 0.10, top + h * 0.65); // Left bumper corner
    front.lineTo(left + w * 0.12, top + h * 0.40); // Hood corner
    front.lineTo(left + w * 0.25, top + h * 0.15); // A-pillar left
    front.quadraticBezierTo(left + w * 0.5, top + h * 0.10, left + w * 0.75, top + h * 0.15); // Roof
    front.lineTo(left + w * 0.88, top + h * 0.40); // A-pillar right
    front.lineTo(left + w * 0.90, top + h * 0.65); // Right bumper corner
    front.lineTo(left + w * 0.85, top + h * 0.90); // Right tire bottom
    front.quadraticBezierTo(left + w * 0.5, top + h * 0.95, left + w * 0.15, top + h * 0.90);
    front.close();

    canvas.drawPath(front, fillP);
    canvas.drawPath(front, mainP);

    // Windshield
    final glass = Path();
    glass.moveTo(left + w * 0.26, top + h * 0.18);
    glass.quadraticBezierTo(left + w * 0.5, top + h * 0.15, left + w * 0.74, top + h * 0.18);
    glass.lineTo(left + w * 0.82, top + h * 0.42);
    glass.quadraticBezierTo(left + w * 0.5, top + h * 0.40, left + w * 0.18, top + h * 0.42);
    glass.close();
    canvas.drawPath(glass, thinP);

    // Hood Line
    canvas.drawLine(Offset(left + w * 0.14, top + h * 0.46), Offset(left + w * 0.86, top + h * 0.46), thinP);

    // Headlights
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.14, top + h * 0.48, w * 0.20, h * 0.14), const Radius.circular(4)), mainP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.66, top + h * 0.48, w * 0.20, h * 0.14), const Radius.circular(4)), mainP);

    // Radiator Grille
    final grilleRect = Rect.fromLTWH(left + w * 0.38, top + h * 0.50, w * 0.24, h * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(grilleRect, const Radius.circular(4)), mainP);
    canvas.drawLine(Offset(grilleRect.left, grilleRect.center.dy), Offset(grilleRect.right, grilleRect.center.dy), thinP);

    // Center Logo
    canvas.drawCircle(grilleRect.center, 4, mainP);

    // Lower Air Dam & Bumper
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.25, top + h * 0.76, w * 0.50, h * 0.12), const Radius.circular(4)), thinP);

    // Fog Lights
    canvas.drawCircle(Offset(left + w * 0.18, top + h * 0.80), 4, thinP);
    canvas.drawCircle(Offset(left + w * 0.82, top + h * 0.80), 4, thinP);

    // Side Mirrors
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.04, top + h * 0.36, w * 0.08, h * 0.12), const Radius.circular(3)), mainP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.88, top + h * 0.36, w * 0.08, h * 0.12), const Radius.circular(3)), mainP);
  }

  // --- 3. REAR CAR VIEW (Right) ---
  void _drawRearView(Canvas canvas, Rect r, Paint mainP, Paint thinP, Paint fillP) {
    final left = r.left;
    final top = r.top;
    final w = r.width;
    final h = r.height;

    // Rear Silhouette
    final rear = Path();
    rear.moveTo(left + w * 0.15, top + h * 0.90);
    rear.lineTo(left + w * 0.10, top + h * 0.65);
    rear.lineTo(left + w * 0.12, top + h * 0.40);
    rear.lineTo(left + w * 0.25, top + h * 0.15);
    rear.quadraticBezierTo(left + w * 0.5, top + h * 0.10, left + w * 0.75, top + h * 0.15);
    rear.lineTo(left + w * 0.88, top + h * 0.40);
    rear.lineTo(left + w * 0.90, top + h * 0.65);
    rear.lineTo(left + w * 0.85, top + h * 0.90);
    rear.quadraticBezierTo(left + w * 0.5, top + h * 0.95, left + w * 0.15, top + h * 0.90);
    rear.close();

    canvas.drawPath(rear, fillP);
    canvas.drawPath(rear, mainP);

    // Rear Windshield Glass
    final rearGlass = Path();
    rearGlass.moveTo(left + w * 0.26, top + h * 0.18);
    rearGlass.quadraticBezierTo(left + w * 0.5, top + h * 0.15, left + w * 0.74, top + h * 0.18);
    rearGlass.lineTo(left + w * 0.80, top + h * 0.44);
    rearGlass.quadraticBezierTo(left + w * 0.5, top + h * 0.42, left + w * 0.20, top + h * 0.44);
    rearGlass.close();
    canvas.drawPath(rearGlass, thinP);

    // High Mount Stop Lamp
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.45, top + h * 0.18, w * 0.10, h * 0.04), const Radius.circular(2)), thinP);

    // Trunk Seam
    canvas.drawLine(Offset(left + w * 0.16, top + h * 0.48), Offset(left + w * 0.84, top + h * 0.48), thinP);

    // Taillights
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.14, top + h * 0.50, w * 0.20, h * 0.14), const Radius.circular(4)), mainP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.66, top + h * 0.50, w * 0.20, h * 0.14), const Radius.circular(4)), mainP);

    // License Plate Holder
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.36, top + h * 0.54, w * 0.28, h * 0.14), const Radius.circular(3)), mainP);

    // Rear Bumper Seam & Exhaust Tips
    canvas.drawLine(Offset(left + w * 0.12, top + h * 0.74), Offset(left + w * 0.88, top + h * 0.74), thinP);
    canvas.drawCircle(Offset(left + w * 0.25, top + h * 0.86), 4, mainP);
    canvas.drawCircle(Offset(left + w * 0.75, top + h * 0.86), 4, mainP);

    // Side Mirrors
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.04, top + h * 0.36, w * 0.08, h * 0.12), const Radius.circular(3)), mainP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.88, top + h * 0.36, w * 0.08, h * 0.12), const Radius.circular(3)), mainP);
  }

  // --- 4 & 5. CAR SIDE PROFILE VIEWS (Sedan Outline with Wheels & Doors) ---
  void _drawSideProfile(Canvas canvas, Rect r, Paint mainP, Paint thinP, Paint fillP, {required bool isTopView}) {
    final left = r.left;
    final top = r.top;
    final w = r.width;
    final h = r.height;

    final profile = Path();
    final wheelRadius = h * 0.28;
    final frontWheelCenter = Offset(left + w * 0.20, top + h * 0.78);
    final rearWheelCenter = Offset(left + w * 0.78, top + h * 0.78);

    // Front Bumper -> Hood -> Windshield -> Roof -> Rear Glass -> Trunk -> Rear Bumper
    profile.moveTo(left + w * 0.02, top + h * 0.75); // Front bumper bottom
    profile.lineTo(left + w * 0.01, top + h * 0.55); // Front nose
    profile.quadraticBezierTo(left + w * 0.08, top + h * 0.38, left + w * 0.25, top + h * 0.34); // Hood
    profile.lineTo(left + w * 0.40, top + h * 0.14); // A-pillar
    profile.quadraticBezierTo(left + w * 0.55, top + h * 0.10, left + w * 0.68, top + h * 0.16); // Roof curve
    profile.lineTo(left + w * 0.80, top + h * 0.38); // Rear windshield / C-pillar
    profile.lineTo(left + w * 0.94, top + h * 0.42); // Trunk lid
    profile.quadraticBezierTo(left + w * 0.99, top + h * 0.52, left + w * 0.98, top + h * 0.72); // Rear bumper
    profile.lineTo(left + w * 0.92, top + h * 0.78); // Under rear bumper

    // Rear Wheel Arch cutout
    profile.arcToPoint(
      Offset(rearWheelCenter.dx - wheelRadius, rearWheelCenter.dy),
      radius: Radius.circular(wheelRadius),
      clockwise: false,
    );

    // Rocker Panel between wheels
    profile.lineTo(frontWheelCenter.dx + wheelRadius, frontWheelCenter.dy);

    // Front Wheel Arch cutout
    profile.arcToPoint(
      Offset(frontWheelCenter.dx - wheelRadius, frontWheelCenter.dy),
      radius: Radius.circular(wheelRadius),
      clockwise: false,
    );

    // Front chin
    profile.lineTo(left + w * 0.02, top + h * 0.75);
    profile.close();

    canvas.drawPath(profile, fillP);
    canvas.drawPath(profile, mainP);

    // Window Frames
    final windows = Path();
    windows.moveTo(left + w * 0.40, top + h * 0.18);
    windows.lineTo(left + w * 0.66, top + h * 0.18);
    windows.lineTo(left + w * 0.77, top + h * 0.38);
    windows.lineTo(left + w * 0.33, top + h * 0.38);
    windows.close();
    canvas.drawPath(windows, thinP);

    // B-Pillar dividing front & rear window
    canvas.drawLine(Offset(left + w * 0.53, top + h * 0.18), Offset(left + w * 0.53, top + h * 0.75), thinP);

    // Front Door Seam
    final frontDoor = Path();
    frontDoor.moveTo(left + w * 0.33, top + h * 0.38);
    frontDoor.lineTo(left + w * 0.28, top + h * 0.75);
    canvas.drawPath(frontDoor, thinP);

    // Rear Door Seam
    final rearDoor = Path();
    rearDoor.moveTo(left + w * 0.70, top + h * 0.38);
    rearDoor.quadraticBezierTo(left + w * 0.70, top + h * 0.55, rearWheelCenter.dx - wheelRadius + 4, frontWheelCenter.dy);
    canvas.drawPath(rearDoor, thinP);

    // Door Handles
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.46, top + h * 0.42, w * 0.04, h * 0.04), const Radius.circular(2)), mainP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.60, top + h * 0.42, w * 0.04, h * 0.04), const Radius.circular(2)), mainP);

    // Side Mirror
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + w * 0.35, top + h * 0.34, w * 0.04, h * 0.08), const Radius.circular(3)), mainP);

    // Headlight profile & Taillight profile
    canvas.drawCircle(Offset(left + w * 0.05, top + h * 0.45), 3, mainP);
    canvas.drawCircle(Offset(left + w * 0.96, top + h * 0.46), 3, mainP);

    // Draw Front & Rear Wheels with Alloy Rims
    _drawWheel(canvas, frontWheelCenter, wheelRadius * 0.90, mainP, thinP);
    _drawWheel(canvas, rearWheelCenter, wheelRadius * 0.90, mainP, thinP);
  }

  void _drawWheel(Canvas canvas, Offset center, double radius, Paint mainP, Paint thinP) {
    final tirePaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E2228) : const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    // Tire Outer
    canvas.drawCircle(center, radius, tirePaint);
    canvas.drawCircle(center, radius, mainP);

    // Rim Outer
    final rimPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF3A424B) : const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.68, rimPaint);
    canvas.drawCircle(center, radius * 0.68, thinP);

    // Center Hub
    canvas.drawCircle(center, radius * 0.22, mainP);

    // Alloy Rim Spokes (5 Spokes)
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72) * (math.pi / 180);
      final p1 = Offset(center.dx + math.cos(angle) * (radius * 0.22), center.dy + math.sin(angle) * (radius * 0.22));
      final p2 = Offset(center.dx + math.cos(angle) * (radius * 0.66), center.dy + math.sin(angle) * (radius * 0.66));
      canvas.drawLine(p1, p2, mainP);
    }
  }

  void _drawViewLabels(Canvas canvas, Size size) {
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;

    // Notice text banner at top
    _drawCenteredText(
      canvas,
      Offset(size.width * 0.5, 14),
      '* Should any defects be detected in the inspection, Indicate them with marks on the diagram.',
      TextStyle(color: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
    );

    // View Subtitles
    _drawCenteredText(canvas, Offset(size.width * 0.50, size.height * 0.03), 'DRIVER SIDE (LEFT PROFILE)', TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold));
    _drawCenteredText(canvas, Offset(size.width * 0.13, size.height * 0.32), 'FRONT VIEW', TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold));
    _drawCenteredText(canvas, Offset(size.width * 0.50, size.height * 0.26), 'TOP VIEW (ROOF & PANELS)', TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold));
    _drawCenteredText(canvas, Offset(size.width * 0.87, size.height * 0.32), 'REAR VIEW', TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold));
    _drawCenteredText(canvas, Offset(size.width * 0.50, size.height * 0.70), 'PASSENGER SIDE (RIGHT PROFILE)', TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold));
  }

  void _drawCenteredText(Canvas canvas, Offset offset, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - (tp.width / 2), offset.dy));
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, Paint()..color = stroke.color);
      return;
    }

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawMarkerPin(Canvas canvas, Size size, DiagramMarker marker) {
    final pos = Offset(marker.x * size.width, marker.y * size.height);
    final isSelected = marker.id == hoveredOrSelectedMarkerId;

    // Pin Shadow
    canvas.drawCircle(pos, 13, Paint()..color = Colors.black.withValues(alpha: 0.35));

    // Outer Circle with Defect Color
    final pinPaint = Paint()
      ..color = marker.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, isSelected ? 13 : 11, pinPaint);

    // White Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = isSelected ? 2.5 : 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, isSelected ? 13 : 11, borderPaint);

    // Defect Code Character inside
    final tp = TextPainter(
      text: TextSpan(
        text: marker.shortCode,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - (tp.width / 2), pos.dy - (tp.height / 2)));

    // Defect Note Tag (if note is present)
    if (marker.note.trim().isNotEmpty) {
      final noteSpan = TextSpan(
        text: marker.note,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
      );
      final noteTp = TextPainter(text: noteSpan, textDirection: TextDirection.ltr)..layout();
      final tagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - (noteTp.width / 2) - 4, pos.dy + 14, noteTp.width + 8, noteTp.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(tagRect, Paint()..color = Colors.black.withValues(alpha: 0.85));
      canvas.drawRRect(tagRect, Paint()..color = marker.color..style = PaintingStyle.stroke..strokeWidth = 1);
      noteTp.paint(canvas, Offset(pos.dx - (noteTp.width / 2), pos.dy + 16));
    }
  }

  @override
  bool shouldRepaint(covariant CarDamageDiagramPainter oldDelegate) => true;

  // Static hit detection helper to identify car view and panel from tap coordinate
  static Map<String, String> detectPanelFromPosition(Offset rel) {
    final x = rel.dx;
    final y = rel.dy;

    if (y < 0.26) {
      // Top Area: Driver Side
      if (x < 0.35) return {'view': 'Left Side', 'panel': 'Left Front Fender / Wheel'};
      if (x < 0.52) return {'view': 'Left Side', 'panel': 'Left Front Door'};
      if (x < 0.70) return {'view': 'Left Side', 'panel': 'Left Rear Door'};
      return {'view': 'Left Side', 'panel': 'Left Quarter Panel / Rear Wheel'};
    } else if (y > 0.68) {
      // Bottom Area: Passenger Side
      if (x < 0.35) return {'view': 'Right Side', 'panel': 'Right Front Fender / Wheel'};
      if (x < 0.52) return {'view': 'Right Side', 'panel': 'Right Front Door'};
      if (x < 0.70) return {'view': 'Right Side', 'panel': 'Right Rear Door'};
      return {'view': 'Right Side', 'panel': 'Right Quarter Panel / Rear Wheel'};
    } else {
      // Middle row: Left = Front, Center = Top, Right = Rear
      if (x < 0.24) {
        if (y < 0.42) return {'view': 'Front', 'panel': 'Front Windshield / Roof'};
        if (y < 0.58) return {'view': 'Front', 'panel': 'Front Grille & Headlights'};
        return {'view': 'Front', 'panel': 'Front Bumper & Fog Lights'};
      } else if (x > 0.76) {
        if (y < 0.42) return {'view': 'Rear', 'panel': 'Rear Windshield'};
        if (y < 0.58) return {'view': 'Rear', 'panel': 'Boot Lid / Taillights'};
        return {'view': 'Rear', 'panel': 'Rear Bumper & Lower Diffuser'};
      } else {
        // Center: Top View
        if (x < 0.40) return {'view': 'Top', 'panel': 'Bonnet / Hood'};
        if (x < 0.50) return {'view': 'Top', 'panel': 'Front Windshield'};
        if (x < 0.68) return {'view': 'Top', 'panel': 'Roof & Sunroof'};
        if (x < 0.80) return {'view': 'Top', 'panel': 'Rear Windshield'};
        return {'view': 'Top', 'panel': 'Trunk / Boot Lid'};
      }
    }
  }
}
