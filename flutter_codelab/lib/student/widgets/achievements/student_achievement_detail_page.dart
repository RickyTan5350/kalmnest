import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/api/achievement_api.dart'; // Import API to fetch full details
import 'package:flutter_codelab/constants/achievement_constants.dart';

class StudentAchievementDetailPage extends StatefulWidget {
  final AchievementData initialData;
  // Note: We assume the AchievementData passed from the Student View already
  // contains the obtained timestamp from local storage, but we'll include a
  // dedicated field for robustness, or assume the initialData carries it
  // via the createdAt/updatedAt fields, or rely on a new field in the model.
  // Based on local_achievement_storage.dart, the obtained_at is saved in the local JSON.
  // We will pass the specific obtained date string if available.
  final DateTime? obtainedAt;

  const StudentAchievementDetailPage({
    super.key,
    required this.initialData,
    this.obtainedAt,
  });

  @override
  State<StudentAchievementDetailPage> createState() => _StudentAchievementDetailPageState();
}

class _StudentAchievementDetailPageState extends State<StudentAchievementDetailPage> {
  late AchievementData _displayData;
  bool _isLoading = true;
  final AchievementApi _api = AchievementApi();

  @override
  void initState() {
    super.initState();
    // 1. Show the partial data immediately
    _displayData = widget.initialData;

    // 2. Fetch the full data using the ID (in case the initial data was brief)
    if (widget.initialData.achievementId != null) {
      _fetchFullDetails(widget.initialData.achievementId!);
    } else {
      _isLoading = false;
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
          _isLoading = false;
        });
      }
    }
  }

  // --- Helper Methods ---
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
      case 'html': return Colors.orange;
      case 'css': return Colors.green;
      case 'javascript': return Colors.yellow;
      case 'php': return Colors.blue;
      case 'backend': return Colors.deepPurple;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = _getIconData(_displayData.icon);
    final Color color = _getColor(_displayData.icon);

    // Determine the date to display: use passed-in obtainedAt first, then use createdAt as fallback
    final DateTime? displayDate = widget.obtainedAt ?? _displayData.createdAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Unlocked!'),
        backgroundColor: color.withOpacity(0.2),
        // NO edit button for the student view
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if(_displayData.achievementId != null) {
            await _fetchFullDetails(_displayData.achievementId!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header (Icon, Title, Level) ---
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
                      _displayData.achievementTitle ?? 'Achievement',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text('Level: ${_displayData.levelName ?? 'N/A'}'),
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Obtained At Timestamp ---
              _buildSectionTitle(context, 'Date Obtained'),
              _buildInfoRow(context, 'Unlocked On', _formatDate(displayDate)),

              const Divider(height: 30),

              // --- Description ---
              _buildSectionTitle(context, 'Description'),
              _isLoading
                  ? const LinearProgressIndicator()
                  : Text(
                _displayData.achievementDescription ?? 'Description not available.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const Divider(height: 30),

              // --- Creator Info ---
              _buildSectionTitle(context, 'Creator Info'),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  _buildInfoRow(context, 'Created By', _displayData.creatorName ?? 'N/A'),
                  _buildInfoRow(context, 'Topic Icon', _displayData.icon ?? 'N/A'),
                ],
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