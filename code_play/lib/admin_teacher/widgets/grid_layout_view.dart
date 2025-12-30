// lib/widgets/grid_view_layout.dart
import 'package:flutter/material.dart';

// 1. UPDATE: Add new modules to the Enum
enum GridModule { achievement, note, games, support, user }

typedef GridItemBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> item,
  dynamic id,
  GlobalKey key,
);

class GridViewLayout extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Set<dynamic> selectedIds;
  final void Function(dynamic) onToggleSelection;
  final Map<dynamic, GlobalKey> itemKeys;
  final GridModule module;
  final GridItemBuilder itemBuilder;
  final void Function(dynamic)? onTap;

  // 2. NEW: Add parameters for customization
  final double childAspectRatio; // To adjust card height/width ratio
  final String? idKey; // To specify which key to use for ID (e.g. 'gameId')
  final bool enableSelection; // To explicit enable/disable long-press selection

  const GridViewLayout({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.itemKeys,
    required this.module,
    required this.itemBuilder,
    this.onTap,
    // Defaults ensure backward compatibility
    this.childAspectRatio = 0.9, 
    this.idKey,
    this.enableSelection = false, 
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverGrid.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250.0,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          // 3. USE: The passed aspect ratio (Games might need 1.5, Users 0.8, etc.)
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          final item = items[index];

          // 4. LOGIC: specific ID lookup or default to 'id'
          // If idKey is provided, use it. 
          // Otherwise, stick to 'achievementId' for achievements, and 'id' for everything else.
          final String keyToUse = idKey ?? 
              (module == GridModule.achievement ? 'achievementId' : 'id');
              
          final dynamic id = item[keyToUse];

          if (id == null) {
            return const SizedBox.shrink();
          }

          final GlobalKey key = itemKeys.putIfAbsent(id, () => GlobalKey());

          return Container(
            key: key,
            child: _buildItemContainer(context, item, id, key),
          );
        },
      ),
    );
  }

  Widget _buildItemContainer(
    BuildContext context,
    Map<String, dynamic> item,
    dynamic id,
    GlobalKey key,
  ) {
    final bool isSelected = selectedIds.contains(id);

    // 5. LOGIC: Determine if selection is allowed
    // Allowed if explicitly enabled OR if it's the 'note' module (backward compatibility)
    final bool canSelect = enableSelection || module == GridModule.note;

    return Card(
      elevation: 1.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          if (selectedIds.isNotEmpty) {
            onToggleSelection(id);
          } else if (onTap != null) {
            onTap!(id);
          }
        },
        // 6. USE: The unified selection logic
        onLongPress: canSelect ? () => onToggleSelection(id) : null,
        child: itemBuilder(context, item, id, key),
      ),
    );
  }
}