import 'package:flutter/material.dart';

class CreateAchievementPage extends StatefulWidget {
  const CreateAchievementPage({Key? key}) : super(key: key);

  @override
  State<CreateAchievementPage> createState() => _CreateAchievementPageState();
}

class _CreateAchievementPageState extends State<CreateAchievementPage> {
  final _formKey = GlobalKey<FormState>();
  final _achievementNameController = TextEditingController();
  final _achievementDescriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedLevel;
  AchievementType _achievementType = AchievementType.level;

  // Example data for dropdowns (replace with your actual data)
  final List<String> _categories = ['HTML', 'CSS', 'JS', 'PHP', 'Backend', 'Frontend'];
  final List<String> _levels = ['Level 1', 'Level 2', 'Level 3', 'Level 4', 'Level 5'];

  @override
  void dispose() {
    _achievementNameController.dispose();
    _achievementDescriptionController.dispose();
    super.dispose();
  }

  void _saveAchievement() {
    if (_formKey.currentState!.validate()) {
      final String name = _achievementNameController.text;
      final String description = _achievementDescriptionController.text;

      // TODO: Add your logic here to save the achievement
      // (e.g., send to API, save to database)

      print('Saving Achievement:');
      print('  Name: $name');
      print('  Description: $description');
      print('  Category: $_selectedCategory');
      print('  Level: $_selectedLevel');
      print('  Type: $_achievementType');

      // Go back to the previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Define consistent input decoration for the dark theme
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
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3), // Slightly visible fill
        filled: true,
      );
    }

    return Scaffold(
      appBar: AppBar(
        // The App Bar is behind the dialog-like card, so it doesn't need to be themed
        // as much as the content. You can make it transparent or match the main background.
        backgroundColor: Colors.transparent, // Or your main app background color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Assuming a light icon on dark background
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFF1F222A), // Matches your app's background
      body: Center(
        child: Card(
          // Styling for the floating card itself
          color: const Color(0xFF2E313D), // Darker shade for the card background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make column take minimum space
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Achievement',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface, // White/light color
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
                      icon: Icons.emoji_events, // Trophy icon
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an achievement name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0), // Align with input field
                    child: Text(
                      'Displaying Achievement Title',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Achievement Description
                  TextFormField(
                    controller: _achievementDescriptionController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Achievement Description',
                      hintText: 'description ~~~~~~',
                      icon: Icons.description, // Description icon
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: const Color(0xFF2E313D), // Dropdown background color
                    style: TextStyle(color: colorScheme.onSurface), // Text color for selected item
                    decoration: _inputDecoration(
                      labelText: 'Category',
                      icon: Icons.category,
                    ).copyWith(
                      // Override default border for dropdown to match
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
                    ),
                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Level Name Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedLevel,
                    dropdownColor: const Color(0xFF2E313D),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Level Name',
                      hintText: 'Placeholder Level 1',
                      icon: Icons.signal_cellular_alt, // Level icon
                    ).copyWith(
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
                    ),
                    items: _levels.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLevel = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a level';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Achievement Type (Radio Buttons)
                  Text(
                    'Achievement Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  
                  
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back without saving
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveAchievement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary, // Blue save button
                          foregroundColor: colorScheme.onPrimary, // White text on blue
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}

// Enum for Achievement Type
enum AchievementType { level, quiz }