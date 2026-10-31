import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/inspection_model.dart';
import '../models/diagram_marker_model.dart';
import 'car_damage_diagram_painter.dart';

enum DiagramInteractionMode {
  placeMarker,
  freehandDraw,
  eraser,
}

class VehicleDiagramWidget extends StatefulWidget {
  final List<InspectionPartItem> parts;
  final List<DiagramMarker> markers;
  final List<DrawingStroke> strokes;
  final Function(InspectionPartItem part)? onPartTap;
  final Function(List<DiagramMarker> markers)? onMarkersChanged;
  final Function(List<DrawingStroke> strokes)? onStrokesChanged;
  final VoidCallback onAddCustomPart;

  const VehicleDiagramWidget({
    super.key,
    required this.parts,
    this.markers = const [],
    this.strokes = const [],
    this.onPartTap,
    this.onMarkersChanged,
    this.onStrokesChanged,
    required this.onAddCustomPart,
  });

  @override
  State<VehicleDiagramWidget> createState() => _VehicleDiagramWidgetState();
}

class _VehicleDiagramWidgetState extends State<VehicleDiagramWidget> {
  DiagramInteractionMode _mode = DiagramInteractionMode.placeMarker;

  // Selected Defect Type for Pin Dropping
  String _selectedDefectType = 'Dent';
  Color _selectedMarkerColor = const Color(0xFFFF3B30);

  // Drawing mode properties
  Color _penColor = const Color(0xFFFF3B30);
  final double _penWidth = 3.0;
  DrawingStroke? _currentStroke;

  late List<DiagramMarker> _markers;
  late List<DrawingStroke> _strokes;
  String? _hoveredMarkerId;

  final Map<String, Color> _defectTypes = {
    'Dent': const Color(0xFFFF3B30),
    'Scratch': const Color(0xFFFF9500),
    'Chip': const Color(0xFFFFCC00),
    'Crack': const Color(0xFFAF52DE),
    'Repaint': const Color(0xFF007AFF),
    'Swirls': const Color(0xFF34C759),
    'Note': const Color(0xFF5AC8FA),
  };

  @override
  void initState() {
    super.initState();
    _markers = List.from(widget.markers);
    _strokes = List.from(widget.strokes);
  }

