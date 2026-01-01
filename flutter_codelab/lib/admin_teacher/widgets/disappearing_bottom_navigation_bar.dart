import 'package:flutter/material.dart';

import 'package:flutter_codelab/destinations.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

class DisappearingBottomNavigationBar extends StatelessWidget {
  const DisappearingBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

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
          final List<String> labels = [
            l10n.users,
            l10n.games,
            l10n.notes,
            l10n.classes,
            l10n.achievements,
            l10n.aiChat,
            l10n.feedback,
          ];
          return destinations.asMap().entries.map<NavigationDestination>((
            entry,
          ) {
            final idx = entry.key;
            final d = entry.value;
            return NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: labels[idx],
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

