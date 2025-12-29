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
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/services/layout_preferences.dart';

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
  ViewLayout _viewLayout = LayoutPreferences.getLayoutSync(
    LayoutPreferences.globalLayoutKey,
  );

  @override
  void initState() {
    super.initState();
    _loadLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    final savedLayout = await LayoutPreferences.getLayout(
      LayoutPreferences.globalLayoutKey,
    );
    if (mounted) {
      setState(() {
        _viewLayout = savedLayout;
      });
    }
  }

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
                // Header with title and view toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pageTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onSurface),
                    ),
                    SegmentedButton<ViewLayout>(
                      segments: const <ButtonSegment<ViewLayout>>[
                        ButtonSegment<ViewLayout>(
                          value: ViewLayout.list,
                          icon: Icon(Icons.menu),
                        ),
                        ButtonSegment<ViewLayout>(
                          value: ViewLayout.grid,
                          icon: Icon(Icons.grid_view),
                        ),
                      ],
                      selected: <ViewLayout>{_viewLayout},
                      onSelectionChanged: (Set<ViewLayout> newSelection) {
                        final newLayout = newSelection.first;
                        setState(() => _viewLayout = newLayout);
                        LayoutPreferences.saveLayout(
                          LayoutPreferences.globalLayoutKey,
                          newLayout,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search Bar (real-time search)
                SizedBox(
                  width: 300,
                  child: SearchBar(
                    controller: _searchController,
                    hintText: "Search by class name",
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
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
        layout: _viewLayout,
      );
    }
    if (role == 'teacher') {
      return teacher.ClassListSection(
        key: ValueKey('teacher_class_list_$_reloadKey'),
        roleName: 'teacher',
        searchQuery: _searchQuery,
        layout: _viewLayout,
      );
    }
    return student.ClassListSection(
      key: ValueKey('student_class_list_$_reloadKey'),
      roleName: 'student',
      searchQuery: _searchQuery,
      layout: _viewLayout,
    );
  }
}
