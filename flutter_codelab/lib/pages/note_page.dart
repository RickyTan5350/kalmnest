// lib/pages/achievement_page.dart

import 'package:flutter/material.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final List<String> _topics = ['HTML', 'CSS', 'JS', 'PHP'];
  String _selectedTopic = 'CSS'; // Default selected topic

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0), // Outer padding around the card
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Inner padding inside the card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  "Notes",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                ),

                const SizedBox(height: 16),

                // Search Bar (moved above chips)
                SizedBox(
                  width: 300,
                  child: SearchBar(
                    
                    hintText: "Select a topic",
                    trailing: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Chips
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: _topics.map((topic) {
                    final bool isSelected = _selectedTopic == topic;
                    return FilterChip(
                      label:
                          Text(topic, style: TextStyle(color: colors.onSurface)),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) _selectedTopic = topic;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                
                const Expanded(
                  child: Center(
                    child: Text('Uploaded Notes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}