import 'dart:convert'; // Required for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';

void showCreateAchievementDialog({
  required BuildContext context,
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

  List<AchievementData> _existingAchievements = [];

  // State variables for individual field errors
  String? _nameError;
  String? _titleError;

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
    _fetchExistingAchievements();

    // Clear errors when the user starts typing
    _achievementNameController.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
    });
    _achievementTitleController.addListener(() {
      if (_titleError != null) setState(() => _titleError = null);
    });
  }

  Future<void> _fetchExistingAchievements() async {
    try {
      final list = await _achievementApi.fetchBriefAchievements();
      if (mounted) {
        setState(() {
          _existingAchievements = list;
        });
      }
    } catch (e) {
      print('Could not fetch existing achievements: $e');
    }
  }

  @override
  void dispose() {
    _achievementNameController.dispose();
    _achievementDescriptionController.dispose();
    _achievementTitleController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // 1. Reset Errors
    setState(() {
      _nameError = null;
      _titleError = null;
    });

    // 2. Client-Side Validation (checks for empty fields)
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
        widget.showSnackBar(
          context,
          'Achievement successfully created!',
          Colors.green,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _handleSubmissionError(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSubmissionError(Object e) {
    String errorString = e.toString();
    const specificStudentMessage = 'Access Denied: Only Admins or Teachers can create achievements.';

    // --- CASE 1: Authorization Error ---
    if (errorString.contains(specificStudentMessage)) {
      widget.showSnackBar(
        context,
        specificStudentMessage,
        Theme.of(context).colorScheme.error,
      );
    }
    // --- CASE 2: Validation Error (422) ---
    // The API now returns a JSON string after the error code
    else if (errorString.startsWith('Exception: ${AchievementApi.validationErrorCode}:')) {
      final jsonPart = errorString.substring(
        'Exception: ${AchievementApi.validationErrorCode}:'.length,
      );

      try {
        // Decode the JSON error map: { "achievement_name": ["Taken"], "title": ["Taken"] }
        final Map<String, dynamic> errors = jsonDecode(jsonPart);

        setState(() {
          if (errors.containsKey('achievement_name')) {
            _nameError = (errors['achievement_name'] as List).first.toString();
          }
          if (errors.containsKey('title')) {
            _titleError = (errors['title'] as List).first.toString();
          }
          // Check for other keys if your backend uses them (e.g. 'name')
          if (errors.containsKey('name')) {
            _nameError = (errors['name'] as List).first.toString();
          }
        });

        // Trigger the form to redraw with the new error text
        _formKey.currentState!.validate();

      } catch (parseError) {
        // Fallback if parsing fails
        widget.showSnackBar(context, 'Validation Error: $jsonPart', Colors.red);
      }
    }
    // --- CASE 3: Database Integrity Error (500) ---
    // Matches "Duplicate entry ... for key 'achievements_achievement_name_unique'"
    else if (errorString.contains('Integrity constraint violation') ||
        errorString.contains('Duplicate entry')) {

      setState(() {
        if (errorString.contains('achievements_achievement_name_unique')) {
          _nameError = 'This internal name is already in use.';
        }
        if (errorString.contains('achievements_title_unique')) {
          _titleError = 'This title is already in use.';
        }
      });

      _formKey.currentState!.validate();

      if (_nameError == null && _titleError == null) {
        widget.showSnackBar(context, 'Database Error: Duplicate entry.', Colors.red);
      }
    }
    // --- CASE 4: General Error ---
    else {
      widget.showSnackBar(
        context,
        'An error occurred. ${errorString.replaceAll('Exception: ', '')}',
        Colors.red,
      );
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    String? errorText,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText, // Displays server error here
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      fillColor: colorScheme.surfaceContainer,
      filled: true,
    );
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Achievement',
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
                    hintText: 'e.g., HTML Master',
                    icon: Icons.emoji_events,
                    colorScheme: colorScheme,
                    errorText: _nameError,
                  ),
                  validator: (value) {
                    if (_nameError != null) return _nameError;

                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an achievement name';
                    }

                    // Client-side fallback (works if data is available)
                    final isDuplicate = _existingAchievements.any((item) =>
                    item.achievementName?.trim().toLowerCase() ==
                        value.trim().toLowerCase()
                    );

                    if (isDuplicate) return 'This Name is already in use.';

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
                    errorText: _titleError,
                  ),
                  validator: (value) {
                    if (_titleError != null) return _titleError;

                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an achievement title';
                    }

                    final isDuplicate = _existingAchievements.any((item) =>
                    item.achievementTitle?.trim().toLowerCase() ==
                        value.trim().toLowerCase()
                    );

                    if (isDuplicate) return 'This Title is already in use.';

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

                // Icon Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedIcon,
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Achievement Icon',
                    icon: Icons.photo_library,
                    colorScheme: colorScheme,
                  ),
                  items: iconOptions.map((option) => DropdownMenuItem<String>(
                    value: option['value'] as String,
                    child: Row(
                      children: [
                        Icon(option['icon'] as IconData, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Text(option['display'] as String),
                      ],
                    ),
                  )).toList(),
                  onChanged: (newValue) => setState(() => _selectedIcon = newValue),
                  validator: (value) => value == null ? 'Please select an icon.' : null,
                ),
                const SizedBox(height: 16),

                // Level Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Level Name',
                    icon: Icons.signal_cellular_alt,
                    colorScheme: colorScheme,
                  ),
                  items: _levels.map((value) =>
                      DropdownMenuItem(value: value, child: Text(value))
                  ).toList(),
                  onChanged: (value) => setState(() => _selectedLevel = value),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
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