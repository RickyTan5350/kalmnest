import 'package:flutter/material.dart';

import 'package:flutter_codelab/destinations.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

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

    final l10n = AppLocalizations.of(context)!;
    final List<String> labels = [
      l10n.users,
      l10n.games,
      l10n.notes,
      l10n.classes,
      l10n.achievements,
      l10n.aiChat,
      l10n.feedback,
    ];

    // The destinations no longer need the placeholder for the add button.
    final List<NavigationRailDestination> allDestinations = [];
    for (int i = 0; i < destinations.length; i++) {
      allDestinations.add(
        NavigationRailDestination(
          icon: Icon(destinations[i].icon),
          selectedIcon: Icon(destinations[i].selectedIcon),
          label: Text(labels[i]),
        ),
      );
    }

    return NavigationRail(
      selectedIndex: selectedIndex, // Simpler indexing now
      backgroundColor: backgroundColor,
      onDestinationSelected: onDestinationSelected,
      extended: isExtended,
      // Use the 'leading' property for the top-aligned buttons.
      leading: Column(
        children: [
          IconButton(onPressed: onMenuPressed, icon: const Icon(Icons.menu)),
          const SizedBox(height: 8),
          FloatingActionButton(
            // Use the FAB widget directly
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
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
