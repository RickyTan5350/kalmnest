import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/play_game_page.dart';
import 'package:code_play/models/level.dart';
import 'package:code_play/api/game_api.dart';
import 'package:code_play/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:code_play/admin_teacher/widgets/game/gamePages/edit_game_page.dart';
import 'package:code_play/admin_teacher/widgets/game/gamePages/teacher_quiz_view.dart'; // Import TeacherQuizView
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/constants/view_layout.dart' show ViewLayout;
import 'package:code_play/enums/sort_enums.dart'; // Shared Enums
import 'package:code_play/services/layout_preferences.dart'; // Layout Persistence
import 'package:code_play/constants/achievement_constants.dart';
import 'package:flutter_codelab/models/achievement_data.dart';

// Global key to access GamePage state for refreshing from main.dart
final GlobalKey<_GamePageState> gamePageGlobalKey = GlobalKey<_GamePageState>();

class GamePage extends StatefulWidget {
  final String userRole; // Current user role

  const GamePage({super.key, required this.userRole});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final List<String> _topics = ['All', 'HTML', 'CSS', 'JS', 'PHP', 'Quiz'];
  String _selectedTopic = 'All';

  // Visibility filter (only for teachers/admins)
  final List<String> _visibilityFilters = ['All', 'Public', 'Private'];
  String _selectedVisibility = 'All';

  ViewLayout _viewLayout = ViewLayout.grid;
  SortType _sortType = SortType.alphabetical;
  SortOrder _sortOrder = SortOrder.ascending;

  final TextEditingController _searchController = TextEditingController();

  List<LevelModel> _levels = [];
  List<LevelModel> _filteredLevels = [];
  Set<String> _completedLevelIds = {};
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLayoutPreference();
    fetchLevels(forceRefresh: true);
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

  @override
  void didUpdateWidget(GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh if user role changed
    if (oldWidget.userRole != widget.userRole) {
      fetchLevels(forceRefresh: true);
    }
  }

  // Public method to refresh from outside
  void refresh() {
    fetchLevels(topic: _selectedTopic, forceRefresh: true);
  }

  Future<void> fetchLevels({String? topic, bool forceRefresh = false}) async {
    setState(() => _loading = true);

    // Fetch levels and completed achievements in parallel
    final bool isStudent = widget.userRole.trim().toLowerCase() == 'student';
    final results = await Future.wait([
      GameAPI.fetchLevels(topic: topic, forceRefresh: forceRefresh),
      isStudent
          ? AchievementApi().fetchMyUnlockedAchievements()
          : Future.value(<AchievementData>[]),
    ]);

    final levels = results[0] as List<LevelModel>;
    final achievements = results[1] as List<dynamic>;

    if (!mounted) return;

    setState(() {
      _levels = levels;
      _completedLevelIds = achievements
          .where((a) => a.unlockedAt != null)
          .map((a) => a.levelId?.toString())
          .whereType<String>()
          .toSet();
      _filteredLevels = _applyFilters(levels);
      _loading = false;
    });
  }

