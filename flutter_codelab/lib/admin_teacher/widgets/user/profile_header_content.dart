import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ADDED
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/user_detail_page.dart';
import 'package:flutter_codelab/pages/help_support_pages.dart';
import 'package:flutter_codelab/controllers/locale_controller.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

class ProfileHeaderContent extends StatelessWidget {
  final UserDetails currentUser;
  final VoidCallback onLogoutPressed;
  final VoidCallback onMenuPressed; // ADDED

  const ProfileHeaderContent({
    super.key,
    required this.currentUser,
    required this.onLogoutPressed,
    required this.onMenuPressed, // ADDED
  });

  Color _getRoleColor(String role, ColorScheme scheme) {
    switch (role.toLowerCase()) {
      case 'admin':
        return scheme.brightness == Brightness.dark
            ? Colors.pinkAccent
            : Colors.pink;
      case 'teacher':
        return scheme.brightness == Brightness.dark
            ? Colors.orangeAccent
            : Colors.orange;
      case 'student':
        return scheme.brightness == Brightness.dark
            ? Colors.lightBlueAccent
            : Colors.blue;
      default:
        return scheme.secondary;
    }
  }

  // --- NEW: Helper method to build the profile display widget ---
  Widget _buildProfileDisplay(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // ADDED
      children: [
        // User's Name
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Text(
              AppLocalizations.of(context)!.helloUser(currentUser.name),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold, // Bolder for standalone name
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),

        // Profile Avatar with initials
        Builder(
          builder: (context) {
            final roleColor = _getRoleColor(currentUser.roleName, colorScheme);
            return CircleAvatar(
              radius: 16,
              backgroundColor: roleColor.withOpacity(0.2),
              foregroundColor: roleColor,
              child: Text(
                currentUser.name.isNotEmpty
                    ? currentUser.name[0].toUpperCase()
                    : '?',
                style: textTheme.titleMedium?.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // CHANGED
        crossAxisAlignment: CrossAxisAlignment.center, // ADDED
        children: [
          // --- LEFT SIDE: Menu & Logo ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // ADDED
            children: [
              IconButton(
                onPressed: onMenuPressed,
                icon: Icon(Icons.menu, color: colorScheme.onSurface),
              ),
              const SizedBox(width: 8),
              // Logo / Title
              Image.asset('assets/CodePlay.png', height: 32),
              const SizedBox(width: 12),
              Text(
                'CodePlay', // CHANGED: Updated from Kalmnest to CodePlay
                style: GoogleFonts.outfit(
                  // REPLACED with GoogleFonts.outfit
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // --- RIGHT SIDE: Existing Actions ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // ADDED
            children: [
              // Help Menu
              PopupMenuButton<String>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tooltip: 'Help',
                icon: Icon(
                  Icons.help_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (String result) {
                  if (result == 'help_center') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HelpCenterPage(),
                      ),
                    );
                  } else if (result == 'faq') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const FaqPage()),
                    );
                  } else if (result == 'feedback') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FeedbackPage(),
                      ),
                    );
                  } else if (result == 'user_manual') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserManualPage(),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'help_center',
                    child: Text('Help Center'),
                  ),
                  const PopupMenuItem<String>(value: 'faq', child: Text('FAQ')),
                  const PopupMenuItem<String>(
                    value: 'feedback',
                    child: Text('Feedback'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'user_manual',
                    child: Text('User Manual'),
                  ),
                ],
              ),
              const SizedBox(width: 16), // Spacing between help and profile
              // --- NEW: Language Switcher Button ---
          ValueListenableBuilder<Locale>(
            valueListenable: LocaleController.instance,
            builder: (context, locale, child) {
              return PopupMenuButton<Locale>(
                tooltip: AppLocalizations.of(context)!.selectLanguage,
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.language, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        locale.languageCode.toUpperCase(),
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                onSelected: (Locale newLocale) {
                  LocaleController.instance.switchLocale(newLocale);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                  const PopupMenuItem<Locale>(
                    value: Locale('en'),
                    child: Text(
                      'English',
                    ), // Can use AppLocalizations.of(context)!.english if desired
                  ),
                  const PopupMenuItem<Locale>(
                    value: Locale('ms'),
                    child: Text(
                      'Bahasa Malaysia',
                    ), // Can use AppLocalizations.of(context)!.bahasaMalaysia if desired
                  ),
                ],
              );
            },
          ),

          // The PopupMenuButton replaces the InkWell and AlertDialog logic.
              // It uses the built profile display widget as its child.
              PopupMenuButton<String>(
                // Set offset to position the menu directly below the icon/profile area
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                // This is the clickable area: the profile name + avatar + arrow
                child: _buildProfileDisplay(context, colorScheme, textTheme),

                // Handle selection from the menu items
                onSelected: (String result) async {
                  if (result == 'logout') {
                    onLogoutPressed();
                  } else if (result == 'profile') {
                    // Navigate to Self-Edit Profile
                    // Note: user_detail_page handles isSelfProfile internally
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserDetailPage(
                          userId: currentUser.id,
                          userName: currentUser.name,
                          isSelfProfile: true, // Enable restricted mode
                        ),
                      ),
                    );
                  }
                },

                // Define the content of the menu items
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  // --- Placeholder Items (Kept: Accessibility, Profile, Private files, Reports) ---
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Text(AppLocalizations.of(context)!.userProfile),
                  ),
                  const PopupMenuDivider(), // Divider
                  // --- Logout Item (Icon color adapts to the theme) ---
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.logout,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme
                                .error, // Text color remains error red for emphasis
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
