import 'dart:convert'; // Required for jsonDecode
import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/constants/achievement_constants.dart';
import 'package:code_play/api/game_api.dart';
import 'package:code_play/models/level.dart';

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

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  AutovalidateMode _nameMode = AutovalidateMode.disabled;
  AutovalidateMode _titleMode = AutovalidateMode.disabled;
  AutovalidateMode _descMode = AutovalidateMode.disabled;

  List<AchievementData> _existingAchievements = [];

  // State variables for individual field errors
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
    _fetchExistingAchievements();
    _fetchLevels();

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

    // Clear errors and check for JSON paste when the user starts typing name
    _achievementNameController.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
      _checkForJsonPaste();
    });

    _achievementTitleController.addListener(() {
      if (_titleError != null) setState(() => _titleError = null);
    });

    // Initial snapshot
    // Using simple Future to allow fields to populate first if any sync logic runs
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
    // Don't push if same as top of stack
    if (_undoStack.isNotEmpty && _undoStack.last == current) return;

    setState(() {
      _undoStack.add(current);
      _redoStack.clear();
      if (_undoStack.length > 50) _undoStack.removeAt(0);
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    // Save current "tip" state to redo stack before going back
    final currentTip = _currentSnapshot;

    // Logic:
    // If currentTip is different from the top of undoStack, we might want to preserve it in Redo.
    // If currentTip equals the top of undoStack (which happens if we just saved), we need to go to the ONE BEFORE.

    // If current state matches the last undo state, it means we are "synced" with history.
    // So to undo, we pop the last one (current state) and go to the one before that.
    if (_undoStack.isNotEmpty && _undoStack.last == currentTip) {
      _undoStack.removeLast();
    }

    if (_undoStack.isEmpty) {
      // We popped the only state, so we are at "start".
      // But wait, if we popped it, where did we go?
      // Let's refine:
      // Undo Stack represents: [State 0, State 1, State 2]
      // Current: State 2.
      // User presses Undo.
      // We want Current to become State 1.
      // Redo should get State 2.
      // So:
      // 1. Redo.add(State 2)
      // 2. Undo.pop() -> Removes State 2.
      // 3. Current = Undo.last (State 1).
    }

    // Correct Implementation for "Browser-like" undo:
    // We treat the "Current UI" as something that sits on top of the undo stack IF it has changed.
    // If we just pushed a snapshot, Current UI == UndoStack.last.
    // So to undo, we must go to UndoStack[last - 1].

    if (_undoStack.isEmpty) return;

    // 1. Save current state to redo
    _redoStack.add(currentTip);

    // 2. Remove the "current" state from undo stack (since we are leaving it)
    // BUT only if the current state IS recorded in undo stack.
    if (_undoStack.last == currentTip) {
      _undoStack.removeLast();
    }

    if (_undoStack.isEmpty) {
      // We ran out of history.
      // This implies we are at the initial state.
      // Revert the pop if needed or handle graceful empty.
      // If we popped everything, we can't apply anything.
      // But we should have at least the initial state...
      // Unless we want to clear fields? No, just stop.
      return;
    }

    // 3. Now the top of undo stack is the previous state.
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
        // Keep cursor at end if possible, or preserve selection?
        // For simplicity, just set text. selection might jump.
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
    _nameFocus.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _debounceTimer?.cancel();
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
      _saveSnapshot(force: true);
    }
  }

  void _checkForJsonPaste() {
    if (!kDebugMode) return;
    final text = _achievementNameController.text.trim();
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final Map<String, dynamic> json = jsonDecode(text);
        _populateFormFromJson(json);
      } catch (e) {
        // Not valid JSON, ignore
      }
    }
  }

  void _populateFormFromJson(Map<String, dynamic> json) {
    String? getValue(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) {
          return json[key]?.toString();
        }
      }
      return null;
    }

    final name = getValue(['achievementName', 'name']);
    final title = getValue(['achievementTitle', 'title']);
    final description = getValue([
      'achievementDescription',
      'description',
      'desc',
    ]);

    setState(() {
      if (name != null) _achievementNameController.text = name;
      if (title != null) _achievementTitleController.text = title;
      if (description != null) {
        _achievementDescriptionController.text = description;
      }
      _saveSnapshot(force: true);
    });

    if (mounted) {
      widget.showSnackBar(context, 'Form autofilled from JSON', Colors.blue);
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
    bool isRequired = false,
  }) {
    return InputDecoration(
      label: isRequired
          ? Text.rich(
              TextSpan(
                text: labelText,
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
            )
          : Text(labelText),
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
        // Also support Cmd+Z for Mac users if needed, though specific instruction asked for ctrl z.
        // Flutter abstracts this usually but Explicit bindings are good.
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
                        'New Achievement',
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
                        // Note: capturing text changes via onChanged to snapshot state
                        onChanged: (value) => _saveSnapshot(),
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

                          final isDuplicate = _existingAchievements.any(
                            (item) =>
                                item.achievementTitle?.trim().toLowerCase() ==
                                value.trim().toLowerCase(),
                          );

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
                            _selectedLevel = null;
                            _levelDisplayController.clear();
                            _saveSnapshot(force: true);
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
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
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
