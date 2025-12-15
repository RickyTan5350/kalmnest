import 'package:flutter/material.dart';
// REMOVED: Specific imports are no longer needed here. 
// Navigation logic is now handled by the parent (StudentViewPage or AdminViewNotePage).

class GridLayoutView extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final bool isStudent;
  final Set<dynamic> selectedIds;
  final void Function(dynamic) onToggleSelection;
  final Map<dynamic, GlobalKey> itemKeys;
  
  // 1. ADD: The parameter to accept the tap callback
  final void Function(dynamic)? onTap; 

  const GridLayoutView({
    super.key,
    required this.achievements,
    required this.isStudent,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.itemKeys,
    // 2. ADD: Add it to the constructor
    this.onTap, 
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
          // If we are in selection mode, tapping toggles selection
          if (selectedIds.isNotEmpty) {
            onToggleSelection(id);
          } 
          // 3. FIX: Otherwise, call the passed navigation function
          else if (onTap != null) {
            onTap!(id);
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