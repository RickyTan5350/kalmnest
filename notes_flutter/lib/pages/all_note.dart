import 'package:flutter/material.dart';

class AllNotesPage extends StatelessWidget {
  const AllNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // This Padding adds space AROUND the card
      padding: const EdgeInsets.all(24.0),
      child: Card(
        // <--- New Card widget here
        elevation: 1, // Adjust elevation as needed
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior:
            Clip.antiAlias, // Ensures content respects rounded corners
        child: Padding(
          // This Padding adds space INSIDE the card for its content
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uploaded Notes',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      // Handle refresh
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Manage all educational materials',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 24),

              // 2. Search and Filter Row
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by title, topic, or file name...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        // Use your theme's color
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Filter Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filters'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      // Use your theme's color
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      // Handle filter tap
                    },
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // 3. Empty State Content
              // Use Expanded to push this to the center
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notes uploaded yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your first note to get started',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
