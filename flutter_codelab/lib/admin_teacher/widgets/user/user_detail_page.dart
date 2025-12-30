import 'package:flutter/material.dart';
import 'package:code_play/api/user_api.dart';
import 'package:code_play/models/user_data.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'edit_user_dialog.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/constants/achievement_constants.dart';
import 'admin_student_achievements_page.dart';
import 'package:code_play/api/auth_api.dart';
import 'package:code_play/student/widgets/achievements/student_profile_achievements_page.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

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

  // Helper to get role color (matching premium style)
  Color _getRoleColor(String role, ColorScheme scheme) {
    switch (role.trim().toLowerCase()) {
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

  // Localization Helpers
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

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'active':
        return l10n.active;
      case 'inactive':
        return l10n.inactive;
      default:
        return status;
    }
  }

  String _getLocalizedGender(String gender) {
    final l10n = AppLocalizations.of(context)!;
    switch (gender.toLowerCase()) {
      case 'male':
        return l10n.male;
      case 'female':
        return l10n.female;
      case 'other':
        return l10n.other;
      default:
        return gender;
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
        title: Text(AppLocalizations.of(context)!.deleteUserAccount),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteUserAccountConfirmation(widget.userName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: Text(AppLocalizations.of(context)!.delete),
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
          content: Text(
            AppLocalizations.of(context)!.deletedUserSuccess(widget.userName),
          ),
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
            ? AppLocalizations.of(context)!.accessDeniedAdminOnly
            : AppLocalizations.of(context)!.errorDeletingUser(cleanError);

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
                  tooltip: AppLocalizations.of(context)!.editUserProfile,
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
                  tooltip: AppLocalizations.of(context)!.deleteUserAccount,
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
                  Text(
                    AppLocalizations.of(context)!.errorLoadingProfile,
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noUsersFound),
            );
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
                  AppLocalizations.of(context)!.userProfileDetails,
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildDetailCard(context, [
                  _buildInfoRow(
                    context,
                    Icons.email_outlined,
                    AppLocalizations.of(context)!.email,
                    user.email,
                  ),
                  _buildDivider(context),
                  _buildInfoRow(
                    context,
                    Icons.phone_outlined,
                    AppLocalizations.of(context)!.phone,
                    user.phoneNo,
                  ),
                  _buildDivider(context),
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    AppLocalizations.of(context)!.address,
                    user.address,
                  ),
                  _buildDivider(context),
                  _buildInfoRow(
                    context,
                    Icons.transgender,
                    AppLocalizations.of(context)!.genderLabel,
                    _getLocalizedGender(user.gender),
                  ),
                ]),

                if (user.isStudent) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.recentAchievements,
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
                      child: Text(AppLocalizations.of(context)!.viewAll),
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
              backgroundColor: roleColor.withOpacity(0.2),
              foregroundColor: roleColor,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: textTheme.displayMedium?.copyWith(
                  color: roleColor,
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
                  _getLocalizedRole(user.roleName).toUpperCase(),
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
                      _getLocalizedStatus(user.accountStatus).toUpperCase(),
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
                      "${AppLocalizations.of(context)!.joinedDateLabel} ${user.joinedDate.split('T')[0]}",
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
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
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
                  AppLocalizations.of(context)!.noAchievementsYet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        final achievements = snapshot.data!.take(10).toList();

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
                  : AppLocalizations.of(context)!.unknownDate;

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
                      achievement.achievementTitle ??
                          AppLocalizations.of(context)!.achievement,
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

