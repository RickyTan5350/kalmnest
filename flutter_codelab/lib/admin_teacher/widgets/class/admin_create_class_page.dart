//lib/widgets/create_class_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';

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
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create class'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
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
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.25),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC), // Same as dialog
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FAFC),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Class',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Class Name
                  TextFormField(
                    controller: _classNameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Class Name',
                      hintText: 'Enter class name',
                      icon: Icons.class_,
                      colorScheme: colorScheme,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter class name'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter description',
                      icon: Icons.description,
                      colorScheme: colorScheme,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter description'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Teacher Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTeacher,
                    dropdownColor: const Color(0xFFF5FAFC),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Assign Teacher (Optional)',
                      hintText: _loadingTeachers
                          ? 'Loading...'
                          : 'Select teacher',
                      icon: Icons.person,
                      colorScheme: colorScheme,
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
                        final status = teacher['account_status'] as String? ?? 'unknown';
                        final isActive = status == 'active';
                        return DropdownMenuItem(
                          value: teacher['user_id'] as String,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        teacher['name'] as String? ?? '',
                                        style: TextStyle(
                                          color: isActive 
                                              ? colorScheme.onSurface 
                                              : colorScheme.onSurface.withOpacity(0.6),
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
                                              : colorScheme.onSurfaceVariant.withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                      color: isActive ? Colors.green : Colors.red,
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
                  const SizedBox(height: 16),

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
                          initialValue: _selectedStudents[index],
                          dropdownColor: const Color(0xFFF5FAFC),
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: _inputDecoration(
                            labelText: 'Student ${index + 1} (Optional)',
                            hintText: _loadingStudents
                                ? 'Loading...'
                                : 'Select student',
                            icon: Icons.person_add,
                            colorScheme: colorScheme,
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
                              final status = student['account_status'] as String? ?? 'unknown';
                              final isActive = status == 'active';
                              return DropdownMenuItem(
                                value: student['user_id'] as String,
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              student['name'] as String? ?? '',
                                              style: TextStyle(
                                                color: isActive 
                                                    ? colorScheme.onSurface 
                                                    : colorScheme.onSurface.withOpacity(0.6),
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
                                                    ? colorScheme.onSurfaceVariant 
                                                    : colorScheme.onSurfaceVariant.withOpacity(0.6),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                            color: isActive ? Colors.green : Colors.red,
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

                  const SizedBox(height: 24),

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
