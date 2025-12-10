// lib/widgets/grid_layout_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'achievements/admin_achievement_detail.dart'; // Ensure this imports the updated file

class GridLayoutView extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final List<AchievementData> originalData; // <-- This holds the full data
  final Set<String> selectedIds;
  final void Function(String) onToggleSelection;
  final Map<String, GlobalKey> itemKeys;

  const GridLayoutView({
    super.key,
    required this.achievements,
    required this.originalData,
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
          final item = achievements[index]; // UI data (Map)
          final originalItem = originalData[index]; // Full data (Object)

          final String id = originalItem.achievementId!;
          final bool isSelected = selectedIds.contains(id);
          final GlobalKey key = itemKeys.putIfAbsent(id, () => GlobalKey());

          return Container(
              key: key,
              child: _buildAchievementCard(
                context,
                item,
                originalItem: originalItem, // <-- Pass the full object
                isSelected: isSelected,
                onToggle: () => onToggleSelection(id),
              )
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(
      BuildContext context,
      Map<String, dynamic> item,{
        required AchievementData originalItem, // <-- Receive full object
        required bool isSelected,
        required VoidCallback onToggle,
      }) {
    final String title = item['title'];
    final IconData icon = item['icon'];
    final Color color = item['color'];
    final String? preview = item['preview'];

    return Card(
      elevation: 1.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          if (selectedIds.isNotEmpty) {
            onToggle();
          } else {
            // Navigate passing the FULL DATA object
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminAchievementDetailPage(
                  initialData: originalItem, // Pass the partial object here
                ),
              ),
            );
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    icon,
                    color: color.withOpacity(0.1),
                  ),
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      preview ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
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