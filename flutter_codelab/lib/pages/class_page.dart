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
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

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

  // Filter states
  String _selectedOwnerFilter = 'all'; // 'all' or 'created_by_me'
  String? _selectedFocusFilter; // null, 'HTML', 'CSS', 'JavaScript', 'PHP'

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
    final l10n = AppLocalizations.of(context)!;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String role = widget.currentUser.roleName.trim().toLowerCase();

    // Determine title based on role
    String pageTitle;
    if (role == 'admin') {
      pageTitle = l10n.allClasses;
    } else if (role == 'teacher') {
      pageTitle = l10n.myClasses;
    } else {
      pageTitle = l10n.enrolledClasses;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2.0,
        2.0,
        16.0,
        16.0,
      ), // Outer padding (same as FeedbackPage)
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // Inner padding (same as FeedbackPage)
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
                    hintText: l10n.searchByClassName,
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

                // Filter Chips and Sort/Refresh Row
                if (role == 'admin' || role == 'teacher' || role == 'student')
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Filter Chips
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Owner filter chips (only for admin)
                            if (role == 'admin') ...[
                              FilterChip(
                                label: Text(l10n.all),
                                selected: _selectedOwnerFilter == 'all',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(
                                      () => _selectedOwnerFilter = 'all',
                                    );
                                  }
                                },
                              ),
                              FilterChip(
                                label: Text(l10n.createdByMe),
                                selected:
                                    _selectedOwnerFilter == 'created_by_me',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(
                                      () => _selectedOwnerFilter =
                                          'created_by_me',
                                    );
                                  }
                                },
                              ),
                              // Separator (only if there are owner filters)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '|',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                            // Focus filter chips (for admin, teacher, and student)
                            FilterChip(
                              label: const Text('HTML'),
                              selected: _selectedFocusFilter == 'HTML',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFocusFilter = selected
                                      ? 'HTML'
                                      : null;
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('CSS'),
                              selected: _selectedFocusFilter == 'CSS',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFocusFilter = selected
                                      ? 'CSS'
                                      : null;
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('JavaScript'),
                              selected: _selectedFocusFilter == 'JavaScript',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFocusFilter = selected
                                      ? 'JavaScript'
                                      : null;
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('PHP'),
                              selected: _selectedFocusFilter == 'PHP',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFocusFilter = selected
                                      ? 'PHP'
                                      : null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter Icon (Sort)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        tooltip: l10n.sortOptions,
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
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  l10n.sortBy,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Name',
                                checked: _sortType == SortType.alphabetical,
                                child: Text(l10n.name),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Date',
                                checked: _sortType == SortType.updated,
                                child: Text(l10n.date),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  l10n.order,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Ascending',
                                checked: _sortOrder == SortOrder.ascending,
                                child: Text(l10n.ascending),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Descending',
                                checked: _sortOrder == SortOrder.descending,
                                child: Text(l10n.descending),
                              ),
                            ],
                      ),
                      const SizedBox(width: 4),
                      // Refresh Icon
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: reloadClassList,
                        tooltip: l10n.refreshList,
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
        ownerFilter: _selectedOwnerFilter,
        focusFilter: _selectedFocusFilter,
        currentUserId: widget.currentUser.id,
      );
    }
    return student.ClassListSection(
      key: ValueKey('student_class_list_$_reloadKey'),
      roleName: 'student',
      searchQuery: _searchQuery,
      layout: _viewLayout,
      sortType: _sortType,
      sortOrder: _sortOrder,
      focusFilter: _selectedFocusFilter, // Add focus filter support
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
