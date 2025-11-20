import 'package:flutter/material.dart';
import '../api/class_api.dart';

class EditClassPage extends StatefulWidget {
  final dynamic classData;

  const EditClassPage({Key? key, required this.classData}) : super(key: key);

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController classNameController;
  late TextEditingController teacherIdController;
  late TextEditingController descriptionController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    classNameController = TextEditingController(
      text: widget.classData['class_name'],
    );
    teacherIdController = TextEditingController(
      text: widget.classData['teacher_id'].toString(),
    );
    descriptionController = TextEditingController(
      text: widget.classData['description'] ?? "",
    );
  }

  @override
  void dispose() {
    classNameController.dispose();
    teacherIdController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final data = {
      "class_name": classNameController.text.trim(),
      "teacher_id": int.parse(teacherIdController.text.trim()),
      "description": descriptionController.text.trim(),
      "admin_id": widget.classData["admin_id"],
    };

    final success = await ClassApi.updateClass(
      widget.classData["class_id"],
      data,
    );

    setState(() => loading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update class")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF2E313D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E313D),
        elevation: 0,
        title: const Text("Edit Class"),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
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
                    'Edit Class Details',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CLASS NAME
                  TextFormField(
                    controller: classNameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: "Class Name",
                      hintText: "Enter class name",
                      icon: Icons.class_,
                      colorScheme: colorScheme,
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? "Class name required" : null,
                  ),
                  const SizedBox(height: 16),

                  // TEACHER ID
                  TextFormField(
                    controller: teacherIdController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: "Teacher ID",
                      hintText: "Enter teacher ID",
                      icon: Icons.person,
                      colorScheme: colorScheme,
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? "Teacher ID required" : null,
                  ),
                  const SizedBox(height: 16),

                  // DESCRIPTION
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: "Description",
                      hintText: "Enter description",
                      icon: Icons.description,
                      colorScheme: colorScheme,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                            borderRadius: BorderRadius.circular(12),
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