  List<LevelModel> _applyFilters(List<LevelModel> levels) {
    var filtered = List<LevelModel>.from(levels);

    // Apply visibility filter (only for teachers/admins)
    final bool isStudent = widget.userRole.trim().toLowerCase() == 'student';
    if (!isStudent && _selectedVisibility != 'All') {
      if (_selectedVisibility == 'Public') {
        filtered = filtered
            .where((level) => !(level.isPrivate ?? false))
            .toList();
      } else if (_selectedVisibility == 'Private') {
        filtered = filtered.where((level) => level.isPrivate == true).toList();
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (level) => (level.levelName ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    // Apply Sorting
    filtered.sort((a, b) {
      int result = 0;
      if (_sortType == SortType.alphabetical) {
        result = (a.levelName ?? '').compareTo(b.levelName ?? '');
      } else if (_sortType == SortType.updated) {
        // Fallback to ID sorting as proxy for date if date is not in model
        result = (a.levelId ?? '').compareTo(b.levelId ?? '');
      }
      return _sortOrder == SortOrder.ascending ? result : -result;
    });

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredLevels = _applyFilters(_levels);
    });
  }

  Future<void> deleteLevel(String levelId) async {
    final response = await GameAPI.deleteLevel(levelId);
    if (response.success) {
      fetchLevels(topic: _selectedTopic, forceRefresh: true);
      showSnackBar(context, response.message, Colors.green);
    } else {
      showSnackBar(context, response.message, Colors.red);
    }
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _onAddLevelPressed() {
    showCreateGamePage(
      context: context,
      showSnackBar: showSnackBar,
      userRole: widget.userRole,
      onLevelCreated: (levelId) {
        // Refresh after game creation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            fetchLevels(topic: _selectedTopic, forceRefresh: true);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isStudent = widget.userRole.trim().toLowerCase() == 'student';

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Game Levels",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onSurface),
                    ),
                    Row(
                      children: [
                        if (!isStudent)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              onPressed: _onAddLevelPressed,
                              child: const Text('Add Level'),
                            ),
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
                  ],
                ),
                const SizedBox(height: 16),

                // SEARCH BAR
                SizedBox(
                  width: 300,
                  child: SearchBar(
                    controller: _searchController,
                    hintText: "Search levels...",
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchChanged,
                    trailing: <Widget>[
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // TOPIC FILTER CHIPS & SORT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: _topics.map((topic) {
                          final bool selected = _selectedTopic == topic;
                          return FilterChip(
                            label: Text(
                              topic,
                              style: TextStyle(color: colors.onSurface),
                            ),
                            selected: selected,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() => _selectedTopic = topic);
                                fetchLevels(topic: topic, forceRefresh: true);
                              }
                            },
                          );
                        }).toList(),
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
                          } else if (value == 'Ascending') {
                            _sortOrder = SortOrder.ascending;
                          } else if (value == 'Descending') {
                            _sortOrder = SortOrder.descending;
                          }
                          _filteredLevels = _applyFilters(_levels);
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
                      tooltip: 'Refresh Levels',
                      onPressed: () {
                        fetchLevels(topic: _selectedTopic, forceRefresh: true);
                      },
                    ),
                  ],
                ),

                // VISIBILITY FILTER (Only for teachers/admins)
                if (!isStudent) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Visibility: ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _visibilityFilters.map((visibility) {
                          final bool selected =
                              _selectedVisibility == visibility;
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (visibility == 'Private')
                                  const Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: Colors.orange,
                                  )
                                else if (visibility == 'Public')
                                  const Icon(
                                    Icons.public,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                const SizedBox(width: 4),
                                Text(visibility),
                              ],
                            ),
                            selected: selected,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() {
                                  _selectedVisibility = visibility;
                                  _filteredLevels = _applyFilters(_levels);
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // LEVEL LIST/GRID
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredLevels.isEmpty
                      ? const Center(child: Text('No levels found'))
                      : _viewLayout == ViewLayout.list
                      ? _buildLevelList()
                      : _buildLevelGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelList() {
    return ListView.builder(
      itemCount: _filteredLevels.length,
      itemBuilder: (context, index) {
        final level = _filteredLevels[index];
        return _buildLevelTile(level);
      },
    );
  }

  Widget _buildLevelTile(LevelModel level) {
    final bool isStudent = widget.userRole.trim().toLowerCase() == 'student';
    final isCompleted = _completedLevelIds.contains(level.levelId);
    final levelTypeName = level.levelTypeName ?? 'Unknown';
    final iconValue = levelTypeName.toLowerCase();
    final icon = getAchievementIcon(iconValue);
    final color = getAchievementColor(context, iconValue);

    return ListTile(
      tileColor: isCompleted ? Colors.green.withOpacity(0.1) : null,
      title: Row(
        children: [
          Expanded(
            child: Text(
              level.levelName ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          _buildVisibilityBadge(level),
        ],
      ),
      subtitle: Text(levelTypeName),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        child: Icon(icon),
      ),
      trailing: isStudent
          ? null
          : (widget.userRole.toLowerCase() == 'teacher' &&
                level.levelTypeName != 'Quiz')
          ? null
          : _buildAdminActions(level, iconSize: 20),
      onTap:
          (isStudent ||
              widget.userRole.toLowerCase() == 'admin' ||
              (widget.userRole.toLowerCase() == 'teacher' &&
                  level.levelTypeName == 'Quiz'))
          ? () => _onLevelTap(level)
          : null,
    );
  }

  Widget _buildLevelGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250.0,
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 0.9,
      ),
      itemCount: _filteredLevels.length,
      itemBuilder: (context, index) {
        final level = _filteredLevels[index];
        return _buildGameCard(level);
      },
    );
  }

  Widget _buildGameCard(LevelModel level) {
    final bool isStudent = widget.userRole.trim().toLowerCase() == 'student';
    final isCompleted = _completedLevelIds.contains(level.levelId);
    final levelTypeName = level.levelTypeName ?? 'Unknown';
    final iconValue = levelTypeName.toLowerCase();
    final icon = getAchievementIcon(iconValue);
    final color = getAchievementColor(context, iconValue);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap:
            (isStudent ||
                widget.userRole.toLowerCase() == 'admin' ||
                (widget.userRole.toLowerCase() == 'teacher' &&
                    level.levelTypeName == 'Quiz'))
            ? () => _onLevelTap(level)
            : null,
        child: Stack(
          children: [
            // Background Icon
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(icon, color: color.withOpacity(0.1)),
                ),
              ),
            ),
            // Foreground Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 8.0, 8.0),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          level.levelName ?? 'Unnamed',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      levelTypeName,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 4,
                    ),
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildVisibilityBadge(level),
                      if (!isStudent &&
                          (widget.userRole.toLowerCase() == 'admin' ||
                              level.levelTypeName == 'Quiz'))
                        _buildAdminActions(level, iconSize: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge(LevelModel level) {
    final isPrivate = level.isPrivate ?? false;
    final color = isPrivate ? Colors.orange : Colors.blue;
    final icon = isPrivate ? Icons.lock : Icons.public;
    final label = isPrivate ? 'Private' : 'Public';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildAdminActions(LevelModel level, {double iconSize = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue, size: iconSize),
          onPressed: () async {
            final currentLevel = await GameAPI.fetchLevelById(level.levelId!);
            if (currentLevel == null) {
              showSnackBar(context, "Failed to load level data", Colors.red);
              return;
            }
            await showEditGamePage(
              context: context,
              showSnackBar: showSnackBar,
              level: currentLevel,
              userRole: widget.userRole,
            );
            fetchLevels(topic: _selectedTopic, forceRefresh: true);
          },
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red, size: iconSize),
          onPressed: () => _confirmDelete(level),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _confirmDelete(LevelModel level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Level'),
        content: const Text('Are you sure you want to delete this level?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              deleteLevel(level.levelId!);
            },
          ),
        ],
      ),
    );
  }

  void _onLevelTap(LevelModel level) async {
    // If Teacher AND Level is Quiz -> Show Results View Dialog
    final bool isTeacher = widget.userRole.trim().toLowerCase() == 'teacher';
    if (isTeacher && level.levelTypeName == 'Quiz') {
      showTeacherQuizResults(context: context, level: level);
      return;
    }

    final currentLevel = await GameAPI.fetchLevelById(level.levelId!);
    if (currentLevel == null) {
      showSnackBar(context, "Failed to load level data", Colors.red);
      return;
    }
    if (!context.mounted) return;
    showPlayGamePage(
      context: context,
      showSnackBar: showSnackBar,
      level: currentLevel,
      userRole: widget.userRole,
    );
  }
}
