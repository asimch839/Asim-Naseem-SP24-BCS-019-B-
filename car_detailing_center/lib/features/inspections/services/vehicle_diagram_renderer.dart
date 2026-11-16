import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/diagram_marker_model.dart';
import '../widgets/car_damage_diagram_painter.dart';

class VehicleDiagramRenderer {
  /// Renders the vehicle 5-view blueprint diagram with any marked defect pins and strokes
  /// into a high-resolution PNG image byte buffer (Uint8List).
  static Future<Uint8List> renderToPngBytes({
    List<DiagramMarker> markers = const [],
    List<DrawingStroke> strokes = const [],
    double width = 1000,
    double height = 620,
    bool isDarkMode = true,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    final painter = CarDamageDiagramPainter(
      strokes: strokes,
      markers: markers,
      isDarkMode: isDarkMode,
    );
    painter.paint(canvas, Size(width, height));
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

