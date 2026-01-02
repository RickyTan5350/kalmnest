//lib/widgets/create_class_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/constants/class_constants.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_theme_extensions.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_validators.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedTeacher;
  String? _selectedFocus;
  List<String?> _selectedStudents = [null];

  // Data from backend
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  bool _loadingTeachers = true;
  bool _loadingStudents = true;

  // Real-time validation state
  String? _classNameValidationError;
  bool _isCheckingClassName = false;
  Timer? _classNameDebounceTimer;

  // Get available students for a specific dropdown (excludes already selected students)
  List<Map<String, dynamic>> _getAvailableStudents(int currentIndex) {
    final selectedIds = _selectedStudents
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    // Remove the current selection from the set (so it can be shown in current dropdown)
    if (_selectedStudents[currentIndex] != null) {
      selectedIds.remove(_selectedStudents[currentIndex]);
    }

    return _students.where((student) {
      final studentId = student['user_id'] as String?;
      return studentId != null && !selectedIds.contains(studentId);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
    _fetchStudents();
  }

  Future<void> _fetchTeachers() async {
    if (!mounted) return;
    setState(() => _loadingTeachers = true);
    try {
      print('Fetching teachers...');
      final teachers = await ClassApi.fetchTeachers();
      print('Received ${teachers.length} teachers');
      if (mounted) {
        setState(() {
          _teachers = teachers;
          _loadingTeachers = false;
        });
        print('Teachers state updated: ${_teachers.length}');
      }
    } catch (e, stackTrace) {
      print('Error fetching teachers: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _teachers = [];
          _loadingTeachers = false;
        });
      }
    }
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() => _loadingStudents = true);
    try {
      print('Fetching students...');
      final students = await ClassApi.fetchStudents();
      print('Received ${students.length} students');
      if (mounted) {
        setState(() {
          _students = students;
          _loadingStudents = false;
        });
        print('Students state updated: ${_students.length}');
      }
    } catch (e, stackTrace) {
      print('Error fetching students: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _students = [];
          _loadingStudents = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _descriptionController.dispose();
    _classNameDebounceTimer?.cancel();
    super.dispose();
  }

  /// Check if class name exists (with debounce)
  Future<void> _checkClassNameExists(String className) async {
    // Cancel previous timer
    _classNameDebounceTimer?.cancel();

    // Clear error if input is too short
    if (className.trim().length < 3) {
      setState(() {
        _classNameValidationError = null;
        _isCheckingClassName = false;
      });
      return;
    }

    setState(() {
      _isCheckingClassName = true;
      _classNameValidationError = null;
    });

    // Debounce: wait 500ms before checking
    _classNameDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      final exists = await ClassApi.checkClassNameExists(className.trim());

      if (!mounted) return;

      setState(() {
        _isCheckingClassName = false;
        if (exists) {
          _classNameValidationError =
              'The classname is already exist. Please choose a different name.';
        } else {
          _classNameValidationError = null;
        }
      });

      // Trigger form validation to update error display
      _formKey.currentState?.validate();
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _classNameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedTeacher = null;
      _selectedFocus = null;
      _selectedStudents = [null];
    });
  }

  void _createClass() async {
    final l10n = AppLocalizations.of(context)!;

    // Validate all fields before submission
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Show error message if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors before submitting'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Additional validation using ClassValidators
    final studentIds = _selectedStudents.whereType<String>().toList();
    final validationErrors = ClassValidators.validateClassForm(
      className: _classNameController.text.trim(),
      description: _descriptionController.text.trim(),
      teacherId: _selectedTeacher,
      focus: _selectedFocus,
      studentIds: studentIds.isEmpty ? null : studentIds,
      l10n: l10n,
    );

    if (!ClassValidators.isFormValid(validationErrors)) {
      // Find first error and show it
      final firstError = validationErrors.values.firstWhere(
        (error) => error != null,
        orElse: () => null,
      );
      if (firstError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(firstError!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    String? adminId; // optional; backend will use current admin
    String? teacherId = _selectedTeacher;
    String description = _descriptionController.text.trim();
    String className = _classNameController.text.trim();

    final result = await ClassApi.createClass(
      className: className,
      teacherId: teacherId,
      description: description,
      adminId: adminId,
      focus: _selectedFocus,
      studentIds: studentIds.isEmpty ? null : studentIds,
    );
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.classCreatedSuccessfully),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true); // Return true to trigger reload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? l10n.failedToCreateClass),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l10n.ok,
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    required BuildContext context,
    bool isRequired = false,
  }) {
    return ClassTheme.inputDecoration(
      context: context,
      labelText: labelText,
      icon: icon,
      hintText: hintText,
      isRequired: isRequired,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ClassConstants.cardPadding),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: ClassConstants.formMaxWidth),
            decoration: ClassTheme.cardDecoration(context),
            padding: EdgeInsets.all(ClassConstants.cardPadding),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.createNewClass,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ClassConstants.sectionSpacing),

                  // Required fields hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.indicatesRequiredFields,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Class Name
                  TextFormField(
                    controller: _classNameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration:
                        _inputDecoration(
                          context: context,
                          labelText: l10n.className,
                          hintText: l10n.enterClassName,
                          icon: Icons.class_,
                          isRequired: true,
                        ).copyWith(
                          suffixIcon: _isCheckingClassName
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                    onChanged: (value) {
                      _checkClassNameExists(value);
                    },
                    validator: (value) {
                      // First check basic validation
                      final basicError = ClassValidators.className(value, l10n);
                      if (basicError != null) {
                        return basicError;
                      }
                      // Then check if class name exists (real-time validation)
                      if (_classNameValidationError != null) {
                        return _classNameValidationError;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: l10n.description,
                      hintText:
                          '${l10n.enterDescription} (${l10n.atLeast10Words})',
                      icon: Icons.description,
                      isRequired: true,
                    ),
                    validator: (value) =>
                        ClassValidators.description(value, l10n),
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Focus Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedFocus,
                    dropdownColor: const Color(0xFFF5FAFC),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: l10n.focusOptional,
                      hintText: l10n.focusOptional,
                      icon: Icons.category,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.noneOptional),
                      ),
                      const DropdownMenuItem(
                        value: 'HTML',
                        child: Text('HTML'),
                      ),
                      const DropdownMenuItem(value: 'CSS', child: Text('CSS')),
                      const DropdownMenuItem(
                        value: 'JavaScript',
                        child: Text('JavaScript'),
                      ),
                      const DropdownMenuItem(value: 'PHP', child: Text('PHP')),
                    ],
                    validator: ClassValidators.focus,
                    onChanged: (value) {
                      setState(() => _selectedFocus = value);
                      // Trigger validation after change
                      _formKey.currentState?.validate();
                    },
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Teacher Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTeacher,
                    dropdownColor: const Color(0xFFF5FAFC),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: l10n.assignTeacherOptional,
                      hintText: _loadingTeachers
                          ? l10n.loading
                          : l10n.selectTeacher,
                      icon: Icons.person,
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      final l10n = AppLocalizations.of(context)!;
                      return [
                        Text(l10n.noneOptional),
                        ..._teachers.map((teacher) {
                          return Text(
                            teacher['name'] as String? ?? '',
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ];
                    },
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.noneOptional),
                      ),
                      ..._teachers.map((teacher) {
                        final status =
                            teacher['account_status'] as String? ?? 'unknown';
                        final isActive = status == 'active';
                        return DropdownMenuItem(
                          value: teacher['user_id'] as String,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        teacher['name'] as String? ?? '',
                                        style: TextStyle(
                                          color: isActive
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurface
                                                    .withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        teacher['email'] as String? ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isActive
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onSurfaceVariant
                                                    .withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: _loadingTeachers
                        ? null
                        : (value) {
                            if (_selectedTeacher != value) {
                              setState(() => _selectedTeacher = value);
                            }
                          },
                    // Optional: no validator to keep it optional
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Students
                  Text(
                    l10n.assignStudentsOptional,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),

                  Column(
                    children: List.generate(_selectedStudents.length, (index) {
                      final availableStudents = _getAvailableStudents(index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStudents[index],
                          dropdownColor: const Color(0xFFF5FAFC),
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: _inputDecoration(
                            context: context,
                            labelText: l10n.studentNumber(index + 1),
                            hintText: _loadingStudents
                                ? l10n.loading
                                : l10n.selectStudents,
                            icon: Icons.person_add,
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            final l10n = AppLocalizations.of(context)!;
                            return [
                              Text(l10n.noneOptional),
                              ...availableStudents.map((student) {
                                return Text(
                                  student['name'] as String? ?? '',
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ];
                          },
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.noneOptional),
                            ),
                            ...availableStudents.map((student) {
                              final status =
                                  student['account_status'] as String? ??
                                  'unknown';
                              final isActive = status == 'active';
                              return DropdownMenuItem(
                                value: student['user_id'] as String,
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              student['name'] as String? ?? '',
                                              style: TextStyle(
                                                color: isActive
                                                    ? colorScheme.onSurface
                                                    : colorScheme.onSurface
                                                          .withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              student['email'] as String? ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isActive
                                                    ? colorScheme
                                                          .onSurfaceVariant
                                                    : colorScheme
                                                          .onSurfaceVariant
                                                          .withOpacity(0.6),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                          onChanged: _loadingStudents
                              ? null
                              : (value) {
                                  if (_selectedStudents[index] != value) {
                                    setState(
                                      () => _selectedStudents[index] = value,
                                    );
                                  }
                                },
                        ),
                      );
                    }),
                  ),

                  TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedStudents.add(null));
                    },
                    icon: Icon(Icons.add, color: colorScheme.onSurface),
                    label: Text(
                      l10n.addStudent,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),

                  SizedBox(height: ClassConstants.sectionSpacing),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _resetForm,
                        child: Text(
                          l10n.reset,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Trigger validation on all fields
                          _formKey.currentState?.validate();
                          _createClass();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.create),
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
