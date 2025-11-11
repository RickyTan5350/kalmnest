import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';

void showCreateAchievementDialog({
  required BuildContext context,
  // Pass the SnackBar helper from the main page to ensure it works with the Scaffold
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return CreateAchievementDialog(showSnackBar: showSnackBar);
    },
  );
}

class CreateAchievementDialog extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;

  const CreateAchievementDialog({super.key, required this.showSnackBar});

  @override
  State<CreateAchievementDialog> createState() => _CreateAchievementDialogState();
}

class _CreateAchievementDialogState extends State<CreateAchievementDialog>{
    final _formKey = GlobalKey<FormState>();
  final AchievementApi _achievementApi = AchievementApi();

  final TextEditingController _achievementNameController =
      TextEditingController();
  final TextEditingController _achievementDescriptionController =
      TextEditingController();
  final TextEditingController _achievementTitleController =
      TextEditingController();
 

  String? _selectedCategory;
  String? _selectedLevel;

  bool _isLoading = false;

  final List<String> _categories = [
    'HTML',
    'CSS',
    'JS',
    'PHP',
    'Backend',
    'Frontend',
  ];
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

    setState(() { _isLoading = true; });

    final data = AchievementData(
      achievementName: _achievementNameController.text,
      achievementTitle: _achievementDescriptionController.text,
      achievementDescription: _achievementTitleController.text,
      level: _selectedLevel,
    );

    try{
      await _achievementApi.createAchievement(data);

      if(mounted){
        // Use the passed-in showSnackBar helper
        widget.showSnackBar(context, 'Achievement successfully created!', Colors.green);
        // Pop the dialog (using the dialog's context)
        Navigator.of(context).pop();
      }
    } catch(e) {
      if(mounted){
        if (e.toString().startsWith('Exception: ${AchievementApi.validationErrorCode}:')) {
          final message = e.toString().substring('Exception: ${AchievementApi.validationErrorCode}:'.length);
          widget.showSnackBar(context, 'Validation Error:\n$message', Colors.red);
        } else {
          widget.showSnackBar(context, 'An unknown error occurred.', Colors.red);
        }
      }
    } finally{
      if (mounted) {
        setState(() { _isLoading = false; });
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
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context){
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: const Color(0xFF2E313D),
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
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an achievement name';
                    }
                    return null;
                  },
                ),

                // Title
                TextFormField(
                  controller: _achievementTitleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Title',
                    hintText: 'name placeholder',
                    icon: Icons.emoji_events,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return ' achievement title';
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
                  initialValue: _selectedCategory,
                  dropdownColor: const Color(0xFF2E313D),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Category',
                    icon: Icons.category,
                    colorScheme: colorScheme,
                  ),
                  items: _categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
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
                  initialValue: _selectedLevel,
                  dropdownColor: const Color(0xFF2E313D),
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
                  onChanged: (value) => _selectedLevel = value,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please select a level';
                  //   }
                  //   return null;
                  // },
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
                      onPressed: _submitForm,
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
                      child: const Text('Save'),
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