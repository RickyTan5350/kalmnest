import 'package:flutter/material.dart';

void showCreateAchievementDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final _achievementNameController = TextEditingController();
  final _achievementDescriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedLevel;

  final List<String> _categories = [
    'HTML', 'CSS', 'JS', 'PHP', 'Backend', 'Frontend'
  ];
  final List<String> _levels = [
    'Level 1', 'Level 2', 'Level 3', 'Level 4', 'Level 5'
  ];

  final colorScheme = Theme.of(context).colorScheme;

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      filled: true,
    );
  }

  void _saveAchievement() {
    if (_formKey.currentState!.validate()) {
      final String name = _achievementNameController.text;
      final String description = _achievementDescriptionController.text;

      print('Saving Achievement:');
      print('  Name: $name');
      print('  Description: $description');
      print('  Category: $_selectedCategory');
      print('  Level: $_selectedLevel');

      Navigator.of(context).pop(); // Close dialog
    }
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF2E313D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Achievement',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Achievement Name
                TextFormField(
                  controller: _achievementNameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Name',
                    hintText: 'name placeholder',
                    icon: Icons.emoji_events,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an achievement name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _achievementDescriptionController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Description',
                    hintText: 'description ~~~~~~',
                    icon: Icons.description,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF2E313D),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Category',
                    icon: Icons.category,
                  ),
                  items: _categories
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) => _selectedCategory = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Level Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  dropdownColor: const Color(0xFF2E313D),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Level Name',
                    icon: Icons.signal_cellular_alt,
                  ),
                  items: _levels
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) => _selectedLevel = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a level';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveAchievement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
