// lib/widgets/edit_class_page.dart
import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/constants/class_constants.dart';
import 'package:code_play/admin_teacher/widgets/class/class_theme_extensions.dart';

class EditClassPage extends StatefulWidget {
  final dynamic classData;

  const EditClassPage({super.key, required this.classData});

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController classNameController;
  late TextEditingController descriptionController;

  String? _selectedTeacher;
  List<String?> _selectedStudents = [];

  // Data from backend
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  bool _loadingTeachers = true;
  bool _loadingStudents = true;
  bool loading = false;

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

    classNameController = TextEditingController(
      text: widget.classData['class_name'],
    );
    descriptionController = TextEditingController(
      text: widget.classData['description'] ?? "",
    );

    // Store initial teacher ID to set after teachers are loaded
    final initialTeacherId = widget.classData['teacher_id'];

    // Set initial enrolled students
    if (widget.classData['students'] != null &&
        widget.classData['students'] is List) {
      final enrolledStudents = widget.classData['students'] as List;
      _selectedStudents = enrolledStudents
          .map((s) => s['user_id']?.toString() ?? s['student_id']?.toString())
          .whereType<String>()
          .toList();
      if (_selectedStudents.isEmpty) {
        _selectedStudents = [null];
      }
    } else {
      _selectedStudents = [null];
    }

    // Fetch data first, then set initial values to avoid dropdown assertion errors
    _fetchTeachers().then((_) {
      if (mounted && initialTeacherId != null) {
        // Check if teacher exists in the fetched list before setting
        final teacherExists = _teachers.any(
          (t) => t['user_id']?.toString() == initialTeacherId.toString(),
        );
        if (teacherExists) {
          setState(() => _selectedTeacher = initialTeacherId.toString());
        }
      }
    });
    _fetchStudents().then((_) {
      if (mounted) {
        // Ensure all selected student IDs exist in the fetched list
        // If not, set to null to avoid dropdown assertion errors
        setState(() {
          _selectedStudents = _selectedStudents.map((id) {
            if (id == null) return null;
            final exists = _students.any(
              (s) => s['user_id']?.toString() == id.toString(),
            );
            return exists ? id : null;
          }).toList();
          // Ensure at least one null entry exists
          if (_selectedStudents.isEmpty ||
              _selectedStudents.every((id) => id != null)) {
            _selectedStudents.add(null);
          }
        });
      }
    });
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
    classNameController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    // Collect student ids (non-null)
    final studentIds = _selectedStudents.whereType<String>().toList();

    final data = {
      "class_name": classNameController.text.trim(),
      "teacher_id": _selectedTeacher,
      "description": descriptionController.text.trim(),
      "admin_id": widget.classData["admin_id"],
      "student_ids": studentIds.isEmpty ? null : studentIds,
    };

    final result = await ClassApi.updateClass(
      widget.classData["class_id"],
      data,
    );

    setState(() => loading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Class updated successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context, true);
    } else {
      // Show specific error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update class'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
      // Don't keep changes - reload original data
      await _reloadClassData();
    }
  }

  Future<void> _reloadClassData() async {
    // Reload class data from backend
    final updatedData = await ClassApi.fetchClassById(
      widget.classData["class_id"],
    );
    if (updatedData != null && mounted) {
      setState(() {
        classNameController.text = updatedData['class_name'] ?? '';
        descriptionController.text = updatedData['description'] ?? '';

        // Reset teacher selection
        final teacherId = updatedData['teacher_id'];
        if (teacherId != null) {
          _selectedTeacher = teacherId.toString();
        } else {
          _selectedTeacher = null;
        }

        // Reset student selections
        final studentsList = updatedData['students'] as List?;
        if (studentsList != null && studentsList.isNotEmpty) {
          _selectedStudents = studentsList
              .map((s) => s['user_id']?.toString())
              .whereType<String>()
              .toList();
          if (_selectedStudents.isEmpty) {
            _selectedStudents = [null];
          }
        } else {
          _selectedStudents = [null];
        }
      });
    }
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
        title: const Text("Edit Class"),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
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
                    'Edit Class Details',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ClassConstants.sectionSpacing),

                  // CLASS NAME
                  TextFormField(
                    controller: classNameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: "Class Name",
                      hintText: "Enter class name",
                      icon: Icons.class_,
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? "Class name required" : null,
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // TEACHER DROPDOWN
                  // Ensure value exists in items to avoid assertion error
                  DropdownButtonFormField<String>(
                    initialValue:
                        (_selectedTeacher == null ||
                            _teachers.any(
                              (t) =>
                                  t['user_id']?.toString() ==
                                  _selectedTeacher.toString(),
                            ))
                        ? _selectedTeacher
                        : null,
                    dropdownColor: colorScheme.surface,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: "Assign Teacher (Optional)",
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
                                        ? colorScheme.primaryContainer
                                        : colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius * 0.33),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? colorScheme.primary
                                          : colorScheme.error,
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
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // STUDENTS ENROLLMENT
                  Text(
                    'Enroll Students',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: ClassConstants.defaultPadding * 0.5),
                  Column(
                    children: List.generate(_selectedStudents.length, (index) {
                      final availableStudents = _getAvailableStudents(index);
                      // Ensure value exists in items to avoid assertion error
                      final currentValue = _selectedStudents[index];
                      final validValue =
                          (currentValue == null ||
                              availableStudents.any(
                                (s) =>
                                    s['user_id']?.toString() ==
                                    currentValue.toString(),
                              ))
                          ? currentValue
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DropdownButtonFormField<String>(
                          initialValue: validValue,
                          dropdownColor: const Color(
                            0xFFF5FAFC,
                          ), // Match create page
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
                    icon: Icon(
                      Icons.add,
                      color: colorScheme.onSurface,
                    ), // Match create page
                    label: Text(
                      'Add Student',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ), // Match create page
                    ),
                  ),
                  SizedBox(height: ClassConstants.formSpacing),

                  // DESCRIPTION
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: "Description",
                      hintText: "Enter description",
                      icon: Icons.description,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter description'
                        : null,
                  ),

                  SizedBox(height: ClassConstants.sectionSpacing),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: loading ? null : saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ClassConstants.inputBorderRadius),
                          ),
                        ),
                        child: loading
                            ? CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                              )
                            : const Text("Save Changes"),
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
