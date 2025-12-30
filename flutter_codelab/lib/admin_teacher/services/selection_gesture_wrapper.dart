// lib/widgets/selection_gesture_wrapper.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// --- DEFINITIVE TYPEDEFS ---
// Use the exact signature required by the LongPressGestureRecognizer
typedef LongPressStartCallback = void Function(LongPressStartDetails details);
typedef LongPressMoveUpdateCallback = void Function(LongPressMoveUpdateDetails details);
typedef LongPressEndCallback = void Function(LongPressEndDetails details);
// Note: The onLongPressEnd in admin_view_achievement_page.dart uses (_) => _endDrag(),
// which ignores the details object, making it compatible with this type.
// ---------------------------

class SelectionGestureWrapper extends StatelessWidget {
  final Widget child;
  final bool isDesktop;
  final Set<String> selectedIds;
  final Map<String, GlobalKey> itemKeys;

  final LongPressStartCallback onLongPressStart;
  final LongPressMoveUpdateCallback onLongPressMoveUpdate;
  final LongPressEndCallback onLongPressEnd;

  const SelectionGestureWrapper({
    super.key,
    required this.child,
    required this.isDesktop,
    required this.selectedIds,
    required this.itemKeys,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    // Setting a shorter hold time to initiate drag-select faster (200ms)
    const Duration selectionHoldDuration = Duration(milliseconds: 200);

    return RawGestureDetector(
      // Configure the LongPressGestureRecognizer with a custom duration
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
        // CORRECTION: Use GestureRecognizerFactoryWithHandlers
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          // Builder function: creates the new recognizer instance
              () => LongPressGestureRecognizer(
            duration: selectionHoldDuration,
          ),
          // Initializer function: sets the callbacks
              (LongPressGestureRecognizer instance) {
            instance
              ..onLongPressStart = onLongPressStart
              ..onLongPressMoveUpdate = onLongPressMoveUpdate
              ..onLongPressEnd = onLongPressEnd;
          },
        ),
      },
      // HitTestBehavior.translucent is essential to allow taps to pass through
      // to the underlying InkWell/ListTile when not in selection mode.
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
