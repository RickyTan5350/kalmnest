import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final String userName; // Passed for the app bar title before loading

  const UserDetailPage({super.key, required this.userId, required this.userName});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserApi _userApi = UserApi();
  late Future<UserDetails> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userApi.getUserDetails(widget.userId);
  }

  // Helper to get role color (matching your list logic)
  Color _getRoleColor(String role, ColorScheme scheme) {
    switch (role.toLowerCase()) {
      case 'admin': return scheme.error;
      case 'teacher': return scheme.tertiary;
      case 'student': return scheme.primary;
      default: return scheme.secondary;
    }
  }
Future<bool> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User Account?'),
        content: Text(
          'Are you sure you want to permanently delete ${widget.userName}\'s account and all associated data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
  
  // --- NEW: Deletion Logic ---
  Future<void> _deleteUser() async {
    final bool confirmed = await _confirmDelete();
    if (!confirmed) return;

    if (!mounted) return;
    // Capture context before async gap to show SnackBar
    final BuildContext scaffoldContext = context; 

    try {
      await _userApi.deleteUser(widget.userId);

      // Show success message
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted user: ${widget.userName}'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop the details page and pass 'true' to signal success to the parent list view
      if (mounted) {
        Navigator.of(context).pop(true); 
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        centerTitle: true,
        actions: [
          FutureBuilder<UserDetails>(
            future: _userFuture,
            builder: (context, snapshot) {
              // Only show delete button if the page has successfully loaded the user details
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteUser,
                  tooltip: 'Delete User Account',
                );
              }
              // Hide while loading or on error
              return const SizedBox.shrink(); 
            },
          ),
        ],
      ),
      body: FutureBuilder<UserDetails>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading profile', style: textTheme.titleMedium),
                  Text(snapshot.error.toString().replaceAll('Exception: ', ''), style: textTheme.bodySmall),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No user data found."));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- Header Section (Avatar & Role) ---
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _getRoleColor(user.roleName, colorScheme),
                        foregroundColor: colorScheme.onPrimary,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: textTheme.displayMedium?.copyWith(color: colorScheme.onPrimary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.roleName,
                          style: textTheme.labelLarge?.copyWith(color: colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- Details Card (Combined) ---
                _buildDetailSection(
                  context,
                  title: "User Profile Details", // Combined title
                  icon: Icons.person_outline, // Generic icon for profile details
                  children: [
                    // Contact Information
                    _buildInfoRow(context, Icons.email_outlined, "Email", user.email),
                    _buildInfoRow(context, Icons.phone_outlined, "Phone", user.phoneNo),
                    _buildInfoRow(context, Icons.location_on_outlined, "Address", user.address),
                    
                    // Added a subtle divider to separate the two original logical groups
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    
                    // Personal Details
                    _buildInfoRow(context, Icons.transgender, "Gender", user.gender),
                    _buildInfoRow(context, Icons.calendar_today, "Joined Date", user.joinedDate.split('T')[0]), // Simple date formatting
                    _buildInfoRow(
                      context, 
                      Icons.info_outline, 
                      "Account Status", 
                      user.accountStatus.toUpperCase(),
                      valueColor: user.accountStatus == 'active' ? Colors.green : colorScheme.error,
                    ),
                  ],
                ),
                // Removed the extra SizedBox(height: 16) that was between the two original cards
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}