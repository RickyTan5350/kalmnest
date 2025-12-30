import 'package:flutter/material.dart';

class MouseFollowTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final TextStyle? textStyle;
  final Decoration? decoration;

  const MouseFollowTooltip({
    super.key,
    required this.message,
    required this.child,
    this.textStyle,
    this.decoration,
  });

  @override
  State<MouseFollowTooltip> createState() => _MouseFollowTooltipState();
}

class _MouseFollowTooltipState extends State<MouseFollowTooltip> {
  OverlayEntry? _overlayEntry;
  // ValueNotifier to update position efficiently without rebuilding the entire overlay
  final ValueNotifier<Offset> _positionNotifier = ValueNotifier(Offset.zero);

  void _onHover(final PointerEvent event) {
    _positionNotifier.value = event.position;
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => ValueListenableBuilder<Offset>(
        valueListenable: _positionNotifier,
        builder: (context, position, _) {
          // Adjust position to not be directly under the cursor
          return Positioned(
            left: position.dx + 12,
            top: position.dy + 12,
            child: IgnorePointer(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration:
                      widget.decoration ??
                      BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                  child: Text(
                    widget.message,
                    style:
                        widget.textStyle ??
                        const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _removeTooltip();
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => _removeTooltip(),
      // Ensure we remove tooltip if widget is tapped/navigates away generally
      // though lifecycle dispose handles navigation.
      child: widget.child,
    );
  }
}
