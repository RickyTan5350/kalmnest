import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_class_list_section.dart'
    as teacher;
import 'package:flutter_codelab/student/widgets/class/student_class_list_section.dart'
    as student;
// import '../widgets/search_bar.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/services/layout_preferences.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';

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
  ViewLayout _viewLayout = ViewLayout.grid;
  SortType _sortType = SortType.alphabetical;
  SortOrder _sortOrder = SortOrder.ascending;

  @override
  void initState() {
    super.initState();
    _loadLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    final savedLayout = await LayoutPreferences.getLayout('global_layout');
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
                    _ViewToggleButton(
                      currentLayout: _viewLayout,
                      onLayoutChanged: (ViewLayout newLayout) {
                        setState(() => _viewLayout = newLayout);
                        LayoutPreferences.saveLayout(
                          'global_layout',
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

                // Filter and Sort Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Filter Icon (Sort)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Sort Options',
                      onSelected: (value) {
                        setState(() {
                          if (value == 'Name') {
                            _sortType = SortType.alphabetical;
                          } else if (value == 'Date') {
                            _sortType = SortType.updated;
                          } else if (value == 'Ascending') {
                            _sortOrder = SortOrder.ascending;
                          } else if (value == 'Descending') {
                            _sortOrder = SortOrder.descending;
                          }
                        });
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              enabled: false,
                              child: Text(
                                'Sort By',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            CheckedPopupMenuItem<String>(
                              value: 'Name',
                              checked: _sortType == SortType.alphabetical,
                              child: const Text('Name'),
                            ),
                            CheckedPopupMenuItem<String>(
                              value: 'Date',
                              checked: _sortType == SortType.updated,
                              child: const Text('Date'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              enabled: false,
                              child: Text(
                                'Order',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            CheckedPopupMenuItem<String>(
                              value: 'Ascending',
                              checked: _sortOrder == SortOrder.ascending,
                              child: const Text('Ascending'),
                            ),
                            CheckedPopupMenuItem<String>(
                              value: 'Descending',
                              checked: _sortOrder == SortOrder.descending,
                              child: const Text('Descending'),
                            ),
                          ],
                    ),
                    const SizedBox(width: 4),
                    // Refresh Icon
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: reloadClassList,
                      tooltip: "Refresh List",
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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
    if (role == 'admin' || role == 'teacher') {
      return teacher.ClassListSection(
        key: ValueKey('${role}_class_list_$_reloadKey'),
        roleName: role,
        onReload: role == 'admin' ? reloadClassList : null,
        searchQuery: _searchQuery,
        layout: _viewLayout,
        sortType: _sortType,
        sortOrder: _sortOrder,
      );
    }
    return student.ClassListSection(
      key: ValueKey('student_class_list_$_reloadKey'),
      roleName: 'student',
      searchQuery: _searchQuery,
      layout: _viewLayout,
      sortType: _sortType,
      sortOrder: _sortOrder,
    );
  }
}

// Custom view toggle button with tooltips
class _ViewToggleButton extends StatelessWidget {
  final ViewLayout currentLayout;
  final Function(ViewLayout) onLayoutChanged;

  const _ViewToggleButton({
    required this.currentLayout,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ViewLayout>(
      segments: <ButtonSegment<ViewLayout>>[
        ButtonSegment<ViewLayout>(
          value: ViewLayout.list,
          icon: Tooltip(message: 'List view', child: Icon(Icons.menu)),
        ),
        ButtonSegment<ViewLayout>(
          value: ViewLayout.grid,
          icon: Tooltip(message: 'Grid view', child: Icon(Icons.grid_view)),
        ),
      ],
      selected: <ViewLayout>{currentLayout},
      onSelectionChanged: (Set<ViewLayout> newSelection) {
        onLayoutChanged(newSelection.first);
      },
    );
  }
}
