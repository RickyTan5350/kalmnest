import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';

// Utility function to show the dialog
void showCreateUserAccountDialog({
  required BuildContext context,
  required void Function(BuildContext context, String message, Color color)
      showSnackBar,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      // Use AlertDialog for a floating modal design, matching the achievement dialog
      return CreateUserAccountDialog(showSnackBar: showSnackBar); 
    },
  );
}

class CreateUserAccountDialog extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
      showSnackBar;

  const CreateUserAccountDialog({super.key, required this.showSnackBar});

  @override
  State<CreateUserAccountDialog> createState() => _CreateUserAccountDialogState();
}

class _CreateUserAccountDialogState extends State<CreateUserAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final UserApi _userApi = UserApi();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController(); // <--- ADDED: Controller for password confirmation

  // Variables
  String? _selectedGender;
  String? _selectedRole = 'Student'; // Default role to student
  bool _accountStatus = true; // Default to active

  bool _isLoading = false;

  final List<String> _genders = ['male', 'female'];
  final List<String> _roles = ['Admin', 'Student', 'Teacher'];

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneNoController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose(); // <--- ADDED to dispose list
    super.dispose();
  }

  // Submission logic, mirroring _submitForm
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Additionally check if password and confirmation match if they are both filled
    if (_passwordController.text != _passwordConfirmationController.text) {
        widget.showSnackBar(context, 'Error: Password and confirmation must match.', Colors.red);
        return;
    }


    setState(() { _isLoading = true; });

    // --- UPDATED: Pass passwordConfirmation and roleName ---
    final data = UserData(
      email: _emailController.text,
      name: _nameController.text,
      phone_no: _phoneNoController.text.isNotEmpty ? _phoneNoController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      gender: _selectedGender,
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text, // <--- ADDED
      accountStatus: _accountStatus,
      roleName: _selectedRole!, // <--- RENAMED
    );

    try {
      await _userApi.createUser(data);

      if (mounted) {
        widget.showSnackBar(context, 'User account successfully created!', Colors.green);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // --- UPDATED: Handle 422 validation errors and network errors ---
        if (e.toString().startsWith('Exception: ${UserApi.validationErrorCode}:')) {
          // Extracts the formatted validation message from the 422 error body
          final message = e.toString().substring('Exception: ${UserApi.validationErrorCode}:'.length);
          widget.showSnackBar(context, 'Validation Error:\n$message', Colors.red);
        } else if (e.toString().startsWith('Exception: Network Error:')) {
          // Handles connection refused, incorrect URL, etc.
          final message = e.toString().substring('Exception: Network Error:'.length);
          widget.showSnackBar(context, 'Network Error: Check API URL and server status.', Colors.red);
        } else {
          // Generic or unexpected server error
          widget.showSnackBar(context, 'An unknown error occurred: ${e.toString()}', Colors.red);
        }
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Input decoration helper, mirroring the _inputDecoration in admin_create_achievement_page.dart
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
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: const Color(0xFF2E313D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24.0),
      // Use SizedBox to constrain the width of the dialog, matching the achievement dialog
      content: SizedBox(
        width: 360, 
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create New User',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Email
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Email', icon: Icons.email, colorScheme: colorScheme,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Name', icon: Icons.person, colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Password', icon: Icons.lock, colorScheme: colorScheme,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // --- ADDED: Password Confirmation Field ---
                TextFormField(
                  controller: _passwordConfirmationController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Confirm Password', icon: Icons.lock_open, colorScheme: colorScheme,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // --- END ADDED ---
                
                // Phone Number
                TextFormField(
                  controller: _phoneNoController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Phone No (Optional)', icon: Icons.phone, colorScheme: colorScheme,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Address (Optional)', icon: Icons.location_on, colorScheme: colorScheme,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  dropdownColor: const Color(0xFF2E313D),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Gender (Optional)', icon: Icons.people, colorScheme: colorScheme,
                  ),
                  items: _genders
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 16),
                
                // Role Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  dropdownColor: const Color(0xFF2E313D),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Role', icon: Icons.badge, colorScheme: colorScheme,
                  ),
                  items: _roles
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please select a role';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Account Status Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Status:',
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                      ),
                      Switch(
                        value: _accountStatus,
                        onChanged: (bool value) {
                          setState(() {
                            _accountStatus = value;
                          });
                        },
                      ),
                      Text(
                        _accountStatus ? 'Active' : 'Inactive',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      // The button style matches the one used in create_achievement_page.dart
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create User'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}