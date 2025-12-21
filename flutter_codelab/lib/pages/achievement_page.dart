import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/admin_teacher/widgets/achievements/admin_view_achievement_page.dart';
import 'package:flutter_codelab/student/widgets/achievements/student_view_achievement_page.dart';
import 'package:flutter_codelab/constants/view_layout.dart' show ViewLayout;
import 'package:flutter_codelab/enums/sort_enums.dart'; // Shared Enums
import 'package:flutter_codelab/services/layout_preferences.dart'; // Layout Persistence

class AchievementPage extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  final UserDetails currentUser;

  const AchievementPage({
    super.key,
    required this.showSnackBar,
    required this.currentUser,
  });

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  final List<String> _topics = [
    'All',
    'HTML',
    'CSS',
    'JS',
    'PHP',
    'Quiz',
    'Created by Me',
    'Unlocked',
    'Locked',
  ]; // Added 'All'
  String _selectedTopic = 'All'; // Default to 'All'
  ViewLayout _viewLayout = ViewLayout.grid;
  SortType _sortType = SortType.alphabetical;
  SortOrder _sortOrder = SortOrder.ascending;

  final GlobalKey<StudentViewAchievementsPageState> _studentKey =
      GlobalKey<StudentViewAchievementsPageState>();
  final GlobalKey<AdminViewAchievementsPageState> _adminKey =
      GlobalKey<AdminViewAchievementsPageState>();

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

  // NEW: State for Search Text
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _handleRefresh() async {
    if (widget.currentUser.isStudent) {
      _studentKey.currentState?.refreshData();
    } else {
      _adminKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    // DEBUGGING: Print the role to console to verify what the app sees
    print("CURRENT USER ROLE: ${widget.currentUser.roleName}");
    print("IS STUDENT? ${widget.currentUser.isStudent}");

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Achievements",
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
                          'global_layout',
                          newLayout,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- SEARCH & CHIPS ---
                SizedBox(
                  width: 300,
                  child: SearchBar(
                    controller: _searchController,
                    hintText: "Search titles or descriptions...",
                    // NEW: Update state on submit or change
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.toLowerCase();
                      });
                    },
                    onSubmitted: (value) {
                      setState(() {
                        _searchText = value.toLowerCase();
                      });
                    },
                    trailing: <Widget>[
                      if (_searchText.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchText = '';
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          /* Search logic is in onChange/onSubmitted */
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: _topics
                            .where((topic) {
                              if (widget.currentUser.isStudent) {
                                // Student: Hide 'Created by Me'
                                if (topic == 'Created by Me') return false;
                              } else {
                                // Teacher/Admin: Hide 'Unlocked', 'Locked'
                                if (topic == 'Unlocked' || topic == 'Locked') {
                                  return false;
                                }
                              }
                              return true;
                            })
                            .map((topic) {
                              final isSelected = _selectedTopic == topic;
                              return FilterChip(
                                label: Text(
                                  topic,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurface,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedTopic = selected ? topic : 'All';
                                  });
                                },
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          } else if (value == 'Unlocked') {
                            _sortType = SortType.unlocked;
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
                            // NEW: Unlocked sort (Visible only for students)
                            if (widget.currentUser.isStudent)
                              CheckedPopupMenuItem<String>(
                                value: 'Unlocked',
                                checked: _sortType == SortType.unlocked,
                                child: const Text('Unlocked'),
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
                      onPressed: _handleRefresh,
                      tooltip: "Refresh List",
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- THE CRITICAL SWITCH (Passing the filters) ---
                Expanded(
                  child: widget.currentUser.isStudent
                      ? StudentViewAchievementsPage(
                          // Load Student View
                          layout: _viewLayout,
                          showSnackBar: widget.showSnackBar,
                          userId: widget.currentUser.id,
                          // NEW: Pass Filter Criteria
                          searchText: _searchText,
                          selectedTopic: _selectedTopic == 'All'
                              ? null
                              : ([
                                      'Created by Me',
                                      'Unlocked',
                                      'Locked',
                                    ].contains(_selectedTopic)
                                    ? _selectedTopic
                                    : _selectedTopic.toLowerCase()),
                          key: _studentKey,
                          sortType: _sortType,
                          sortOrder: _sortOrder,
                        )
                      : AdminViewAchievementsPage(
                          // Load Admin View
                          layout: _viewLayout,
                          showSnackBar: widget.showSnackBar,
                          userId: widget.currentUser.id,
                          // NEW: Pass Filter Criteria
                          searchText: _searchText,
                          selectedTopic: _selectedTopic == 'All'
                              ? null
                              : ([
                                      'Created by Me',
                                      'Unlocked',
                                      'Locked',
                                    ].contains(_selectedTopic)
                                    ? _selectedTopic
                                    : _selectedTopic.toLowerCase()),
                          key: _adminKey,
                          sortType: _sortType,
                          sortOrder: _sortOrder,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
