import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/admin_teacher/services/breadcrumb_navigation.dart';
import 'edit_user_dialog.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'admin_student_achievements_page.dart';
import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/student/widgets/achievements/student_profile_achievements_page.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final String userName; // Passed for the app bar title before loading
  final List<BreadcrumbItem>? breadcrumbs;
  final bool isSelfProfile;
  final String viewerRole;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.userName,
    this.breadcrumbs,
    this.isSelfProfile = false,
    this.viewerRole = 'Student',
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserApi _userApi = UserApi();
  final AchievementApi _achievementApi = AchievementApi();
  late Future<UserDetails> _userFuture;
  Future<List<AchievementData>>? _achievementsFuture;
  bool _isViewerStudent = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _checkViewerRole();
  }

  Future<void> _checkViewerRole() async {
    final userData = await AuthApi.getStoredUser();
    if (userData != null && mounted) {
      final role = userData['role'];
      String roleName = '';
      if (role is String) {
        roleName = role;
      } else if (role is Map) {
        roleName = role['role_name'] ?? '';
      }

      if (roleName.toLowerCase() == 'student') {
        setState(() {
          _isViewerStudent = true;
        });
      }
    }
  }

  // Helper to get role color
  Color _getRoleColor(String role, ColorScheme scheme) {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'teacher':
        return scheme.tertiary;
      case 'student':
        return scheme.primary;
      default:
        return scheme.secondary;
    }
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _userFuture = _userApi.getUserDetails(widget.userId);
    });

    // Only fetch achievements if the user is a student
    _userFuture
        .then((user) {
          if (mounted && user.isStudent) {
            _fetchAchievements();
          }
        })
        .catchError((_) {
          // Errors are handled by the FutureBuilder in the UI
        });
  }

  Future<void> _fetchAchievements() async {
    setState(() {
      _achievementsFuture = _achievementApi.fetchUserAchievements(
        widget.userId,
      );
    });
  }

  Future<void> _editUser(UserDetails user) async {
    final bool? refreshed = await showEditUserDialog(
      context: context,
      initialData: user,
      isSelfEdit: widget.isSelfProfile,
      showSnackBar: (ctx, msg, color) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
      },
    );

    if (refreshed == true) {
      _fetchUserDetails();
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

  Future<void> _deleteUser() async {
    final bool confirmed = await _confirmDelete();
    if (!confirmed) return;

    if (!mounted) return;
    final BuildContext scaffoldContext = context;

    try {
      await _userApi.deleteUser(widget.userId);

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted user: ${widget.userName}'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final BuildContext scaffoldContext = context;
        String cleanError = e.toString().replaceAll('Exception: ', '');

        bool isDeniedError = false;
        const String deniedMessage =
            'Access Denied: Only Administrators can delete user accounts.';

        if (cleanError.contains('403:')) {
          cleanError = deniedMessage;
          isDeniedError = true;
        }

        final String snackBarText = isDeniedError
            ? cleanError
            : 'Error deleting user: $cleanError';

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(snackBarText),
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
        title: widget.breadcrumbs != null
            ? BreadcrumbNavigation(items: widget.breadcrumbs!)
            : Text(widget.userName),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          FutureBuilder<UserDetails>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  (widget.viewerRole.toLowerCase() == 'admin' ||
                      widget.isSelfProfile)) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editUser(snapshot.data!),
                  tooltip: 'Edit User Profile',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          FutureBuilder<UserDetails>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  !widget.isSelfProfile &&
                  widget.viewerRole.toLowerCase() == 'admin') {
                return IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteUser,
                  tooltip: 'Delete User Account',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
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
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No user data found."));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(context, user),

                const SizedBox(height: 32),

                _buildSectionHeader(
                  context,
                  "Personal Information",
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildDetailCard(context, [
                  _buildInfoRow(
                    context,
                    Icons.email_outlined,
                    "Email",
                    user.email,
                  ),
                  _buildDivider(context),
                  _buildInfoRow(
                    context,
                    Icons.phone_outlined,
                    "Phone",
                    user.phoneNo,
                  ),
                  _buildDivider(context),
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    "Address",
                    user.address,
                  ),
                  _buildDivider(context),
                  _buildInfoRow(
                    context,
                    Icons.transgender,
                    "Gender",
                    user.gender,
                  ),
                ]),

                if (user.isStudent) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    "Recent Achievements",
                    Icons.emoji_events_outlined,
                    trailing: TextButton(
                      onPressed: () async {
                        final user = await _userFuture;
                        if (mounted) {
                          if (_isViewerStudent) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StudentProfileAchievementsPage(
                                      userId: widget.userId,
                                      userName: user.name,
                                    ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminStudentAchievementsPage(
                                      userId: widget.userId,
                                      userName: user.name,
                                    ),
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text("View All"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentAchievements(context),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserDetails user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleColor = _getRoleColor(user.roleName, colorScheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: roleColor,
              foregroundColor: colorScheme.onPrimary,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: textTheme.displayMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Role, Status, and Joined Date metadata row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.roleName.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: roleColor,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: user.accountStatus == 'active'
                      ? Colors.green.withOpacity(0.1)
                      : colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: user.accountStatus == 'active'
                        ? Colors.green.withOpacity(0.3)
                        : colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.accountStatus == 'active'
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 14,
                      color: user.accountStatus == 'active'
                          ? Colors.green
                          : colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.accountStatus.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: user.accountStatus == 'active'
                            ? Colors.green
                            : colorScheme.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Joined ${user.joinedDate.split('T')[0]}",
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
    );
  }

  Widget _buildIconContainer(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIconContainer(context, icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        valueColor ?? Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements(BuildContext context) {
    return FutureBuilder<List<AchievementData>>(
      future: _achievementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100,
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Text('Error loading achievements: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  "No achievements yet",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        final achievements = snapshot.data!
            .take(10)
            .toList(); // Show more items for scrolling

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final icon = getAchievementIcon(achievement.icon);
              final color = getAchievementColor(context, achievement.icon);
              final dateStr = achievement.unlockedAt != null
                  ? achievement.unlockedAt!.toString().split(' ')[0]
                  : 'N/A';

              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      achievement.achievementTitle ?? "Achievement",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
