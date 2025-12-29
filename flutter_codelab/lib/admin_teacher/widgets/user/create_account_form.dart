import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/utils/formatters.dart';
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
  State<CreateUserAccountDialog> createState() =>
      _CreateUserAccountDialogState();
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
  final TextEditingController _passwordConfirmationController =
      TextEditingController(); // <--- ADDED: Controller for password confirmation

  // Variables
  String? _selectedGender;
  String? _selectedRole = 'Student'; // Default role to student
  bool _accountStatus = true; // Default to active
  Map<String, String> _serverErrors = {}; // Store server-side errors

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

    // Clear previous server errors on new submission attempt
    setState(() {
      _serverErrors.clear();
    });

    // Additionally check if password and confirmation match if they are both filled
    if (_passwordController.text != _passwordConfirmationController.text) {
      widget.showSnackBar(
        context,
        'Error: Password and confirmation must match.',
        Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // --- UPDATED: Pass passwordConfirmation and roleName ---
    final data = UserData(
      email: _emailController.text,
      name: _nameController.text,
      phone_no: _phoneNoController.text.isNotEmpty
          ? _phoneNoController.text
          : null,
      address: _addressController.text.isNotEmpty
          ? _addressController.text
          : null,
      gender: _selectedGender,
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text, // <--- ADDED
      accountStatus: _accountStatus,
      roleName: _selectedRole!, // <--- RENAMED
    );

    try {
      await _userApi.createUser(data);

      if (mounted) {
        widget.showSnackBar(
          context,
          'User account successfully created!',
          Colors.green,
        );
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          // Map the errors: key -> first error message in list
          e.errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              _serverErrors[key] = value.first.toString();
            }
          });
        });
        // Re-trigger validation to show the errors in the fields
        _formKey.currentState!.validate();

        // Optional: Show a snackbar summary if you want, or trust the fields.
        // For now, removing the generic validation snackbar to rely on inline errors.
      }
    } catch (e) {
      if (mounted) {
        final errorColor = Theme.of(
          context,
        ).colorScheme.error; // Standardize color
        String errorString = e.toString();

        if (errorString.startsWith('Exception: Network Error:')) {
          // Handles connection refused, incorrect URL, etc.
          final message = errorString.substring(
            'Exception: Network Error:'.length,
          );
          widget.showSnackBar(
            context,
            'Network Error: Check API URL and server status.',
            errorColor,
          );
        } else {
          // Generic or unexpected server error
          widget.showSnackBar(
            context,
            'An unknown error occurred: ${errorString.replaceAll('Exception: ', '')}',
            errorColor,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      // FIX: Use colorScheme.surface instead of hardcoded dark color
      backgroundColor: colorScheme.surface,
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

                // Name
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Name',
                    icon: Icons.person,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (_serverErrors.containsKey('name')) {
                      return _serverErrors['name'];
                    }
                    if (value == null || value.isEmpty)
                      return 'Please enter a name';
                    return null;
                  },
                  onChanged: (value) {
                    if (_serverErrors.containsKey('name')) {
                      setState(() => _serverErrors.remove('name'));
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Email',
                    icon: Icons.email,
                    colorScheme: colorScheme,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (_serverErrors.containsKey('email')) {
                      setState(() => _serverErrors.remove('email'));
                    }
                  },
                  validator: (value) {
                    if (_serverErrors.containsKey('email')) {
                      return _serverErrors['email'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    final emailRegex = RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Password',
                    icon: Icons.lock,
                    colorScheme: colorScheme,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_serverErrors.containsKey('password')) {
                      return _serverErrors['password'];
                    }
                    if (value == null || value.isEmpty || value.length < 8)
                      return 'Password must be at least 8 characters';
                    return null;
                  },
                  onChanged: (value) {
                    if (_serverErrors.containsKey('password')) {
                      setState(() => _serverErrors.remove('password'));
                    }
                  },
                ),
                const SizedBox(height: 16),

                // --- ADDED: Password Confirmation Field ---
                TextFormField(
                  controller: _passwordConfirmationController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Confirm Password',
                    icon: Icons.lock_open,
                    colorScheme: colorScheme,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please confirm your password';
                    if (value != _passwordController.text)
                      return 'Passwords do not match';
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
                    labelText: 'Phone No',
                    icon: Icons.phone,
                    colorScheme: colorScheme,
                    hintText: 'e.g. 012-3456789',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [MalaysianPhoneFormatter()],
                  onChanged: (value) {
                    if (_serverErrors.containsKey('phone_no')) {
                      setState(() => _serverErrors.remove('phone_no'));
                    }
                  },
                  validator: (value) {
                    if (_serverErrors.containsKey('phone_no')) {
                      return _serverErrors['phone_no'];
                    }
                    if (value == null || value.isEmpty)
                      return 'Please enter a phone number';
                    // Regex for Malaysian Phone Numbers:
                    // Matches: +601..., 601..., 01...
                    // Supports dashes or no dashes
                    final phoneRegex = RegExp(
                      r'^(\+?6?0)[0-9]{1,2}-?[0-9]{7,8}$',
                    );
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Enter a valid Malaysian phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Address',
                    icon: Icons.location_on,
                    colorScheme: colorScheme,
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter an address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value:
                      _selectedGender, // Removed initialValue in favor of value
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Gender',
                    icon: Icons.people,
                    colorScheme: colorScheme,
                  ),
                  items: _genders.map((value) {
                    IconData icon;
                    if (value.toLowerCase() == 'male') {
                      icon = Icons.male;
                    } else if (value.toLowerCase() == 'female') {
                      icon = Icons.female;
                    } else {
                      icon = Icons.transgender;
                    }
                    return DropdownMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please select a gender';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  // FIX: Use colorScheme.surfaceContainer instead of hardcoded dark color
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Role',
                    icon: Icons.badge,
                    colorScheme: colorScheme,
                  ),
                  items: _roles.map((value) {
                    IconData icon;
                    switch (value.toLowerCase()) {
                      case 'admin':
                        icon = Icons.admin_panel_settings;
                        break;
                      case 'teacher':
                        icon = Icons.school;
                        break;
                      case 'student':
                        icon = Icons.person;
                        break;
                      default:
                        icon = Icons.person_outline;
                    }
                    return DropdownMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please select a role';
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
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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
