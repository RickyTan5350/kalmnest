import 'package:flutter/material.dart';

class Destination {
  const Destination(this.selectedIcon, this.icon,  this.label);
  final IconData icon;
  final String label;
  final IconData selectedIcon;
}

const List<Destination> destinations = <Destination>[
  Destination(Icons.people, Icons.people_outlined,  'User'),
  Destination(Icons.videogame_asset, Icons.videogame_asset_outlined, 'Game'),
  Destination(Icons.sticky_note_2, Icons.sticky_note_2_outlined, 'Note'),
  Destination(Icons.co_present, Icons.co_present_outlined, 'Class'),
  Destination(Icons.emoji_events,  Icons.emoji_events_outlined, 'Achievement',),
  Destination(Icons.auto_awesome, Icons.auto_awesome_outlined, 'AI chat'),
];
