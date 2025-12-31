import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:intl/intl.dart';

class StudentAchievementPeersPage extends StatefulWidget {
  final String achievementId;
  final String achievementName;

  const StudentAchievementPeersPage({
    super.key,
    required this.achievementId,
    required this.achievementName,
  });

  @override
  State<StudentAchievementPeersPage> createState() =>
      _StudentAchievementPeersPageState();
}

class _StudentAchievementPeersPageState
    extends State<StudentAchievementPeersPage> {
  final AchievementApi _api = AchievementApi();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final students = await _api.fetchAchievementStudents(
        widget.achievementId,
      );
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().add_jm().format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Unlocked By"), // Simple title, no breadcrumbs
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStudents();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            ElevatedButton(
              onPressed: _fetchStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(
        child: Text('No other students have unlocked this achievement yet.'),
      );
    }

    // Group students by Class Name
    final Map<String, List<Map<String, dynamic>>> groupedStudents = {};

    for (var student in _students) {
      final className = student['class_name'] as String? ?? 'Other / No Class';
      if (!groupedStudents.containsKey(className)) {
        groupedStudents[className] = [];
      }
      groupedStudents[className]!.add(student);
    }

    final sortedKeys = groupedStudents.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final className = sortedKeys[sectionIndex];
        final studentsInClass = groupedStudents[className]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Text(
                className,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            // List of Students in this Class
            ...studentsInClass.map((student) {
              final name = student['name'] ?? 'Unknown';
              final unlockedAt = student['unlocked_at'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 1.0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // Removed Subtitle (Email) for privacy in student view if desired,
                  // or keep it. I'll remove email for strict privacy.
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Unlocked',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(unlockedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: null, // Read Only!
                ),
              );
            }),
            const SizedBox(height: 12.0),
          ],
        );
      },
    );
  }
}

