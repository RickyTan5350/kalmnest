import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/constants/achievement_constants.dart';

Future<void> showEditAchievementDialog({
  required BuildContext context,
  required Map<String, dynamic> achievement, // Data to pre-fill
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
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
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;

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

  // Validation State
  List<AchievementData> _existingAchievements = [];
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
    // 1. Pre-load Data
    _achievementNameController = TextEditingController(
      text: widget.achievement['achievement_name'],
    );
    _achievementTitleController = TextEditingController(
      text: widget.achievement['title'],
    );
    _achievementDescriptionController = TextEditingController(
      text: widget.achievement['description'],
    );

    _selectedIcon = widget.achievement['icon'];
    _selectedLevel = widget.achievement['associated_level'];

    if (!_levels.contains(_selectedLevel)) {
      _selectedLevel = null;
    }

    // 2. Fetch Existing Data for Uniqueness Check
    _fetchExistingAchievements();

    // 3. Clear Server Errors on Typing
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
      print('Warning: Could not fetch list for uniqueness check: $e');
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
    String? errorText, // Added errorText support
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText, // Display server error
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
        // Red border on error
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
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
    // 1. Reset Server Errors
    setState(() {
      _nameError = null;
      _titleError = null;
    });

    // 2. Client-Side Validation
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String id = widget.achievement['achievement_id'].toString();

    final updatedData = AchievementData(
      achievementId: id,
      achievementName: _achievementNameController.text,
      achievementTitle: _achievementTitleController.text,
      achievementDescription: _achievementDescriptionController.text,
      levelId: _selectedLevel,
      icon: _selectedIcon,
    );

    try {
      await _achievementApi.updateAchievement(id, updatedData);

      if (mounted) {
        widget.showSnackBar(
          context,
          'Changes saved successfully!',
          Colors.green,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _handleSubmissionError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSubmissionError(Object e) {
    String errorString = e.toString();
    const specificStudentMessage =
        'Access Denied: Only Admins or Teachers can create achievements.';

    // --- CASE 1: Authorization ---
    if (errorString.contains(specificStudentMessage)) {
      widget.showSnackBar(
        context,
        specificStudentMessage,
        Theme.of(context).colorScheme.error,
      );
    }
    // --- CASE 2: Validation Error (422 JSON) ---
    else if (errorString.startsWith(
      'Exception: ${AchievementApi.validationErrorCode}:',
    )) {
      final jsonPart = errorString.substring(
        'Exception: ${AchievementApi.validationErrorCode}:'.length,
      );

      try {
        final Map<String, dynamic> errors = jsonDecode(jsonPart);
        setState(() {
          if (errors.containsKey('achievement_name')) {
            _nameError = (errors['achievement_name'] as List).first.toString();
          }
          if (errors.containsKey('title')) {
            _titleError = (errors['title'] as List).first.toString();
          }
          // Catch-all for other naming conventions
          if (errors.containsKey('name')) {
            _nameError = (errors['name'] as List).first.toString();
          }
        });
        _formKey.currentState!.validate(); // Refresh UI
      } catch (parseError) {
        widget.showSnackBar(context, 'Validation Error: $jsonPart', Colors.red);
      }
    }
    // --- CASE 3: Database Integrity (500) ---
    else if (errorString.contains('Integrity constraint violation') ||
        errorString.contains('Duplicate entry')) {
      setState(() {
        if (errorString.contains('achievements_achievement_name_unique')) {
          _nameError = 'This internal name is already in use.';
        }
        if (errorString.contains('title_unique')) {
          _titleError = 'This title is already in use.';
        }
      });

      _formKey.currentState!.validate(); // Refresh UI

      if (_nameError == null && _titleError == null) {
        widget.showSnackBar(
          context,
          'Database Error: Duplicate entry.',
          Colors.red,
        );
      }
    }
    // --- CASE 4: Generic ---
    else {
      widget.showSnackBar(context, 'Error updating: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final String currentId = widget.achievement['achievement_id'].toString();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        child: WillPopScope(
          onWillPop: _onWillPop,
          child: AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                          errorText: _nameError, // Server error
                        ),
                        validator: (value) {
                          if (_nameError != null) {
                            return _nameError; // Server error priority
                          }

                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }

                          // Client-Side Uniqueness (Excluding current item)
                          final isDuplicate = _existingAchievements.any((item) {
                            return item.achievementId != currentId &&
                                item.achievementName?.trim().toLowerCase() ==
                                    value.trim().toLowerCase();
                          });

                          if (isDuplicate) return 'Name already in use.';
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
                          icon: Icons.title,
                          colorScheme: colorScheme,
                          errorText: _titleError, // Server error
                        ),
                        validator: (value) {
                          if (_titleError != null) return _titleError;

                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }

                          // Client-Side Uniqueness (Excluding current item)
                          final isDuplicate = _existingAchievements.any((item) {
                            return item.achievementId != currentId &&
                                item.achievementTitle?.trim().toLowerCase() ==
                                    value.trim().toLowerCase();
                          });

                          if (isDuplicate) return 'Title already in use.';
                          return null;
                        },
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
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a description'
                            : null,
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
                        validator: (val) =>
                            val == null ? 'Please select an icon' : null,
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
                        onChanged: (val) =>
                            setState(() => _selectedLevel = val),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).maybePop(false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
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
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final hasChanges =
        _achievementNameController.text !=
            widget.achievement['achievement_name'] ||
        _achievementTitleController.text != widget.achievement['title'] ||
        _achievementDescriptionController.text !=
            widget.achievement['description'] ||
        _selectedIcon != widget.achievement['icon'] ||
        _selectedLevel != widget.achievement['associated_level'];

    if (!hasChanges) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }
}

