import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/constants/achievement_constants.dart';

import 'package:code_play/models/level.dart';
import 'package:code_play/api/game_api.dart';

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
  final TextEditingController _levelDisplayController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  AutovalidateMode _nameMode = AutovalidateMode.disabled;
  AutovalidateMode _titleMode = AutovalidateMode.disabled;
  AutovalidateMode _descMode = AutovalidateMode.disabled;

  // Validation State
  List<AchievementData> _existingAchievements = [];
  String? _nameError;
  String? _titleError;

  String? _selectedIcon;
  String? _selectedLevel;
  bool _isLoading = false;

  final List<Map<String, dynamic>> iconOptions = achievementIconOptions;
  List<LevelModel> _levels = [];

  // Undo/Redo State
  final List<_FormStateData> _undoStack = [];
  final List<_FormStateData> _redoStack = [];
  Timer? _debounceTimer;

  _FormStateData get _currentSnapshot => _FormStateData(
    name: _achievementNameController.text,
    title: _achievementTitleController.text,
    description: _achievementDescriptionController.text,
    icon: _selectedIcon,
    levelId: _selectedLevel,
    levelName: _levelDisplayController.text,
  );

  List<LevelModel> get _filteredLevels {
    if (_selectedIcon == null) return _levels;
    return _levels.where((l) {
      final type = l.levelTypeName?.toLowerCase() ?? '';
      final icon = _selectedIcon!.toLowerCase();
      // Heuristic: Check if the level type name allows the icon tag
      // e.g. "HTML Basics" contains "html"
      if (icon == 'javascript' && type.contains('js')) return true;
      return type.contains(icon);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // Focus Listeners for "Validate on Blur"
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        setState(() => _nameMode = AutovalidateMode.onUserInteraction);
      }
    });

    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) {
        setState(() => _titleMode = AutovalidateMode.onUserInteraction);
      }
    });

    _descFocus.addListener(() {
      if (!_descFocus.hasFocus) {
        setState(() => _descMode = AutovalidateMode.onUserInteraction);
      }
    });

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
    _selectedLevel = widget.achievement['associated_level']?.toString();

    // 2. Fetch Data
    _fetchExistingAchievements();
    _fetchLevels();

    // 3. Clear Server Errors on Typing
    _achievementNameController.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
    });
    _achievementTitleController.addListener(() {
      if (_titleError != null) setState(() => _titleError = null);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveSnapshot(force: true);
    });
  }

  void _saveSnapshot({bool force = false}) {
    if (force) {
      _debounceTimer?.cancel();
      _pushUndo();
      return;
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _pushUndo);
  }

  void _pushUndo() {
    if (!mounted) return;
    final current = _currentSnapshot;
    if (_undoStack.isNotEmpty && _undoStack.last == current) return;

    setState(() {
      _undoStack.add(current);
      _redoStack.clear();
      if (_undoStack.length > 50) _undoStack.removeAt(0);
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    final currentTip = _currentSnapshot;

    if (_undoStack.isNotEmpty && _undoStack.last == currentTip) {
      _undoStack.removeLast();
    }

    if (_undoStack.isEmpty) return;

    _redoStack.add(currentTip);

    final previous = _undoStack.last;
    _applySnapshot(previous);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final next = _redoStack.removeLast();
    _undoStack.add(next);
    _applySnapshot(next);
  }

  void _applySnapshot(_FormStateData data) {
    setState(() {
      if (_achievementNameController.text != data.name) {
        _achievementNameController.text = data.name;
      }
      if (_achievementTitleController.text != data.title) {
        _achievementTitleController.text = data.title;
      }
      if (_achievementDescriptionController.text != data.description) {
        _achievementDescriptionController.text = data.description;
      }
      _selectedIcon = data.icon;
      _selectedLevel = data.levelId;
      _levelDisplayController.text = data.levelName;
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

  Future<void> _showLevelSelectionDialog() async {
    final options = _filteredLevels;

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

    if (result != null) {
      setState(() {
        _selectedLevel = result.levelId;
        _levelDisplayController.text = result.levelName ?? '';
      });
      _saveSnapshot(force: true);
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
      print('Warning: Could not fetch list for uniqueness check: $e');
    }
  }

  @override
  void dispose() {
    _achievementNameController.dispose();
    _achievementTitleController.dispose();
    _achievementDescriptionController.dispose();
    _levelDisplayController.dispose();
    _nameFocus.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    String? errorText,
    required ColorScheme colorScheme,
    bool isRequired = false,
  }) {
    return InputDecoration(
      label: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: labelText),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
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
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          _undo();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () {
          _redo();
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
                  // autovalidateMode: AutovalidateMode.onUserInteraction, // Managed individually
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
                        focusNode: _nameFocus,
                        autovalidateMode: _nameMode,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          labelText: 'Achievement Name',
                          hintText: 'e.g., HTML Master',
                          icon: Icons.emoji_events,
                          colorScheme: colorScheme,
                          errorText: _nameError,
                          isRequired: true,
                        ),
                        onChanged: (value) => _saveSnapshot(),
                        validator: (value) {
                          if (_nameError != null) return _nameError;

                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an achievement name';
                          }

                          final isDuplicate = _existingAchievements.any((item) {
                            return item.achievementId != currentId &&
                                item.achievementName?.trim().toLowerCase() ==
                                    value.trim().toLowerCase();
                          });

                          if (isDuplicate)
                            return 'This Name is already in use.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _achievementTitleController,
                        focusNode: _titleFocus,
                        autovalidateMode: _titleMode,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          labelText: 'Achievement Title',
                          hintText: 'e.g., Certified Web Developer',
                          icon: Icons.title,
                          colorScheme: colorScheme,
                          errorText: _titleError,
                          isRequired: true,
                        ),
                        onChanged: (value) => _saveSnapshot(),
                        validator: (value) {
                          if (_titleError != null) return _titleError;

                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an achievement title';
                          }

                          final isDuplicate = _existingAchievements.any((item) {
                            return item.achievementId != currentId &&
                                item.achievementTitle?.trim().toLowerCase() ==
                                    value.trim().toLowerCase();
                          });

                          if (isDuplicate)
                            return 'This Title is already in use.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _achievementDescriptionController,
                        focusNode: _descFocus,
                        autovalidateMode: _descMode,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          labelText: 'Achievement Description',
                          hintText: 'Describe the achievement...',
                          icon: Icons.description,
                          colorScheme: colorScheme,
                          isRequired: true,
                        ),
                        maxLines: 3,
                        onChanged: (value) => _saveSnapshot(),
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
                          isRequired: true,
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
                            // When icon changes, maybe reset level if it conflicts?
                            // For edit, let's keep it simple or follow create logic:
                            _selectedLevel = null;
                            _levelDisplayController.clear();
                            _saveSnapshot(force: true);
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select an icon.' : null,
                      ),
                      const SizedBox(height: 16),

                      // Level Dropdown (Searchable)
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
                        onTap: () => _showLevelSelectionDialog(),
                        validator: (value) {
                          if (_selectedIcon != null && _selectedLevel == null) {
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
        _selectedLevel != widget.achievement['associated_level']?.toString();

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

class _FormStateData {
  final String name;
  final String title;
  final String description;
  final String? icon;
  final String? levelId;
  final String levelName;

  _FormStateData({
    required this.name,
    required this.title,
    required this.description,
    this.icon,
    this.levelId,
    required this.levelName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FormStateData &&
        other.name == name &&
        other.title == title &&
        other.description == description &&
        other.icon == icon &&
        other.levelId == levelId &&
        other.levelName == levelName;
  }

  @override
  int get hashCode =>
      Object.hash(name, title, description, icon, levelId, levelName);
}
