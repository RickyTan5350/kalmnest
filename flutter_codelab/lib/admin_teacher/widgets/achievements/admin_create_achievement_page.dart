import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';

void showCreateAchievementDialog({
  required BuildContext context,
  // Pass the SnackBar helper from the main page to ensure it works with the Scaffold
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AdminCreateAchievementDialog(showSnackBar: showSnackBar);
    },
  );
}

class AdminCreateAchievementDialog extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;

  const AdminCreateAchievementDialog({super.key, required this.showSnackBar});

  @override
  State<AdminCreateAchievementDialog> createState() =>
      _AdminCreateAchievementDialogState();
}

class _AdminCreateAchievementDialogState extends State<AdminCreateAchievementDialog> {
  final _formKey = GlobalKey<FormState>();
  final AchievementApi _achievementApi = AchievementApi();

  final TextEditingController _achievementNameController =
  TextEditingController();
  final TextEditingController _achievementDescriptionController =
  TextEditingController();
  final TextEditingController _achievementTitleController =
  TextEditingController();

  String? _selectedIcon;
  String? _selectedLevel;

  bool _isLoading = false;

  final List<Map<String, dynamic>> iconOptions = achievementIconOptions;

  final List<String> _levels = [
    '',
    'Level 1',
    'Level 2',
    'Level 3',
    'Level 4',
    'Level 5',
  ];

  @override
  void dispose() {
    _achievementNameController.dispose();
    _achievementDescriptionController.dispose();
    _achievementTitleController.dispose();

    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final data = AchievementData(
      achievementName: _achievementNameController.text,
      achievementTitle: _achievementTitleController.text,
      achievementDescription: _achievementDescriptionController.text,
      level: _selectedLevel,
      icon: _selectedIcon,
    );

    try {
      await _achievementApi.createAchievement(data);

      if (mounted) {
        // Use the passed-in showSnackBar helper
        widget.showSnackBar(
          context,
          'Achievement successfully created!',
          Colors.green,
        );
        // Pop the dialog (using the dialog's context)
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorString = e.toString();

        // --- START FIX: Check for Authorization Failure ---
        const specificStudentMessage = 'Access Denied: Only Admins or Teachers can create achievements.';

        // 1. Authorization Failure (Student role)
        if (errorString.contains(specificStudentMessage)) {
          widget.showSnackBar(
            context,
            specificStudentMessage,
            Theme.of(context).colorScheme.error, // Use the theme's error color
          );
        }
        // 2. Validation Failure (422)
        else if (errorString.startsWith(
          'Exception: ${AchievementApi.validationErrorCode}:',
        )) {
          // Extract and format the validation message
          final message = errorString.substring(
            'Exception: ${AchievementApi.validationErrorCode}:'.length,
          ).trim();

          widget.showSnackBar(
            context,
            'Validation Error:\n$message',
            Colors.red,
          );
        }
        // 3. General/Server Failure (e.g., 401, 500, Network error)
        else {
          // General Network/Server Error
          widget.showSnackBar(
            context,
            'An error occurred. ${errorString.replaceAll('Exception: ', '')}',
            Colors.red,
          );
        }
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    required ColorScheme colorScheme,
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
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
      fillColor: colorScheme.surfaceContainer, // Use a semantic color
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface, // Use surface color for the dialog background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24.0),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Achievement',
                  style: textTheme.titleLarge?.copyWith( // Use theme's text styles
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                // Achievement Name
                TextFormField(
                  controller: _achievementNameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Name',
                    hintText: 'e.g., HTML Master',
                    icon: Icons.emoji_events,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an achievement name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _achievementTitleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Title',
                    hintText: 'e.g., Certified Web Developer',
                    icon: Icons.title,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an achievement title';
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
                    hintText: 'Describe the achievement...',
                    icon: Icons.description,
                    colorScheme: colorScheme,
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
                  initialValue: _selectedIcon,
                  dropdownColor: colorScheme.surfaceContainer, // Use a semantic background color
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Icon',
                    icon: Icons.photo_library,
                    colorScheme: colorScheme,
                  ),
                  items: iconOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                      value: option['value'] as String,
                      child: Row(
                        children: [
                          Icon(
                            option['icon'] as IconData,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Text(option['display'] as String),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedIcon = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an icon.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Level Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  dropdownColor: colorScheme.surfaceContainer, // Use a semantic background color
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Level Name',
                    icon: Icons.signal_cellular_alt,
                    colorScheme: colorScheme,
                  ),
                  items: _levels
                      .map(
                        (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedLevel = value;
                  }),
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
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
