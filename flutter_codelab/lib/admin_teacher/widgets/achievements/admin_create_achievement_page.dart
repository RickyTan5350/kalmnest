import 'dart:convert'; // Required for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'package:flutter_codelab/api/game_api.dart';
import 'package:flutter_codelab/models/level.dart';

void showCreateAchievementDialog({
  required BuildContext context,
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
  String? initialName,
  String? initialIcon,
  String? initialLevelId,
  String? initialLevelName,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AdminCreateAchievementDialog(
        showSnackBar: showSnackBar,
        initialName: initialName,
        initialIcon: initialIcon,
        initialLevelId: initialLevelId,
        initialLevelName: initialLevelName,
      );
    },
  );
}

class AdminCreateAchievementDialog extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  final String? initialName;
  final String? initialIcon;
  final String? initialLevelId;
  final String? initialLevelName;

  const AdminCreateAchievementDialog({
    super.key,
    required this.showSnackBar,
    this.initialName,
    this.initialIcon,
    this.initialLevelId,
    this.initialLevelName,
  });

  @override
  State<AdminCreateAchievementDialog> createState() =>
      _AdminCreateAchievementDialogState();
}

class _AdminCreateAchievementDialogState
    extends State<AdminCreateAchievementDialog> {
  final _formKey = GlobalKey<FormState>();
  final AchievementApi _achievementApi = AchievementApi();

  final TextEditingController _achievementNameController =
      TextEditingController();
  final TextEditingController _achievementDescriptionController =
      TextEditingController();
  final TextEditingController _achievementTitleController =
      TextEditingController();
  final TextEditingController _levelDisplayController = TextEditingController();

  List<AchievementData> _existingAchievements = [];

  // State variables for individual field errors
  String? _nameError;
  String? _titleError;

  String? _selectedIcon;
  String? _selectedLevel;

  bool _isLoading = false;

  final List<Map<String, dynamic>> iconOptions = achievementIconOptions;

  List<LevelModel> _levels = [];

  List<LevelModel> get _filteredLevels {
    if (_selectedIcon == null) return _levels;
    return _levels.where((l) {
      final type = l.levelTypeName?.toLowerCase() ?? '';
      final icon = _selectedIcon!.toLowerCase();
      // Heuristic: Check if the level type name allows the icon tag
      // e.g. "HTML Basics" contains "html"
      return type.contains(icon);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchExistingAchievements();
    _fetchLevels();

    if (widget.initialName != null) {
      _achievementNameController.text = widget.initialName!;
    }
    if (widget.initialIcon != null) {
      _selectedIcon = widget.initialIcon;
    }
    if (widget.initialLevelId != null) {
      _selectedLevel = widget.initialLevelId;
      if (widget.initialLevelName != null) {
        _levelDisplayController.text = widget.initialLevelName!;
      }
    }

    // Clear errors when the user starts typing
    _achievementNameController.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
    });
    _achievementTitleController.addListener(() {
      if (_titleError != null) setState(() => _titleError = null);
    });
  }

  Future<void> _fetchLevels() async {
    try {
      final levels = await GameAPI.fetchLevels();
      if (mounted) {
        setState(() {
          _levels = levels;
          // If we have an initial level ID but no name, try to find it in the fetched options
          if (_selectedLevel != null && _levelDisplayController.text.isEmpty) {
            final match = levels.firstWhere(
              (l) => l.levelId == _selectedLevel,
              orElse: () => LevelModel(levelId: '', levelName: ''),
            );
            if (match.levelId?.isNotEmpty ?? false) {
              _levelDisplayController.text = match.levelName ?? '';
            }
          }
        });
      }
    } catch (e) {
      print('Could not fetch levels: $e');
    }
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
    _levelDisplayController.dispose();
    super.dispose();
  }

  Future<void> _showLevelSelectionDialog() async {
    // 1. Get the list of options based on current icon filter
    final options = _filteredLevels;

    // 2. Show Dialog
    final LevelModel? result = await showDialog<LevelModel>(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredOptions = options.where((level) {
              final name = level.levelName?.toLowerCase() ?? '';
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Level'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // List
                    Flexible(
                      child: filteredOptions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No levels found.'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredOptions.length,
                              itemBuilder: (context, index) {
                                final level = filteredOptions[index];
                                return ListTile(
                                  title: Text(level.levelName ?? 'Unknown'),
                                  subtitle: Text(level.levelTypeName ?? ''),
                                  onTap: () {
                                    Navigator.pop(context, level);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    // 3. Handle Result
    if (result != null) {
      setState(() {
        _selectedLevel = result.levelId;
        _levelDisplayController.text = result.levelName ?? '';
      });
    }
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
      levelId: _selectedLevel, // This now holds the ID string from the dropdown
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
    const specificStudentMessage =
        'Access Denied: Only Admins or Teachers can create achievements.';

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
    else if (errorString.startsWith(
      'Exception: ${AchievementApi.validationErrorCode}:',
    )) {
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
        widget.showSnackBar(
          context,
          'Database Error: Duplicate entry.',
          Colors.red,
        );
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
                      final isDuplicate = _existingAchievements.any(
                        (item) =>
                            item.achievementName?.trim().toLowerCase() ==
                            value.trim().toLowerCase(),
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

                      final isDuplicate = _existingAchievements.any(
                        (item) =>
                            item.achievementTitle?.trim().toLowerCase() ==
                            value.trim().toLowerCase(),
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
                    onChanged: (newValue) {
                      setState(() {
                        _selectedIcon = newValue;
                        // Clear selected level on icon change to ensure consistency
                        _selectedLevel = null;
                        _levelDisplayController.clear();
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select an icon.' : null,
                  ),
                  const SizedBox(height: 16),

                  // Level Dropdown
                  // Level Selection (Searchable)
                  TextFormField(
                    controller: _levelDisplayController,
                    readOnly: true,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration:
                        _inputDecoration(
                          labelText: 'Associated Level',
                          hintText: 'Select a level',
                          icon: Icons.signal_cellular_alt,
                          colorScheme: colorScheme,
                        ).copyWith(
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    onTap: _showLevelSelectionDialog,
                    validator: (value) {
                      // Check if valid level is selected
                      if (_selectedIcon != null && _selectedLevel == null) {
                        // Only require level if an icon is selected?
                        // Or maybe level is optional. The original code had a "None" option.
                        // Let's assume it's optional but if they picked one it's fine.
                        // Use "None" button in dialog? Or just allow empty?
                        // Standard: if it's required. Let's make it optional as per original "None" option.
                        return null;
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
                        onPressed: () => Navigator.of(context).maybePop(),
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
      ),
      ),
    );
  }


  Future<bool> _onWillPop() async {
    final hasChanges =
        _achievementNameController.text.isNotEmpty ||
        _achievementTitleController.text.isNotEmpty ||
        _achievementDescriptionController.text.isNotEmpty ||
        _selectedIcon != null ||
        _selectedLevel != null;

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
