import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart'; // ADDED
import 'package:code_play/models/user_data.dart';
import 'package:code_play/admin_teacher/widgets/user/user_detail_page.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';
import 'package:code_play/widgets/language_selector.dart';
import 'package:code_play/widgets/user_avatar.dart';

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
            child: Builder(
              builder: (context) {
                final fullGreeting = AppLocalizations.of(
                  context,
                )!.helloUser(currentUser.name);
                final nameIdx = fullGreeting.indexOf(currentUser.name);

                if (nameIdx != -1) {
                  final prefix = fullGreeting.substring(0, nameIdx);
                  final suffix = fullGreeting.substring(
                    nameIdx + currentUser.name.length,
                  );
                  return Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: prefix,
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: currentUser.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: suffix,
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                }

                return Text(
                  fullGreeting,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
            ),
          ),
        ),

        // Profile Avatar with initials
        UserAvatar(
          name: currentUser.name,
          role: currentUser.roleName,
          size: 32,
          fontSize: 16,
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
                onSelected: (String result) async {
                  if (result == 'help_center') {
                    final Uri url = Uri.parse(
                      'https://misty-pruner-069.notion.site/2e1ee9e36cb0800e992aee5aba0a4ebe?v=2e1ee9e36cb081799b7d000c3be8d000&source=copy_link',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  } else if (result == 'faq') {
                    final Uri url = Uri.parse(
                      'https://misty-pruner-069.notion.site/FAQs-2e1ee9e36cb0805a96e1d29c7650094f?source=copy_link',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  } else if (result == 'feedback') {
                    final Uri url = Uri.parse(
                      'https://misty-pruner-069.notion.site/Feedback-2e1ee9e36cb080369eadfa37c10e66b6?source=copy_link',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  } else if (result == 'user_manual') {
                    final Uri url = Uri.parse(
                      'https://misty-pruner-069.notion.site/User-Manual-2e1ee9e36cb080e4bcc4fef7fea8bf2a?source=copy_link',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
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
              const SizedBox(width: 8),
              const LanguageSelector(),
              const SizedBox(width: 8),

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
