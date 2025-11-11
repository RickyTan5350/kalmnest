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

  // List to store selected students
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
      // Replace with actual adminId from your app/session
      int adminId = 1;
      int teacherId = _selectedTeacher!; // Already int

      // make sure teacherId is integer

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
          const SnackBar(
            content: Text('Class created successfully!'),
            backgroundColor: Color(0xFF39B5E7),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Class',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a new class to the system',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Card container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBDBDBD), width: 1.35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Enter class information',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class Name
                          const Text('Class Name *'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _classNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter class name',
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Please enter class name'
                                : null,
                          ),

                          const SizedBox(height: 16),
                          // Description
                          const Text('Description *'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Enter description',
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Please enter description'
                                : null,
                          ),

                          const SizedBox(height: 16),
                          // Teacher selection
                          const Text('Assign Teacher *'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedTeacher,
                            decoration: InputDecoration(
                              hintText: 'Select teacher',
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text('Teacher 1'),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text('Teacher 2'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('Teacher 3'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedTeacher = value;
                              });
                            },
                            validator: (value) => value == null
                                ? 'Please select a teacher'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Student selection
                          const Text('Enroll Students'),
                          const SizedBox(height: 8),

                          Column(
                            children: List.generate(_selectedStudents.length, (
                              index,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedStudents[index],
                                  decoration: InputDecoration(
                                    hintText: 'Select student ${index + 1}',
                                    filled: true,
                                    fillColor: const Color(0xFFEEEEEE),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
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
                                    setState(() {
                                      _selectedStudents[index] = value;
                                    });
                                  },
                                ),
                              );
                            }),
                          ),

                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedStudents.add(null);
                              });
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Color(0xFF1C1B1F),
                            ),
                            label: const Text(
                              'Add Student',
                              style: TextStyle(color: Color(0xFF1C1B1F)),
                            ),
                          ),

                          const SizedBox(height: 24),
                          // Buttons: Reset Form & Create Class
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: _resetForm,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFBDBDBD),
                                    width: 1.35,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Reset Form',
                                  style: TextStyle(
                                    color: Color(0xFF1C1B1F),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _createClass,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Create Class'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
