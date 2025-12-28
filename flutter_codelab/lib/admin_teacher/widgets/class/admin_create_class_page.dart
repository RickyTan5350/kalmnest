//lib/widgets/create_class_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/constants/class_constants.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_theme_extensions.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_color_picker.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_icon_picker.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_customization.dart';

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
  List<String?> _selectedStudents = [null];
  String _selectedColor = 'blue';
  String _selectedIcon = 'school_rounded';

  // Data from backend
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  bool _loadingTeachers = true;
  bool _loadingStudents = true;

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
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _classNameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedTeacher = null;
      _selectedStudents = [null];
    });
  }

  void _createClass() async {
    if (_formKey.currentState?.validate() ?? false) {
      String? adminId; // optional; backend will use current admin
      String? teacherId = _selectedTeacher;
      String description = _descriptionController.text;
      String className = _classNameController.text;

      // collect student ids (non-null)
      final studentIds = _selectedStudents.whereType<String>().toList();

      final result = await ClassApi.createClass(
        className: className,
        teacherId: teacherId,
        description: description,
        adminId: adminId,
        studentIds: studentIds.isEmpty ? null : studentIds,
        icon: _selectedIcon,
        color: _selectedColor,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class created successfully!'),
           backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create class'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    required BuildContext context,
  }) {
    return ClassTheme.inputDecoration(
      context: context,
      labelText: labelText,
      icon: icon,
      hintText: hintText,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Class',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ClassConstants.sectionSpacing),

                  // Class Name
                  TextFormField(
                    controller: _classNameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: 'Class Name',
                      hintText: 'Enter class name',
                      icon: Icons.class_,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter class name'
                        : null,
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: 'Description',
                      hintText: 'Enter description',
                      icon: Icons.description,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter description'
                        : null,
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Color Picker
                  ClassColorPicker(
                    selectedColor: _selectedColor,
                    onColorSelected: (color) {
                      setState(() => _selectedColor = color);
                    },
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Icon Picker
                  ClassIconPicker(
                    selectedIcon: _selectedIcon,
                    onIconSelected: (icon) {
                      setState(() => _selectedIcon = icon);
                    },
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // Teacher Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedTeacher,
                    dropdownColor: const Color(0xFFF5FAFC),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: 'Assign Teacher (Optional)',
                      hintText: _loadingTeachers
                          ? 'Loading...'
                          : 'Select teacher',
                      icon: Icons.person,
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        const Text('None (Optional)'),
                        ..._teachers.map((teacher) {
                          return Text(
                            teacher['name'] as String? ?? '',
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ];
                    },
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None (Optional)'),
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
                    'Enroll Students',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),

                  Column(
                    children: List.generate(_selectedStudents.length, (index) {
                      final availableStudents = _getAvailableStudents(index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DropdownButtonFormField<String>(
                          value: _selectedStudents[index],
                          dropdownColor: const Color(0xFFF5FAFC),
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: _inputDecoration(
                            context: context,
                            labelText: 'Student ${index + 1} (Optional)',
                            hintText: _loadingStudents
                                ? 'Loading...'
                                : 'Select student',
                            icon: Icons.person_add,
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            return [
                              const Text('None (Optional)'),
                              ...availableStudents.map((student) {
                                return Text(
                                  student['name'] as String? ?? '',
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ];
                          },
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('None (Optional)'),
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
                      'Add Student',
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
                          'Reset',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _createClass,
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
                        child: const Text('Create'),
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
