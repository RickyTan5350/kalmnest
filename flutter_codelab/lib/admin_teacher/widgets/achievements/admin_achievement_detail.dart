// lib/pages/achievement_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/api/achievement_api.dart'; // Import API
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'admin_achievement_students_page.dart';
import 'admin_edit_achievement_page.dart';

class AdminAchievementDetailPage extends StatefulWidget {
  final AchievementData initialData; // The partial data from the grid
  final double progress;

  const AdminAchievementDetailPage({
    super.key,
    required this.initialData,
    this.progress = 0.0,
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
        title: const Text('Achievement Details'),
        backgroundColor: color.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),

            // In achievement_detail.dart inside the IconButton onPressed:
            onPressed: () async {
              // 1. Map ALL fields required by the new Edit Form
              final Map<String, dynamic> achievementMap = {
                'achievement_id': _displayData.achievementId,
                'achievement_name': _displayData.achievementName, // Added
                'title': _displayData.achievementTitle,
                'description': _displayData.achievementDescription,
                'associated_level': _displayData.levelId, // Added
                'icon': _displayData.icon, // Added
              };

              // 2. Call the dialog
              await showEditAchievementDialog(
                context: context,
                achievement: achievementMap,
                showSnackBar: (ctx, msg, color) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: color),
                  );
                },
              );

              // 3. Refresh
              if (_displayData.achievementId != null && mounted) {
                _fetchFullDetails(_displayData.achievementId!);
              }
            },
          ),
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
              InkWell(
                onTap: () {
                  if (_displayData.achievementId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminAchievementStudentsPage(
                          achievementId: _displayData.achievementId!,
                          achievementName:
                              _displayData.achievementTitle ?? 'Achievement',
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Students Unlocked',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            (_displayData.unlockedCount != null &&
                                    _displayData.totalStudents != null)
                                ? '${_displayData.unlockedCount} / ${_displayData.totalStudents}'
                                : '${(widget.progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      if (_isLoading)
                        const LinearProgressIndicator()
                      else
                        LinearProgressIndicator(
                          value:
                              (_displayData.unlockedCount != null &&
                                  _displayData.totalStudents != null &&
                                  _displayData.totalStudents! > 0)
                              ? (_displayData.unlockedCount! /
                                    _displayData.totalStudents!)
                              : widget.progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                    ],
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
