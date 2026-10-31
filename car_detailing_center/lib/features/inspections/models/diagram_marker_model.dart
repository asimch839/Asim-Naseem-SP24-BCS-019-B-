import 'package:flutter/material.dart';

class DiagramMarker {
  final String id;
  final double x; // Relative position 0.0 to 1.0
  final double y; // Relative position 0.0 to 1.0
  final String defectType; // 'Dent', 'Scratch', 'Chip', 'Crack', 'Repaint', 'Swirls', 'Note'
  final String panelName;
  final String viewName;
  final String note;
  final Color color;

  DiagramMarker({
    required this.id,
    required this.x,
    required this.y,
    required this.defectType,
    required this.panelName,
    required this.viewName,
    this.note = '',
    required this.color,
  });

  String get shortCode {
    switch (defectType.toLowerCase()) {
      case 'dent':
        return 'D';
      case 'scratch':
        return 'S';
      case 'chip':
      case 'stone chip':
        return 'C';
      case 'crack':
        return 'CR';
      case 'repaint':
      case 'repainted':
        return 'R';
      case 'swirls':
      case 'scuff':
        return 'SW';
      case 'rust':
        return 'RU';
      default:
        return 'N';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'x': x,
    'y': y,
    'defectType': defectType,
    'panelName': panelName,
    'viewName': viewName,
    'note': note,
    'color': color.toARGB32(),
  };

  factory DiagramMarker.fromMap(Map<String, dynamic> map) => DiagramMarker(
    id: map['id'] ?? '',
    x: (map['x'] as num?)?.toDouble() ?? 0.0,
    y: (map['y'] as num?)?.toDouble() ?? 0.0,
    defectType: map['defectType'] ?? 'Scratch',
    panelName: map['panelName'] ?? 'Body Panel',
    viewName: map['viewName'] ?? 'Vehicle View',
    note: map['note'] ?? '',
    color: Color((map['color'] as num?)?.toInt() ?? 0xFFFF3B30),
  );
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.color,
    this.strokeWidth = 3.0,
  });

  Map<String, dynamic> toMap() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': color.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  factory DrawingStroke.fromMap(Map<String, dynamic> map) {
    final pts = (map['points'] as List? ?? []).map((p) {
      return Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
    }).toList();
    return DrawingStroke(
      points: pts,
      color: Color((map['color'] as num?)?.toInt() ?? 0xFFFF3B30),
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 3.0,
    );
  }
}
