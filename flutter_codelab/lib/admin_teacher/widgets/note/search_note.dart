import 'package:flutter/material.dart';

class SearchNote extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchCount;
  final int totalMatches;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClose;

  const SearchNote({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.matchCount,
    required this.totalMatches,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: 16,
      right: 16,
      width: screenWidth > 350 ? 350 : screenWidth - 32,
      child: Material(
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerHigh,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  cursorColor: colorScheme.primary,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Find...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                Text(
                  totalMatches > 0
                      ? '${matchCount + 1}/$totalMatches'
                      : 'No results',
                  style: TextStyle(
                      color: totalMatches > 0
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.error,
                      fontSize: 14),
                ),
              IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: onPrev),
              IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 20),
                  onPressed: onNext),
              IconButton(
                  icon: const Icon(Icons.close, size: 20), onPressed: onClose),
            ],
          ),
        ),
      ),
    );
  }
}
