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
    this.onAddButtonPressed,
    // REMOVED: required this.onLogoutPressed,
  });

  final Color backgroundColor;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool isExtended;
  final VoidCallback? onAddButtonPressed;
  // REMOVED: final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Map your destinations using the localized labels from your list
    final List<String> labels = [
      l10n.users,
      l10n.games,
      l10n.notes,
      l10n.classes,
      l10n.achievements,
      l10n.aiChat,
      l10n.feedback,
    ];

    final List<NavigationRailDestination> allDestinations = [];
    for (int i = 0; i < destinations.length; i++) {
      final d = destinations[i];
      allDestinations.add(
        NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: Text(labels[i]),
        ),
      );
    }

    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Anchors the FAB area to the left
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
    );
  }
}
