import 'package:flutter/material.dart';

import 'package:code_play/destinations.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class DisappearingNavigationRail extends StatelessWidget {
  const DisappearingNavigationRail({
    super.key,
    required this.backgroundColor,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.isExtended,
    // REMOVED: required this.onMenuPressed,
    this.onAddButtonPressed,
    // REMOVED: required this.onLogoutPressed,
  });

  final Color backgroundColor;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool isExtended;
  // REMOVED: final VoidCallback onMenuPressed;
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
    final List<NavigationRailDestination> allDestinations = destinations.map((
      d,
    ) {
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
          // REMOVED: Menu Icon Button
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

