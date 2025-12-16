// lib/widgets/note_grid_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/grid_layout_view.dart';

class NoteGridLayout extends StatelessWidget {
  final List<Map<String, dynamic>> notes; // Renamed for clarity
  final bool isStudent;
  final Set<dynamic> selectedIds;
  final void Function(dynamic) onToggleSelection;
  final Map<dynamic, GlobalKey> itemKeys;
  
  // The parameter to accept the tap callback (for navigation)
  final void Function(dynamic)? onTap; 

  const NoteGridLayout({
    super.key,
    required this.notes,
    required this.isStudent,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.itemKeys,
    this.onTap, 
  });

  // Custom builder for Note card content
  Widget _buildNoteCardContent(
    BuildContext context, 
    Map<String, dynamic> item, 
    dynamic id, 
    GlobalKey key,
  ) {
    final String title = item['title'];
    final IconData icon = item['icon'] ?? Icons.note;
    final Color color = item['color'] ?? Colors.blue;
    final String? preview = item['preview'];

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(icon, color: color.withOpacity(0.1)),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 4.0, 8.0),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  preview ?? 'Tap to view note content...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridViewLayout(
      items: notes,
      selectedIds: selectedIds,
      onToggleSelection: onToggleSelection,
      itemKeys: itemKeys,
      module: GridModule.note,
      itemBuilder: _buildNoteCardContent,
      // Pass the navigation function directly to GridViewLayout's onTap
      onTap: onTap,
    );
  }
}