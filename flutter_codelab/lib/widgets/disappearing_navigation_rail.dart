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
        final int i = entry.key;
        final d = entry.value;
        final bool isSelected = selectedIndex == i;

        return NavigationRailDestination(
          icon: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Icon(
              d.icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          selectedIcon: Container(
            //width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal:16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.25),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Icon(
              d.selectedIcon,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          label: Text(
            d.label,
            style: TextStyle(
              color:
                  isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
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
            // Add button logic here
          } else {
            onDestinationSelected?.call(index - 2);
          }
        },
        extended: isExtended,
        groupAlignment: -1.0,
        useIndicator: false,
        destinations: allDestinations,
      ),
    );
  }
}