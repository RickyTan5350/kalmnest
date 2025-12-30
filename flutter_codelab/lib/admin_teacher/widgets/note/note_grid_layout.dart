// lib/widgets/note_grid_layout.dart
import 'package:flutter/material.dart';
import 'package:code_play/admin_teacher/widgets/grid_layout_view.dart';
import 'package:code_play/theme.dart';

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
    final String? preview = item['preview'];
    final String topic = item['topic'] ?? 'Other'; // Get passed topic

    // Resolve Brand Colors
    final brandColors = Theme.of(context).extension<BrandColors>();
    Color topicColor;
    IconData topicIcon;

    switch (topic.toLowerCase()) {
      case 'html':
        topicColor = brandColors?.html ?? Colors.orange;
        topicIcon = Icons.html;
        break;
      case 'css':
        topicColor = brandColors?.css ?? Colors.blue;
        topicIcon = Icons.css;
        break;
      case 'js':
      case 'javascript':
        topicColor = brandColors?.javascript ?? Colors.yellow;
        topicIcon = Icons.javascript;
        break;
      case 'php':
        topicColor = brandColors?.php ?? Colors.indigo;
        topicIcon = Icons.php;
        break;

      default:
        topicColor = brandColors?.other ?? Colors.grey;
        topicIcon = Icons.folder_open;
    }

    // ACHIEVEMENT STYLE EFFECT with Dynamic Color/Icon
    return Stack(
      children: [
        // 1. Large Faded Background Icon (The Effect)
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(topicIcon, color: topicColor.withOpacity(0.1)),
            ),
          ),
        ),

        // 2. Foreground Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 4.0, 8.0),
              child: Row(
                children: [
                  Icon(topicIcon, color: topicColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    if (item['updatedAt'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Updated: ${item['updatedAt']}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 10,
                              ),
                        ),
                      ),
                  ],
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

