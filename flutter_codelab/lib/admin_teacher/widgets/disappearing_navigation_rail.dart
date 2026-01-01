import 'package:flutter/material.dart';


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
  final List<NavigationRailDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;



    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Anchors the FAB area to the left
        children: [
          // --- GMAIL STYLE FAB AREA ---
          // A SizedBox of 72px matches the standard collapsed width of the Rail
          SizedBox(
            child: onAddButtonPressed != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: 12.0,
                      bottom: 12.0,
                      left: 12.0,
                      right: 4.0,
                    ),
                    child: isExtended
                        ? FloatingActionButton.extended(
                            isExtended: true,
                            onPressed: onAddButtonPressed,
                            icon: const Icon(Icons.add),
                            label: const Text("Create"), // Gmail style text label
                            backgroundColor: colorScheme.tertiaryContainer,
                            foregroundColor: colorScheme.onTertiaryContainer,
                          )
                        : Center(
                            // Center ensures the circular FAB stays perfectly
                            // aligned over the navigation icons below
                            child: FloatingActionButton(
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
                              ),
                              onPressed: onAddButtonPressed,
                              backgroundColor: colorScheme.tertiaryContainer,
                              foregroundColor: colorScheme.onTertiaryContainer,
                              child: const Icon(Icons.add),
                            ),
                          ),
                  )
                : null,
          ),
          // --- THE NAVIGATION RAIL ---
          Expanded(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              backgroundColor: backgroundColor,
              onDestinationSelected: onDestinationSelected,
              extended: isExtended,
              // groupAlignment -1.0 keeps icons at the top under the FAB
              groupAlignment: -1.0,
              destinations: destinations,
              trailing: const SizedBox(),
              // Leading is now null because the FAB is handled in the Column above
              leading: null,
            ),
          ),
        ],
      ),
    );
  }
}
