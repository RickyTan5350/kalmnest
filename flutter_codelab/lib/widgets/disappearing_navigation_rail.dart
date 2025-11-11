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
    this.onAddButtonPressed,
  });

  final Color backgroundColor;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool isExtended;
  final VoidCallback onMenuPressed;
  final VoidCallback? onAddButtonPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<NavigationRailDestination> allDestinations = [
      // Item 0: The Menu button
      const NavigationRailDestination(
        icon: Icon(Icons.menu),
        label: Text('Menu'),
      ),
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
      ...destinations.asMap().entries.map((entry) {
        // final int i = entry.key; // Index not needed for styling now
        final d = entry.value;

        return NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: Text(d.label),
        );
      }).toList(),
    ];

    // This Theme wrapper removes the splash/ripple and other hover effects
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex + 2, // +2 for Menu & Add
        backgroundColor: backgroundColor,
        onDestinationSelected: (int index) {
          if (index == 0) {
            onMenuPressed(); // Menu button
          } else if (index == 1) {
            onAddButtonPressed?.call();
          } else {
            onDestinationSelected?.call(index - 2);
          }
        },
        extended: isExtended,
        groupAlignment: -1.0,
        useIndicator: true,
        destinations: allDestinations,
      ),
    );
  }
}