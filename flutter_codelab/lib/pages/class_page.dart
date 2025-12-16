import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/admin_class_list_section.dart'
    as admin;
import 'package:flutter_codelab/admin_teacher/widgets/class/admin_class_list_statistic.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_class_list_section.dart'
    as teacher;
import 'package:flutter_codelab/student/widgets/class/student_class_list_section.dart'
    as student;
// import '../widgets/search_bar.dart';
import 'package:flutter_codelab/models/user_data.dart';

// Global key to access ClassPage state for reloading from main.dart
final GlobalKey<_ClassPageState> classPageGlobalKey =
    GlobalKey<_ClassPageState>();

class ClassPage extends StatefulWidget {
  final UserDetails currentUser;

  const ClassPage({super.key, required this.currentUser});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  int _reloadKey = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void reloadClassList() {
    // Force rebuild by changing the key
    setState(() {
      _reloadKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String role = widget.currentUser.roleName.trim().toLowerCase();

    // Determine title based on role
    String pageTitle;
    if (role == 'admin') {
      pageTitle = "All classes";
    } else if (role == 'teacher') {
      pageTitle = "My Classes";
    } else {
      pageTitle = "Enrolled Classes";
    }

    return Padding(
      padding: const EdgeInsets.all(
        16.0,
      ), // Outer padding (same as AchievementPage)
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // Inner padding (same as AchievementPage)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (same style as AchievementPage)
                Text(
                  pageTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: colors.onSurface),
                ),

                const SizedBox(height: 16),

                // Search Bar (shown for all roles)
                SizedBox(
                  width: 300,
                  child: SearchBar(
                    controller: _searchController,
                    hintText: "Search by class name",
                    trailing: <Widget>[
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _reloadKey++;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _searchQuery = _searchController.text.trim();
                            _reloadKey++;
                          });
                        },
                      ),
                    ],
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                        _reloadKey++;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics section (only for admin)
                if (role == 'admin') ...[
                  ClassStatisticsSection(key: ValueKey('stats_$_reloadKey')),
                  const SizedBox(height: 16),
                ],

                // Class list (fills remaining space) - role-based
                Expanded(child: _buildRoleBasedClassList(role)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBasedClassList(String role) {
    if (role == 'admin') {
      return admin.ClassListSection(
        key: ValueKey('admin_class_list_$_reloadKey'),
        roleName: 'admin',
        onReload: reloadClassList,
        searchQuery: _searchQuery,
      );
    }
    if (role == 'teacher') {
      return teacher.ClassListSection(
        key: ValueKey('teacher_class_list_$_reloadKey'),
        roleName: 'teacher',
        searchQuery: _searchQuery,
      );
    }
    return student.ClassListSection(
      key: ValueKey('student_class_list_$_reloadKey'),
      roleName: 'student',
      searchQuery: _searchQuery,
    );
  }
}
