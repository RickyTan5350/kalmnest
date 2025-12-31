import 'package:flutter/material.dart';

import 'package:flutter_codelab/destinations.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

class DisappearingBottomNavigationBar extends StatelessWidget {
  const DisappearingBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<Destination> destinations;

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
          }
          return const TextStyle(fontSize: 10);
        }),
      ),
      child: NavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        destinations: () {
          final l10n = AppLocalizations.of(context)!;
          final Map<String, String> labelMap = {
            'User': l10n.users,
            'Game': l10n.games,
            'Note': l10n.notes,
            'Class': l10n.classes,
            'Achievement': l10n.achievements,
            'AI chat': l10n.aiChat,
            'Feedback': l10n.feedback,
          };
          return destinations.map<NavigationDestination>((d) {
            return NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: labelMap[d.label] ?? d.label,
            );
          }).toList();
        }(),
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

