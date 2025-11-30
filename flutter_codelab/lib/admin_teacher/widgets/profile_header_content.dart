import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/user_data.dart';

class ProfileHeaderContent extends StatelessWidget {
  final UserDetails currentUser;
  final VoidCallback onLogoutPressed;

  const ProfileHeaderContent({
    super.key,
    required this.currentUser,
    required this.onLogoutPressed,
  });

  Color _getRoleColor(String role, ColorScheme scheme) {
    switch (role.toLowerCase()) {
      case 'admin': return scheme.error;
      case 'teacher': return scheme.tertiary;
      case 'student': return scheme.primary;
      default: return scheme.secondary;
    }
  }

  // --- NEW: Helper method to build the profile display widget ---
  Widget _buildProfileDisplay(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // User's Name
        Flexible( 
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Text(
              'Hello, ${currentUser.name}', 
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 14, 
              ),
              overflow: TextOverflow.ellipsis, 
              maxLines: 1,
            ),
          ),
        ),
        
        // Profile Avatar with initials
        CircleAvatar(
          radius: 16, 
          backgroundColor: _getRoleColor(currentUser.roleName, colorScheme),
          foregroundColor: colorScheme.onPrimary,
          child: Text(
            currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : '?',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16, 
            ),
          ),
        ),
        
        // Dropdown Arrow (matching the image style)
        Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
      ],
    );
  }

  // --- REPLACED: Use PopupMenuButton for native dropdown menu ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // MODIFIED: Increased top padding (4.0) and reduced bottom padding (0.0) 
      // to shift content down without increasing overall vertical size.
      padding: const EdgeInsets.fromLTRB(24.0, 15.0, 24.0, 0.0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // The PopupMenuButton replaces the InkWell and AlertDialog logic.
          // It uses the built profile display widget as its child.
          PopupMenuButton<String>(
            // Set offset to position the menu directly below the icon/profile area
            offset: const Offset(0, 48), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            
            // This is the clickable area: the profile name + avatar + arrow
            child: _buildProfileDisplay(colorScheme, textTheme),
            
            // Handle selection from the menu items
            onSelected: (String result) {
              if (result == 'logout') {
                onLogoutPressed();
              }
            },
            
            // Define the content of the menu items
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // --- Placeholder Items (Kept: Accessibility, Profile, Private files, Reports) ---
              
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuDivider(), // Divider

              // --- Logout Item (Icon color adapts to the theme) ---
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout, 
                      color: colorScheme.onSurface, 
                    ), 
                    const SizedBox(width: 8),
                    Text(
                      'Log out',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.error, // Text color remains error red for emphasis
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}