import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/play_game_page.dart';
import 'package:flutter_codelab/models/level.dart';
import 'package:flutter_codelab/api/game_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/edit_game_page.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

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

  List<LevelModel> _levels = [];
  List<LevelModel> _filteredLevels = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchLevels(forceRefresh: true);
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
    final levels = await GameAPI.fetchLevels(
      topic: topic,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    setState(() {
      _levels = levels;
      _filteredLevels = _applyFilters(levels);
      _loading = false;
    });
  }

  List<LevelModel> _applyFilters(List<LevelModel> levels) {
    var filtered = levels;

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

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredLevels = _applyFilters(_levels);
    });
  }

  String _getLocalizedTopic(String topic) {
    final l10n = AppLocalizations.of(context)!;
    switch (topic) {
      case 'All':
        return l10n.all;
      case 'Quiz':
        return l10n.quiz;
      default:
        return topic; // HTML, CSS, JS, PHP
    }
  }

  String _getLocalizedVisibility(String visibility) {
    final l10n = AppLocalizations.of(context)!;
    switch (visibility) {
      case 'All':
        return l10n.all;
      case 'Public':
        return l10n.public;
      case 'Private':
        return l10n.private;
      default:
        return visibility;
    }
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
                  children: [
                    Text(
                      AppLocalizations.of(context)!.gameLevels,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: AppLocalizations.of(context)!.refreshLevels,
                      onPressed: () {
                        fetchLevels(topic: _selectedTopic, forceRefresh: true);
                      },
                    ),
                    const Spacer(),
                    if (!isStudent)
                      ElevatedButton(
                        onPressed: _onAddLevelPressed,
                        child: Text(AppLocalizations.of(context)!.addLevel),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // SEARCH BAR
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: AppLocalizations.of(context)!.searchLevels,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 16),

                // TOPIC FILTER CHIPS
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: _topics.map((topic) {
                    final bool selected = _selectedTopic == topic;
                    return FilterChip(
                      label: Text(
                        _getLocalizedTopic(topic),
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

                // VISIBILITY FILTER (Only for teachers/admins)
                if (!isStudent) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.visibility}: ',
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
                                Text(_getLocalizedVisibility(visibility)),
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

                // LEVEL LIST
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredLevels.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.noLevelsFound,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredLevels.length,
                          itemBuilder: (context, index) {
                            final level = _filteredLevels[index];
                            final levelTypeName =
                                level.levelTypeName ?? 'Unknown';

                            return ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      level.levelName ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status badge
                                  if (level.isPrivate ?? false)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock,
                                            size: 14,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.private,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.public,
                                            size: 14,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.public,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(levelTypeName),
                              leading: const Icon(Icons.videogame_asset),
                              trailing: isStudent
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () async {
                                            final currentLevel =
                                                await GameAPI.fetchLevelById(
                                                  level.levelId!,
                                                );
                                            if (currentLevel == null) {
                                              showSnackBar(
                                                context,
                                                AppLocalizations.of(
                                                  context,
                                                )!.failedToLoadLevel,
                                                Colors.red,
                                              );
                                              return;
                                            }

                                            await showEditGamePage(
                                              context: context,
                                              showSnackBar: showSnackBar,
                                              level: currentLevel,
                                              userRole: widget.userRole,
                                            );

                                            fetchLevels(
                                              topic: _selectedTopic,
                                              forceRefresh: true,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.deleteLevel,
                                                ),
                                                content: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.deleteLevelConfirmation,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.cancel,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.delete,
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      deleteLevel(
                                                        level.levelId!,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              onTap: isStudent
                                  ? () async {
                                      final currentLevel =
                                          await GameAPI.fetchLevelById(
                                            level.levelId!,
                                          );
                                      showPlayGamePage(
                                        context: context,
                                        showSnackBar: showSnackBar,
                                        level: currentLevel!,
                                        userRole: widget.userRole,
                                      );
                                    }
                                  : null,
                            );
                          },
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
