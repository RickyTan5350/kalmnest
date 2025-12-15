import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:intl/intl.dart';
import 'package:flutter_codelab/admin_teacher/services/breadcrumb_navigation.dart';
import '../user/user_detail_page.dart';

class AdminAchievementStudentsPage extends StatefulWidget {
  final String achievementId;
  final String achievementName;

  const AdminAchievementStudentsPage({
    super.key,
    required this.achievementId,
    required this.achievementName,
  });

  @override
  State<AdminAchievementStudentsPage> createState() =>
      _AdminAchievementStudentsPageState();
}

class _AdminAchievementStudentsPageState
    extends State<AdminAchievementStudentsPage> {
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
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: 'Achievements',
              onTap: () {
                // Pop until we are back at the main list
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            BreadcrumbItem(
              label: widget.achievementName,
              onTap: () => Navigator.of(context).pop(), // Pop back to detail
            ),
            const BreadcrumbItem(label: 'Students'),
          ],
        ),
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
        child: Text('No students have unlocked this achievement yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final name = student['name'] ?? 'Unknown';
        final email = student['email'] ?? 'No Email';
        final userId = student['user_id'];
        final unlockedAt = student['unlocked_at'];

        return Container(
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            elevation: 1.0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(email),
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
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailPage(
                        userId: userId,
                        userName: name,
                        breadcrumbs: [
                          BreadcrumbItem(
                            label: 'Achievements',
                            onTap: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                          ),
                          BreadcrumbItem(
                            label: widget.achievementName,
                            // Pop 2 times: UserDetail -> Students -> Detail
                            onTap: () {
                              Navigator.of(context).pop(); // pop UserDetail
                              Navigator.of(context).pop(); // pop Students
                            },
                          ),
                          BreadcrumbItem(
                            label: 'Students',
                            // Pop 1 time: UserDetail -> Students
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          BreadcrumbItem(label: name),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
