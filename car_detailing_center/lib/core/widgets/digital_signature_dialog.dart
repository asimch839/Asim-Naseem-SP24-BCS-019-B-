import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../services/local_storage_service.dart';

class DigitalSignatureDialog extends StatefulWidget {
  final String title;
  final String signerRole;

  const DigitalSignatureDialog({
    super.key,
    required this.title,
    required this.signerRole,
  });

  @override
  State<DigitalSignatureDialog> createState() => _DigitalSignatureDialogState();
}

class _DigitalSignatureDialogState extends State<DigitalSignatureDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSaving = false;
  Size _actualCanvasSize = const Size(500, 220);

  void _onPanStart(DragStartDetails details) {
    final localPosition = details.localPosition;
    setState(() {
      _currentStroke = [localPosition];
      _strokes.add(_currentStroke);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _currentStroke = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<void> _saveSignature() async {
    if (_strokes.isEmpty) {
      Get.snackbar('Empty Signature', 'Please sign on the canvas before saving', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0, 0), const Offset(500, 220)),
      );

      // Draw white background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, 500, 220), bgPaint);

      // Draw baseline guide
      final linePaint = Paint()
        ..color = const Color(0xFFE0E0E0)
        ..strokeWidth = 1.0;
      canvas.drawLine(const Offset(30, 180), const Offset(470, 180), linePaint);

      // Draw signature strokes
      final strokePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3.0;

      final scaleX = _actualCanvasSize.width > 0 ? 500.0 / _actualCanvasSize.width : 1.0;
      final scaleY = _actualCanvasSize.height > 0 ? 220.0 / _actualCanvasSize.height : 1.0;

      for (final stroke in _strokes) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(
            Offset(stroke[i].dx * scaleX, stroke[i].dy * scaleY),
            Offset(stroke[i + 1].dx * scaleX, stroke[i + 1].dy * scaleY),
            strokePaint,
          );
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(500, 220);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode signature image');
      }

      final bytes = byteData.buffer.asUint8List();
      final fileName = 'sig_${widget.signerRole.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';

      final savedPath = await LocalStorageService.to.saveBytesLocally(
        bytes,
        fileName: fileName,
        subFolder: 'signatures',
      );

      if (savedPath != null) {
        Get.back(result: savedPath);
      } else {
        throw Exception('Could not save signature locally');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save digital signature: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = math.min(520.0, screenWidth - 32);
    final canvasWidth = math.max(240.0, dialogWidth - 32);
    final canvasHeight = (canvasWidth * 0.44).clamp(140.0, 220.0);
    _actualCanvasSize = Size(canvasWidth, canvasHeight);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      title: Row(
        children: [
          const Icon(Icons.draw_rounded, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign within the frame using touch screen, mouse, or stylus (${widget.signerRole}):',
                style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                width: canvasWidth,
                height: canvasHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      size: Size(canvasWidth, canvasHeight),
                      painter: _SignaturePainter(strokes: _strokes),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _strokes.isEmpty ? null : _clear,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Clear Signature'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                  Text(
                    _strokes.isEmpty ? 'Waiting for signature...' : '${_strokes.length} stroke(s) captured',
                    style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveSignature,
          icon: _isSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_rounded, size: 16),
          label: const Text('Save Signature'),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw signature guide line
    final guidePaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(20, size.height - 40), Offset(size.width - 20, size.height - 40), guidePaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
