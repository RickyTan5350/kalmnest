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
    this.onAddButtonPressed,
    required this.destinations,
  });

  final Color backgroundColor;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool isExtended;
  final VoidCallback? onAddButtonPressed;
  final List<Destination> destinations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Map your destinations using the localized labels from your list
    final Map<String, String> labelMap = {
      'User': l10n.users,
      'Game': l10n.games,
      'Note': l10n.notes,
      'Class': l10n.classes,
      'Achievement': l10n.achievements,
      'AI chat': l10n.aiChat,
      'Feedback': l10n.feedback,
    };

    final List<NavigationRailDestination> allDestinations = [];
    for (var d in destinations) {
      allDestinations.add(
        NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: Text(labelMap[d.label] ?? d.label),
        ),
      );
    }

    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (onAddButtonPressed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FloatingActionButton(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
                onPressed: onAddButtonPressed,
                child: const Icon(Icons.add),
              ),
            )
          else
            // Maintain spacing even if button is hidden, or remove if desired.
            // Using SizedBox(height: 56) + Padding can keep layout stable, 
            // but usually hiding it is preferred. Let's hide it but keep top spacing.
            const SizedBox(height: 56),
          const SizedBox(height: 12),
          Expanded(
            child: NavigationRail(
              backgroundColor: backgroundColor,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              extended: isExtended,
              labelType: isExtended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.none,
              destinations: allDestinations,
            ),
          ),
        ],
      ),
    );
  }
}
