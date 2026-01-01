import 'package:flutter/material.dart';
import 'package:code_play/api/user_api.dart';
import 'package:code_play/utils/formatters.dart';
import 'package:code_play/models/user_data.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';
import 'package:code_play/widgets/password_strength_indicator.dart';

// Utility function to show the dialog
Future<bool?> showEditUserDialog({
  required BuildContext context,
  required UserDetails initialData,
  bool isSelfEdit = false,
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return EditUserDialog(
        initialData: initialData,
        isSelfEdit: isSelfEdit,
        showSnackBar: showSnackBar,
      );
    },
  );
}

class EditUserDialog extends StatefulWidget {
  final UserDetails initialData;
  final bool isSelfEdit;
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;

  const EditUserDialog({
    super.key,
    required this.initialData,
    this.isSelfEdit = false,
    required this.showSnackBar,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final UserApi _userApi = UserApi();

  // Controllers
  late final TextEditingController _emailController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneNoController;
  late final TextEditingController _addressController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  // Variables
  late String _selectedGender;
  late String _selectedRole;
  late bool _accountStatus;
  Map<String, String> _serverErrors = {}; // Store server-side errors

  bool _isPasswordVisible = false;

  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _roles = ['Admin', 'Student', 'Teacher'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _emailController = TextEditingController(text: widget.initialData.email);
    _nameController = TextEditingController(text: widget.initialData.name);
    _phoneNoController = TextEditingController(
      text: widget.initialData.phoneNo == 'N/A'
          ? ''
          : widget.initialData.phoneNo,
    );
    _addressController = TextEditingController(
      text: widget.initialData.address == 'N/A'
          ? ''
          : widget.initialData.address,
    );

    // Initialize state variables
    _selectedGender = widget.initialData.gender;
    _selectedRole = widget.initialData.roleName;
    _accountStatus = widget.initialData.accountStatus == 'active';

    // Ensure initial dropdown values are in the list, otherwise default to first valid option.
    if (!_genders.contains(_selectedGender)) {
      _selectedGender =
          _genders[0]; // Defaulting gender to Male if 'N/A' is stored
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneNoController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  String _getLocalizedGender(String gender) {
    final l10n = AppLocalizations.of(context)!;
    switch (gender.toLowerCase()) {
      case 'male':
        return l10n.male;
      case 'female':
        return l10n.female;

      default:
        return gender;
    }
  }

  String _getLocalizedRole(String role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role.toLowerCase()) {
      case 'student':
        return l10n.student;
      case 'teacher':
        return l10n.teacher;
      case 'admin':
        return l10n.admin;
      default:
        return role;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear previous server errors on new submission attempt
    setState(() {
      _serverErrors.clear();
    });

    final newPassword = _passwordController.text.trim();

    // Check if passwords are provided but don't match
    if (newPassword.isNotEmpty &&
        newPassword != _passwordConfirmationController.text.trim()) {
      widget.showSnackBar(
        context,
        AppLocalizations.of(context)!.passwordsMatchError,
        Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // --- Build the Update Payload (Only send fields that might change) ---
    final Map<String, dynamic> updatePayload = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_no': _phoneNoController.text.trim().isEmpty
          ? null
          : _phoneNoController.text.trim(),
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'gender': _selectedGender,
    };

    // Only allow updating Role and Status if NOT self-edit
    if (!widget.isSelfEdit) {
      updatePayload['role_name'] = _selectedRole;
      updatePayload['account_status'] = _accountStatus ? 'active' : 'inactive';
    }

    // Only include password if a new one was entered
    if (newPassword.isNotEmpty) {
      updatePayload['password'] = newPassword;
    }

    try {
      await _userApi.updateUser(widget.initialData.id, updatePayload);

      if (mounted) {
        widget.showSnackBar(
          context,
          AppLocalizations.of(context)!.userProfileUpdated,
          Colors.green,
        );
        // Pop dialog and return 'true' to signal a successful update/refresh needed
        Navigator.of(context).pop(true);
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
      }
    } catch (e) {
      if (mounted) {
        // Handle validation and network errors
        String errorString = e.toString();
        String displayMessage = 'An unknown error occurred.';
        Color errorColor = Theme.of(
          context,
        ).colorScheme.error; // Standardize color

        if (errorString.contains('403:')) {
          // Explicit message for 403 Forbidden
          displayMessage = AppLocalizations.of(
            context,
          )!.accessDeniedAdminModify;
        } else {
          displayMessage = AppLocalizations.of(
            context,
          )!.errorUpdatingProfile(errorString.replaceAll('Exception: ', ''));
        }

        widget.showSnackBar(
          context,
          displayMessage,
          errorColor,
        ); // Use theme error color
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    required ColorScheme colorScheme,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: enabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
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
      labelStyle: TextStyle(
        color: enabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
      fillColor: enabled
          ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
          : colorScheme.surfaceContainerHighest.withOpacity(0.1),
      filled: true,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24.0),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.editUserProfile,
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
                    labelText: AppLocalizations.of(context)!.name,
                    icon: Icons.person,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (_serverErrors.containsKey('name')) {
                      return _serverErrors['name'];
                    }
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.pleaseEnterName;
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
                    labelText: AppLocalizations.of(context)!.email,
                    icon: Icons.email,
                    colorScheme: colorScheme,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_serverErrors.containsKey('email')) {
                      return _serverErrors['email'];
                    }
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.pleaseEnterEmail;
                    final emailRegex = RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.enterValidEmail;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_serverErrors.containsKey('email')) {
                      setState(() => _serverErrors.remove('email'));
                    }
                  },
                ),
                const SizedBox(height: 16),

                // New Password
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration:
                      _inputDecoration(
                        labelText: AppLocalizations.of(context)!.newPassword,
                        icon: Icons.lock,
                        colorScheme: colorScheme,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                      ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (_serverErrors.containsKey('password')) {
                      return _serverErrors['password'];
                    }
                    if (value != null && value.isNotEmpty && value.length < 8)
                      return AppLocalizations.of(context)!.passwordLengthError;
                    return null;
                  },
                  onChanged: (value) {
                    if (_serverErrors.containsKey('password')) {
                      setState(() => _serverErrors.remove('password'));
                    }
                    setState(() {}); // Trigger rebuild for strength indicator
                  },
                ),
                PasswordStrengthIndicator(password: _passwordController.text),
                const SizedBox(height: 16),

                // Password Confirmation Field
                TextFormField(
                  controller: _passwordConfirmationController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration:
                      _inputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.confirmNewPassword,
                        icon: Icons.lock_open,
                        colorScheme: colorScheme,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                      ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return AppLocalizations.of(
                        context,
                      )!.confirmPasswordRequired;
                    }
                    if (value != _passwordController.text)
                      return AppLocalizations.of(context)!.passwordsDoNotMatch;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneNoController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: AppLocalizations.of(context)!.phone,
                    icon: Icons.phone,
                    colorScheme: colorScheme,
                    hintText: 'e.g. 012-3456789',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [MalaysianPhoneFormatter()],
                  validator: (value) {
                    if (_serverErrors.containsKey('phone_no')) {
                      return _serverErrors['phone_no'];
                    }
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.pleaseEnterPhone;
                    final phoneRegex = RegExp(
                      r'^(\+?6?0)[0-9]{1,2}-?[0-9]{7,8}$',
                    );
                    if (!phoneRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.enterValidPhone;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_serverErrors.containsKey('phone_no')) {
                      setState(() => _serverErrors.remove('phone_no'));
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: AppLocalizations.of(context)!.address,
                    icon: Icons.location_on,
                    colorScheme: colorScheme,
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.pleaseEnterAddress;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: AppLocalizations.of(context)!.genderLabel,
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
                          Text(_getLocalizedGender(value)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedGender = value!),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.pleaseSelectGender;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  onChanged: widget.isSelfEdit
                      ? null
                      : (value) => setState(() => _selectedRole = value!),
                  dropdownColor: colorScheme.surfaceContainer,
                  style: TextStyle(
                    color: widget.isSelfEdit
                        ? colorScheme.onSurface.withOpacity(0.5)
                        : colorScheme.onSurface,
                  ),
                  decoration: _inputDecoration(
                    labelText: AppLocalizations.of(context)!.roleLabel,
                    icon: Icons.badge,
                    colorScheme: colorScheme,
                    enabled: !widget.isSelfEdit,
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
                          Text(_getLocalizedRole(value)),
                        ],
                      ),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.pleaseSelectRole;
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
                        '${AppLocalizations.of(context)!.accountStatusLabel}:',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      Switch(
                        value: _accountStatus,
                        onChanged: widget.isSelfEdit
                            ? null
                            : (bool value) {
                                setState(() {
                                  _accountStatus = value;
                                });
                              },
                      ),
                      Text(
                        _accountStatus
                            ? AppLocalizations.of(context)!.active
                            : AppLocalizations.of(context)!.inactive,
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
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(AppLocalizations.of(context)!.saveChanges),
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
