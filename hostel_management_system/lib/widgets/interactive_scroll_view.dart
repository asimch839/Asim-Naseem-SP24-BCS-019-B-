import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// A bi-directional scroll view wrapper providing fully interactive,
/// mouse-draggable vertical (right side) and horizontal (bottom) scrollbars
/// pinned to the viewport edges.
class InteractiveBiDirectionalScrollView extends StatefulWidget {
  final Widget child;
  final double minWidth;
  final double minHeight;

  const InteractiveBiDirectionalScrollView({
    super.key,
    required this.child,
    this.minWidth = 1050.0,
    this.minHeight = 680.0,
  });

  @override
  State<InteractiveBiDirectionalScrollView> createState() =>
      _InteractiveBiDirectionalScrollViewState();
}

class _InteractiveBiDirectionalScrollViewState
    extends State<InteractiveBiDirectionalScrollView> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = constraints.maxWidth < widget.minWidth
            ? widget.minWidth
            : constraints.maxWidth;
        final targetHeight = constraints.maxHeight < widget.minHeight
            ? widget.minHeight
            : constraints.maxHeight;

        final hasVert = _verticalController.hasClients;
        final hasHoriz = _horizontalController.hasClients;

        return RawScrollbar(
          controller: _verticalController,
          scrollbarOrientation: ScrollbarOrientation.right,
          thumbVisibility: hasVert,
          trackVisibility: hasVert,
          interactive: true,
          thickness: 12,
          radius: const Radius.circular(8),
          thumbColor: AppColors.primary.withValues(alpha: 0.8),
          trackColor: AppColors.surfaceSecondary,
          notificationPredicate: (notif) => notif.metrics.axis == Axis.vertical,
          child: RawScrollbar(
            controller: _horizontalController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            thumbVisibility: hasHoriz,
            trackVisibility: hasHoriz,
            interactive: true,
            thickness: 12,
            radius: const Radius.circular(8),
            thumbColor: AppColors.primary.withValues(alpha: 0.8),
            trackColor: AppColors.surfaceSecondary,
            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                  if (isShiftPressed || pointerSignal.scrollDelta.dx != 0) {
                    final delta = pointerSignal.scrollDelta.dx != 0
                        ? pointerSignal.scrollDelta.dx
                        : pointerSignal.scrollDelta.dy;
                    if (_horizontalController.hasClients) {
                      final newOffset = (_horizontalController.offset + delta).clamp(
                        0.0,
                        _horizontalController.position.maxScrollExtent,
                      );
                      _horizontalController.jumpTo(newOffset);
                    }
                  }
                }
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: targetWidth,
                        minHeight: targetHeight,
                      ),
                      child: SizedBox(
                        width: targetWidth,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

