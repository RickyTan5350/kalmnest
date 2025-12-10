import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';

Future<void> showEditAchievementDialog({
  required BuildContext context,
  required Map<String, dynamic> achievement, // Data to pre-fill
  required void Function(BuildContext context, String message, Color color) showSnackBar,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return EditAchievementDialog(
        achievement: achievement,
        showSnackBar: showSnackBar,
      );
    },
  );
}

class EditAchievementDialog extends StatefulWidget {
  final Map<String, dynamic> achievement;
  final void Function(BuildContext context, String message, Color color) showSnackBar;

  const EditAchievementDialog({
    super.key,
    required this.achievement,
    required this.showSnackBar,
  });

  @override
  State<EditAchievementDialog> createState() => _EditAchievementDialogState();
}

class _EditAchievementDialogState extends State<EditAchievementDialog> {
  final _formKey = GlobalKey<FormState>();
  final AchievementApi _achievementApi = AchievementApi();

  late TextEditingController _achievementNameController;
  late TextEditingController _achievementTitleController;
  late TextEditingController _achievementDescriptionController;

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
  void initState() {
    super.initState();
    // --- PRE-LOAD DATA ---
    // We map the keys passed from the detail page to the controllers
    _achievementNameController = TextEditingController(text: widget.achievement['achievement_name']);
    _achievementTitleController = TextEditingController(text: widget.achievement['title']);
    _achievementDescriptionController = TextEditingController(text: widget.achievement['description']);

    // Pre-select dropdowns (ensure value exists in options to avoid crash)
    _selectedIcon = widget.achievement['icon'];
    _selectedLevel = widget.achievement['associated_level'];

    // Safety check: if the loaded level isn't in our list, default to empty/null
    if (!_levels.contains(_selectedLevel)) {
      _selectedLevel = null;
    }
  }

  @override
  void dispose() {
    _achievementNameController.dispose();
    _achievementTitleController.dispose();
    _achievementDescriptionController.dispose();
    super.dispose();
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
      fillColor: colorScheme.surfaceContainer,
      filled: true,
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Construct the data object for the API
    // We use the ID passed in the map to know which one to update
    String id = widget.achievement['achievement_id'].toString();

    final updatedData = AchievementData(
      achievementId: id,
      achievementName: _achievementNameController.text,
      achievementTitle: _achievementTitleController.text,
      achievementDescription: _achievementDescriptionController.text,
      level: _selectedLevel,
      icon: _selectedIcon,
    );

    try {
      // Assuming your API has an update method.
      // If not, you might need to implement: await _achievementApi.updateAchievement(id, updatedData);
      // For now, I will use the pattern from your create page but targeting an update.
      await _achievementApi.updateAchievement(id, updatedData);

      if (mounted) {
        widget.showSnackBar(context, 'Changes saved successfully!', Colors.green);
        Navigator.of(context).pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        widget.showSnackBar(context, 'Error updating: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
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
                  'Edit Achievement',
                  style: textTheme.titleLarge?.copyWith(
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
                    icon: Icons.emoji_events,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _achievementTitleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Title',
                    icon: Icons.title,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _achievementDescriptionController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Description',
                    icon: Icons.description,
                    colorScheme: colorScheme,
                  ),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),

                // Category Icon Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedIcon,
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Icon',
                    icon: Icons.photo_library,
                    colorScheme: colorScheme,
                  ),
                  items: iconOptions.map((option) {
                    return DropdownMenuItem<String>(
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
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedIcon = val),
                  validator: (val) => val == null ? 'Please select an icon' : null,
                ),
                const SizedBox(height: 16),

                // Level Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Level',
                    icon: Icons.signal_cellular_alt,
                    colorScheme: colorScheme,
                  ),
                  items: _levels.map((val) {
                    return DropdownMenuItem(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedLevel = val),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
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
                          : const Text('Save Changes'),
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