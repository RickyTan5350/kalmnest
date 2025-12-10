import 'package:flutter/material.dart';

import 'package:flutter_codelab/destinations.dart';

class DisappearingNavigationRail extends StatelessWidget {
  const DisappearingNavigationRail({
    super.key,
    required this.backgroundColor,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.isExtended,
    required this.onMenuPressed,
    this.onAddButtonPressed,
    // REMOVED: required this.onLogoutPressed,
  });

  final Color backgroundColor;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool isExtended;
  final VoidCallback onMenuPressed;
  final VoidCallback? onAddButtonPressed;
  // REMOVED: final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // The destinations no longer need the placeholder for the add button.
    final List<NavigationRailDestination> allDestinations =
    destinations.map((d) {
      return NavigationRailDestination(
        icon: Icon(d.icon),
        selectedIcon: Icon(d.selectedIcon),
        label: Text(d.label),
      );
    }).toList();

    return NavigationRail(
      selectedIndex: selectedIndex, // Simpler indexing now
      backgroundColor: backgroundColor,
      onDestinationSelected: onDestinationSelected,
      extended: isExtended,
      // Use the 'leading' property for the top-aligned buttons.
      leading: Column(
        children: [
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            // Use the FAB widget directly
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            backgroundColor: colorScheme.tertiaryContainer,
            foregroundColor: colorScheme.onTertiaryContainer,
            onPressed: onAddButtonPressed,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      groupAlignment: -0.95, // Adjust alignment to position destinations lower
      destinations: allDestinations,

      // ------------------------------------------------------------------
      // MODIFIED: Trailing widget is now an empty box
      // ------------------------------------------------------------------
      trailing: const SizedBox(),
      // ------------------------------------------------------------------
    );
  }
}