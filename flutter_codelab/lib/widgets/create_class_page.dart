//lib/widgets/create_class_page.dart
import 'package:flutter/material.dart';
import '../api/class_api.dart';
import '../models/class_data.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedTeacher;
  List<String?> _selectedStudents = [null];

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
      int adminId = 1;
      int teacherId = _selectedTeacher!;
      String description = _descriptionController.text;
      String className = _classNameController.text;

      final result = await ClassApi.createClass(
        className: className,
        teacherId: teacherId,
        description: description,
        adminId: adminId,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFF2E313D), // Same as dialog
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E313D),
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
              color: const Color(0xFF2E313D),
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
                  DropdownButtonFormField<int>(
                    value: _selectedTeacher,
                    dropdownColor: const Color(0xFF2E313D),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Assign Teacher',
                      hintText: 'Select teacher',
                      icon: Icons.person,
                      colorScheme: colorScheme,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Teacher 1')),
                      DropdownMenuItem(value: 2, child: Text('Teacher 2')),
                      DropdownMenuItem(value: 3, child: Text('Teacher 3')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTeacher = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select a teacher' : null,
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DropdownButtonFormField<String>(
                          value: _selectedStudents[index],
                          dropdownColor: const Color(0xFF2E313D),
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: _inputDecoration(
                            labelText: 'Student ${index + 1}',
                            icon: Icons.person_add,
                            colorScheme: colorScheme,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'student1',
                              child: Text('Student 1'),
                            ),
                            DropdownMenuItem(
                              value: 'student2',
                              child: Text('Student 2'),
                            ),
                            DropdownMenuItem(
                              value: 'student3',
                              child: Text('Student 3'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStudents[index] = value);
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

