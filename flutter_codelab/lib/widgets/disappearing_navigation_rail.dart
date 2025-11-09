import 'package:flutter/material.dart';

import '../destinations.dart';

class DisappearingNavigationRail extends StatelessWidget {
  const DisappearingNavigationRail({
    super.key,
    required this.backgroundColor,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.isExtended,
    required this.onMenuPressed,
  });

  final Color backgroundColor;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool isExtended;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<NavigationRailDestination> allDestinations = [
      // Item 0: The Menu button
      NavigationRailDestination(icon: Icon(Icons.menu), label: Text('Menu')),
      // Item 1: The Add button (styled to look like your FAB)
      NavigationRailDestination(
        icon: Container(
          width: 40, // FAB.small size
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Icon(Icons.add, color: colorScheme.onTertiaryContainer),
        ),
        label: Text('Create'),
      ),
      // The rest of your original destinations
      ...destinations.map((d) {
        return NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: Text(d.label),
        );
      }),
    ];

    return NavigationRail(
      // Add 2 to the selectedIndex to account for Menu and Add
      selectedIndex: selectedIndex + 2,
      backgroundColor: backgroundColor,
      onDestinationSelected: (int index) {
        if (index == 0) {
          // This is the Menu button
          onMenuPressed();
        } else if (index == 1) {
          // This is the Add button
          // Add your "onPressed" logic here
        } else {
          // This is a real destination, so call the original callback
          // subtracting 2 to get the correct original index
          onDestinationSelected?.call(index - 2);
        }
      },
      extended: isExtended,
      // leading is removed
      groupAlignment: -1.0, // Aligns all items to the top
      destinations: allDestinations, // Use our new combined list
    );
  }
}
