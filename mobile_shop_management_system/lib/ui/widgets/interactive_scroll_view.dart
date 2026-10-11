import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A bi-directional interactive scroll view designed for desktop & web productivity.
/// Supports simultaneous horizontal and vertical interactive scrollbars,
/// desktop mouse drag-to-scroll, trackpad gestures, and Shift+Wheel / horizontal wheel scrolling.
class InteractiveBiDirectionalScrollView extends StatefulWidget {
  final Widget child;
  final double? minWidth;
  final double? minHeight;
  final ScrollController? horizontalController;
  final ScrollController? verticalController;
  final bool enableHorizontalMouseWheel;

  const InteractiveBiDirectionalScrollView({
    super.key,
    required this.child,
    this.minWidth,
    this.minHeight,
    this.horizontalController,
    this.verticalController,
    this.enableHorizontalMouseWheel = true,
  });

  @override
  State<InteractiveBiDirectionalScrollView> createState() =>
      _InteractiveBiDirectionalScrollViewState();
}

class _InteractiveBiDirectionalScrollViewState
    extends State<InteractiveBiDirectionalScrollView> {
  late ScrollController _hCtrl;
  late ScrollController _vCtrl;
  bool _ownsHCtrl = false;
  bool _ownsVCtrl = false;

  @override
  void initState() {
    super.initState();
    if (widget.horizontalController != null) {
      _hCtrl = widget.horizontalController!;
    } else {
      _hCtrl = ScrollController();
      _ownsHCtrl = true;
    }

    if (widget.verticalController != null) {
      _vCtrl = widget.verticalController!;
    } else {
      _vCtrl = ScrollController();
      _ownsVCtrl = true;
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveBiDirectionalScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.horizontalController != oldWidget.horizontalController) {
      if (_ownsHCtrl) _hCtrl.dispose();
      if (widget.horizontalController != null) {
        _hCtrl = widget.horizontalController!;
        _ownsHCtrl = false;
      } else {
        _hCtrl = ScrollController();
        _ownsHCtrl = true;
      }
    }
    if (widget.verticalController != oldWidget.verticalController) {
      if (_ownsVCtrl) _vCtrl.dispose();
      if (widget.verticalController != null) {
        _vCtrl = widget.verticalController!;
        _ownsVCtrl = false;
      } else {
        _vCtrl = ScrollController();
        _ownsVCtrl = true;
      }
    }
  }

  @override
  void dispose() {
    if (_ownsHCtrl) _hCtrl.dispose();
    if (_ownsVCtrl) _vCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollBehavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
    );

    return ScrollConfiguration(
      behavior: scrollBehavior,
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
            if (isShiftPressed ||
                (widget.enableHorizontalMouseWheel &&
                    pointerSignal.scrollDelta.dx != 0)) {
              final delta = isShiftPressed
                  ? (pointerSignal.scrollDelta.dy != 0
                      ? pointerSignal.scrollDelta.dy
                      : pointerSignal.scrollDelta.dx)
                  : pointerSignal.scrollDelta.dx;
              if (_hCtrl.hasClients) {
                final target = (_hCtrl.offset + delta)
                    .clamp(0.0, _hCtrl.position.maxScrollExtent);
                _hCtrl.jumpTo(target);
              }
            }
          }
        },
        child: Scrollbar(
          controller: _vCtrl,
          thumbVisibility: true,
          interactive: true,
          child: SingleChildScrollView(
            controller: _vCtrl,
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Scrollbar(
              controller: _hCtrl,
              thumbVisibility: true,
              interactive: true,
              notificationPredicate: (notif) => notif.depth == 1,
              child: SingleChildScrollView(
                controller: _hCtrl,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: widget.minWidth ?? 0,
                    minHeight: widget.minHeight ?? 0,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