  @override
  void didUpdateWidget(covariant VehicleDiagramWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers) {
      _markers = List.from(widget.markers);
    }
    if (widget.strokes != oldWidget.strokes) {
      _strokes = List.from(widget.strokes);
    }
  }

  void _notifyMarkers() {
    widget.onMarkersChanged?.call(_markers);
  }

  void _notifyStrokes() {
    widget.onStrokesChanged?.call(_strokes);
  }

  void _handleCanvasTap(Offset localPos, Size canvasSize) {
    if (_mode != DiagramInteractionMode.placeMarker) return;

    final relX = (localPos.dx / canvasSize.width).clamp(0.0, 1.0);
    final relY = (localPos.dy / canvasSize.height).clamp(0.0, 1.0);

    // 1. Check if user tapped an existing marker to edit/delete it
    for (final m in _markers) {
      final mx = m.x * canvasSize.width;
      final my = m.y * canvasSize.height;
      final distance = (Offset(mx, my) - localPos).distance;
      if (distance <= 20) {
        _showMarkerDetailsDialog(m);
        return;
      }
    }

    // 2. Otherwise, drop a new marker at this position
    final detected = CarDamageDiagramPainter.detectPanelFromPosition(Offset(relX, relY));
    _showAddMarkerDialog(relX, relY, detected['view']!, detected['panel']!);
  }

  void _showAddMarkerDialog(double x, double y, String view, String panel) {
    final noteCtrl = TextEditingController();
    String currentType = _selectedDefectType;
    Color currentColor = _selectedMarkerColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: currentColor,
                  child: Text(
                    currentType.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Mark $currentType on $panel', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Defect Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _defectTypes.entries.map((e) {
                      final isSelected = currentType == e.key;
                      return ChoiceChip(
                        label: Text(e.key),
                        selected: isSelected,
                        selectedColor: e.value.withValues(alpha: 0.35),
                        avatar: CircleAvatar(radius: 6, backgroundColor: e.value),
                        onSelected: (val) {
                          if (val) {
                            setDlgState(() {
                              currentType = e.key;
                              currentColor = e.value;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: noteCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Defect Description / Notes',
                      hintText: 'e.g., Deep scratch 6cm, Dent from door impact',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newMarker = DiagramMarker(
                    id: 'mark_${const Uuid().v4().substring(0, 8)}',
                    x: x,
                    y: y,
                    defectType: currentType,
                    panelName: panel,
                    viewName: view,
                    note: noteCtrl.text.trim(),
                    color: currentColor,
                  );

                  setState(() {
                    _markers.add(newMarker);
                  });
                  _notifyMarkers();

                  // Also create or sync with InspectionPartItem
                  widget.onPartTap?.call(InspectionPartItem(
                    partName: panel,
                    view: view,
                    condition: currentType,
                    damageDescription: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : currentType,
                    hasDamage: true,
                  ));

                  Navigator.pop(ctx);
                },
                child: const Text('Place Mark'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMarkerDetailsDialog(DiagramMarker marker) {
    final noteCtrl = TextEditingController(text: marker.note);
    String currentType = marker.defectType;
    Color currentColor = marker.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: currentColor,
                  child: Text(
                    marker.shortCode,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${marker.defectType}: ${marker.panelName}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('View: ${marker.viewName}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                  const SizedBox(height: 10),
                  const Text('Defect Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _defectTypes.entries.map((e) {
                      final isSelected = currentType == e.key;
                      return ChoiceChip(
                        label: Text(e.key),
                        selected: isSelected,
                        selectedColor: e.value.withValues(alpha: 0.35),
                        avatar: CircleAvatar(radius: 6, backgroundColor: e.value),
                        onSelected: (val) {
                          if (val) {
                            setDlgState(() {
                              currentType = e.key;
                              currentColor = e.value;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Remarks',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () {
                  setState(() {
                    _markers.removeWhere((m) => m.id == marker.id);
                  });
                  _notifyMarkers();
                  Navigator.pop(ctx);
                },
                child: const Text('Delete Mark'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updated = DiagramMarker(
                    id: marker.id,
                    x: marker.x,
                    y: marker.y,
                    defectType: currentType,
                    panelName: marker.panelName,
                    viewName: marker.viewName,
                    note: noteCtrl.text.trim(),
                    color: currentColor,
                  );

                  setState(() {
                    final idx = _markers.indexWhere((m) => m.id == marker.id);
                    if (idx != -1) _markers[idx] = updated;
                  });
                  _notifyMarkers();
                  Navigator.pop(ctx);
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _clearAllMarks() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Diagram?'),
        content: const Text('This will remove all placed defect markers and hand-drawn strokes from the vehicle diagram.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              setState(() {
                _markers.clear();
                _strokes.clear();
              });
              _notifyMarkers();
              _notifyStrokes();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text(
                      'Vehicle Body Inspection Diagram',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _clearAllMarks,
                      icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                      label: const Text('Clear Diagram', style: TextStyle(fontSize: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onAddCustomPart,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Add Custom Part', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Instruction prompt matching image
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132B21) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '* Should any defects be detected in the inspection, Indicate them with marks on the diagram.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Interactive Mode Selector & Palette Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  // Mode Segmented Buttons
                  SegmentedButton<DiagramInteractionMode>(
                    segments: const [
                      ButtonSegment(
                        value: DiagramInteractionMode.placeMarker,
                        icon: Icon(Icons.location_on_rounded, size: 16),
                        label: Text('Mark Defect', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: DiagramInteractionMode.freehandDraw,
                        icon: Icon(Icons.draw_rounded, size: 16),
                        label: Text('Draw Pen', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: DiagramInteractionMode.eraser,
                        icon: Icon(Icons.cleaning_services_rounded, size: 16),
                        label: Text('Eraser', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (newSet) {
                      setState(() => _mode = newSet.first);
                    },
                  ),

                  // Mode-Specific Controls
                  if (_mode == DiagramInteractionMode.placeMarker) ...[
                    // Defect Type Selector Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _defectTypes.entries.map((e) {
                        final isSel = _selectedDefectType == e.key;
                        return ChoiceChip(
                          label: Text(e.key, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          selectedColor: e.value.withValues(alpha: 0.35),
                          avatar: CircleAvatar(radius: 5, backgroundColor: e.value),
                          visualDensity: VisualDensity.compact,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedDefectType = e.key;
                                _selectedMarkerColor = e.value;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ] else if (_mode == DiagramInteractionMode.freehandDraw) ...[
                    // Pen Color Palette & Width
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...[
                          const Color(0xFFFF3B30),
                          const Color(0xFFFF9500),
                          const Color(0xFFFFCC00),
                          const Color(0xFF34C759),
                          const Color(0xFF007AFF),
                          Colors.white,
                        ].map((c) {
                          final isSel = _penColor == c;
                          return GestureDetector(
                            onTap: () => setState(() => _penColor = c),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.undo_rounded, size: 20),
                          tooltip: 'Undo Stroke',
                          onPressed: _strokes.isNotEmpty
                              ? () {
                                  setState(() => _strokes.removeLast());
                                  _notifyStrokes();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ] else ...[
                    TextButton.icon(
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear All Strokes', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() => _strokes.clear());
                        _notifyStrokes();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // The Interactive Diagram Canvas
            LayoutBuilder(
              builder: (context, constraints) {
                final canvasWidth = constraints.maxWidth;
                final canvasHeight = (canvasWidth * 0.70).clamp(380.0, 560.0);
                final canvasSize = Size(canvasWidth, canvasHeight);

                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                    onTapUp: (details) => _handleCanvasTap(details.localPosition, canvasSize),
                    onPanStart: (details) {
                      if (_mode == DiagramInteractionMode.freehandDraw) {
                        setState(() {
                          _currentStroke = DrawingStroke(
                            points: [details.localPosition],
                            color: _penColor,
                            strokeWidth: _penWidth,
                          );
                        });
                      }
                    },
                    onPanUpdate: (details) {
                      if (_mode == DiagramInteractionMode.freehandDraw && _currentStroke != null) {
                        setState(() {
                          _currentStroke!.points.add(details.localPosition);
                        });
                      } else if (_mode == DiagramInteractionMode.eraser) {
                        // Erase strokes near touch
                        setState(() {
                          _strokes.removeWhere((stroke) {
                            return stroke.points.any((p) => (p - details.localPosition).distance < 20);
                          });
                        });
                        _notifyStrokes();
                      }
                    },
                    onPanEnd: (details) {
                      if (_mode == DiagramInteractionMode.freehandDraw && _currentStroke != null) {
                        setState(() {
                          _strokes.add(_currentStroke!);
                          _currentStroke = null;
                        });
                        _notifyStrokes();
                      }
                    },
                    child: CustomPaint(
                      size: canvasSize,
                      painter: CarDamageDiagramPainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        markers: _markers,
                        isDarkMode: isDark,
                        hoveredOrSelectedMarkerId: _hoveredMarkerId,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Defect Counts & Statistics Summary Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _markers.isEmpty ? Colors.grey.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_markers.length} Defects Marked',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _markers.isEmpty ? AppColors.textDarkSecondary : AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_strokes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_strokes.length} Drawing Markups',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _defectTypes.keys.map((type) {
                      final count = _markers.where((m) => m.defectType.toLowerCase() == type.toLowerCase()).length;
                      if (count == 0) return const SizedBox.shrink();
                      final color = _defectTypes[type]!;
                      return Chip(
                        avatar: CircleAvatar(radius: 6, backgroundColor: color),
                        label: Text('$count $type', style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
