import 'package:flutter/material.dart';

class Destination {
  const Destination(this.icon, this.label);
  final IconData icon;
  final String label;
}

const List<Destination> destinations = <Destination>[
  Destination(Icons.people, 'User'),
  Destination(Icons.videogame_asset, 'Game'),
  Destination(Icons.menu_book, 'Note'),
  Destination(Icons.co_present, 'Class'),
  Destination(Icons.emoji_events, 'Achievement'),
  Destination(Icons.auto_awesome, 'AI chat'),
];