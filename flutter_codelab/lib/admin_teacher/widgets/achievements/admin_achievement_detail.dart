// lib/pages/achievement_detail_page.dart
import 'package:flutter/material.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/admin_teacher/widgets/achievements/admin_achievement_students_page.dart';
import 'package:code_play/constants/achievement_constants.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/widgets/mouse_follow_tooltip.dart'; // NEW
import 'admin_edit_achievement_page.dart';

class AdminAchievementDetailPage extends StatefulWidget {
  final AchievementData initialData; // The partial data from the grid
  final double progress;
  final String? currentUserId; // NEW
  final bool isAdmin; // NEW
  final String?
  studentName; // NEW: For viewing a specific student's unlock details
  final String? studentId; // NEW: To identify the student context
  final List<BreadcrumbItem>? breadcrumbs;

  const AdminAchievementDetailPage({
    super.key,
    required this.initialData,
    this.progress = 0.0,
    this.currentUserId,
    this.isAdmin = false,
    this.studentName,
    this.studentId,
    this.breadcrumbs,
  });

  @override
  State<AdminAchievementDetailPage> createState() =>
      _AdminAchievementDetailPageState();
}

class _AdminAchievementDetailPageState
    extends State<AdminAchievementDetailPage> {
  late AchievementData _displayData; // The data currently being shown
  bool _isLoading = true;
  final AchievementApi _api = AchievementApi();

  @override
  void initState() {
    super.initState();
    // 1. Show the partial data immediately so the user sees something
    _displayData = widget.initialData;

    // 2. Fetch the full data using the ID
    if (widget.initialData.achievementId != null) {
      _fetchFullDetails(widget.initialData.achievementId!);
    }
  }

  Future<void> _fetchFullDetails(String id) async {
    try {
      final fullData = await _api.getAchievementById(id);

      if (mounted) {
        setState(() {
          _displayData = fullData; // Update with the new, full data
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load full details: $e')),
        );
        setState(() {
          _isLoading = false; // Stop loading spinner even on error
        });
      }
    }
  }

  Future<void> _deleteAchievement() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Achievement?'),
        content: Text(
          'Are you sure you want to delete "${_displayData.achievementTitle}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(Colors.red),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _api.deleteAchievements({_displayData.achievementId!});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Achievement deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate change
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting achievement: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ... Keep your helper methods (_getIconData, _getColor, _formatDate) here ...
  IconData _getIconData(String? iconValue) {
    try {
      final entry = achievementIconOptions.firstWhere(
        (opt) => opt['value'] == iconValue,
        orElse: () => {'icon': Icons.help_outline},
      );
      return entry['icon'] as IconData;
    } catch (e) {
      return Icons.help_outline;
    }
  }

  Color _getColor(String? iconValue) {
    switch (iconValue) {
      case 'html':
        return Colors.orange;
      case 'css':
        return Colors.green;
      case 'javascript':
        return Colors.yellow;
      case 'php':
        return Colors.blue;
      case 'backend':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = _getIconData(_displayData.icon);
    final Color color = _getColor(_displayData.icon);

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items:
              widget.breadcrumbs ??
              [
                BreadcrumbItem(
                  label: 'Achievements',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const BreadcrumbItem(label: 'Details'),
              ],
        ),
        backgroundColor: color.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_displayData.achievementId != null) {
                setState(() => _isLoading = true);
                _fetchFullDetails(_displayData.achievementId!);
              }
            },
            tooltip: 'Refresh',
          ),
          // ACCESS CONTROL: Only Admin or Creator can Edit/Delete
          if (widget.isAdmin ||
              (widget.currentUserId != null &&
                  _displayData.creatorId != null &&
                  widget.currentUserId.toString() ==
                      _displayData.creatorId.toString())) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Achievement',
              onPressed: () async {
                final Map<String, dynamic> achievementMap = {
                  'achievement_id': _displayData.achievementId,
                  'achievement_name': _displayData.achievementName,
                  'title': _displayData.achievementTitle,
                  'description': _displayData.achievementDescription,
                  'associated_level': _displayData.levelId,
                  'icon': _displayData.icon,
                };

                await showEditAchievementDialog(
                  context: context,
                  achievement: achievementMap,
                  showSnackBar: (ctx, msg, color) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: color),
                    );
                  },
                );

                if (_displayData.achievementId != null && mounted) {
                  _fetchFullDetails(_displayData.achievementId!);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                if (_displayData.achievementId != null) {
                  _deleteAchievement();
                }
              },
              tooltip: 'Delete Achievement',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_displayData.achievementId != null) {
            await _fetchFullDetails(_displayData.achievementId!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, color: color, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayData.achievementTitle ?? 'No Title',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_displayData.levelName ?? 'No Level'),
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Progress (Clickable)
              MouseFollowTooltip(
                message: 'View details',
                child: Card(
                  elevation: 2,
                  shadowColor: color.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (_displayData.achievementId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminAchievementStudentsPage(
                              achievementId: _displayData.achievementId!,
                              achievementName:
                                  _displayData.achievementTitle ??
                                  'Achievement',
                              excludedStudentId: widget.studentId,
                              breadcrumbs: widget.breadcrumbs != null
                                  ? [
                                      ...BreadcrumbItem.wrap(
                                        widget.breadcrumbs!,
                                        context,
                                      ),
                                      const BreadcrumbItem(label: 'Students'),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    hoverColor: color.withOpacity(0.1),
                    splashColor: color.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Students Unlocked',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      (_displayData.unlockedCount != null &&
                                              _displayData.totalStudents !=
                                                  null)
                                          ? '${_displayData.unlockedCount} / ${_displayData.totalStudents}'
                                          : '${(widget.progress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Progress Bar
                                if (_isLoading)
                                  const LinearProgressIndicator()
                                else
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0.0,
                                      end:
                                          (_displayData.unlockedCount != null &&
                                              _displayData.totalStudents !=
                                                  null &&
                                              _displayData.totalStudents! > 0)
                                          ? (_displayData.unlockedCount! /
                                                _displayData.totalStudents!)
                                          : widget.progress,
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1500,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, _) =>
                                        LinearProgressIndicator(
                                          value: value,
                                          minHeight: 10,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                color,
                                              ),
                                          backgroundColor: color.withOpacity(
                                            0.1,
                                          ),
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Info Fields
              _buildSectionTitle(context, 'General Info'),
              _buildInfoRow(context, 'Name', _displayData.achievementName),
              _buildInfoRow(
                context,
                'Creator',
                _displayData.creatorName ?? 'Loading...',
              ),

              const Divider(height: 30),

              _buildSectionTitle(context, 'Description'),
              Text(
                _displayData.achievementDescription ?? 'Loading description...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const Divider(height: 30),

              _buildSectionTitle(context, 'Timestamps'),
              _buildInfoRow(
                context,
                'Created At',
                _formatDate(_displayData.createdAt),
              ),
              _buildInfoRow(
                context,
                'Last Updated',
                _formatDate(_displayData.updatedAt),
              ),

              if (widget.studentName != null &&
                  _displayData.unlockedAt != null) ...[
                const Divider(height: 30),
                _buildSectionTitle(context, 'Student Progress'),
                _buildInfoRow(
                  context,
                  'Unlocked by ${widget.studentName}',
                  _formatDate(_displayData.unlockedAt),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
