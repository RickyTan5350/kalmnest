import 'package:flutter/material.dart';
// Import BOTH detail pages
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_note_detail.dart';
import 'package:flutter_codelab/student/widgets/note/student_note_detail.dart';

class GridLayoutView extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final bool isStudent;
  final Set<dynamic> selectedIds;
  final void Function(dynamic) onToggleSelection;
  final Map<dynamic, GlobalKey> itemKeys;

  const GridLayoutView({
    super.key,
    required this.achievements,
    required this.isStudent,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.itemKeys,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverGrid.builder(
        itemCount: achievements.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250.0,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final item = achievements[index];
          final dynamic id = item['id'];
          final GlobalKey key = itemKeys.putIfAbsent(id, () => GlobalKey());

          return Container(
            key: key,
            child: _buildNoteCard(context, item, id),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Map<String, dynamic> item, dynamic id) {
    final String title = item['title'];
    final IconData icon = item['icon'] ?? Icons.note;
    final Color color = item['color'] ?? Colors.blue;
    final String? preview = item['preview'];
    final bool isSelected = selectedIds.contains(id);

    return Card(
      elevation: 1.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.outline.withOpacity(0.3), 
          width: isSelected ? 2.0 : 1.0
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          if (selectedIds.isNotEmpty) {
            onToggleSelection(id);
          } else {
            // FIX: Check isStudent to navigate to the correct page
            if (isStudent) {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => StudentNoteDetailPage(
                  noteId: id.toString(),
                  noteTitle: title,
                ),
              ));
            } else {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => AdminNoteDetailPage(
                  noteId: id.toString(),
                  noteTitle: title,
                  isStudent: false, // Required for admin logic
                ),
              ));
            }
          }
        },
        onLongPress: () => onToggleSelection(id),
        child: Stack(
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
        ),
      ),
    );
  }
}