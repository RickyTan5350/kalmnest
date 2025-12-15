import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/play_game_page.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_codelab/models/level.dart';
import 'package:flutter_codelab/api/game_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/edit_game_page.dart';

class GamePage extends StatefulWidget {
  final String userRole; // Current user role

  const GamePage({super.key, required this.userRole});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final List<String> _topics = ['All', 'HTML', 'CSS', 'JS', 'PHP', 'Quiz'];
  String _selectedTopic = 'All';

  List<LevelModel> _levels = [];
  List<LevelModel> _filteredLevels = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchLevels();
  }

  Future<void> fetchLevels({String? topic}) async {
    setState(() => _loading = true);
    final levels = await GameAPI.fetchLevels(topic: topic);
    if (!mounted) return;

    setState(() {
      _levels = levels;
      _filteredLevels = _applySearch(levels, _searchQuery);
      _loading = false;
    });
  }

  List<LevelModel> _applySearch(List<LevelModel> levels, String query) {
    if (query.isEmpty) return levels;
    return levels
        .where(
          (level) => (level.levelName ?? '').toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredLevels = _applySearch(_levels, _searchQuery);
    });
  }

  Future<void> deleteLevel(String levelId) async {
    final response = await GameAPI.deleteLevel(levelId);
    if (response.success) {
      fetchLevels(topic: _selectedTopic);
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
    );
  }

  void _openUnityWebView(LevelModel level) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 1200,
          height: 800,
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(
                "https://backend_services.test/unity_build/index.html?role=${widget.userRole}&level=${level.levelId}",
              ),
            ),
            initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
            onWebViewCreated: (controller) {},
            onLoadStart: (controller, url) {
              debugPrint("Started loading: $url");
            },
            onLoadStop: (controller, url) async {
              debugPrint("Finished loading: $url");
            },
            onLoadError: (controller, url, code, message) {
              debugPrint("Failed to load $url: $message");
            },
          ),
        ),
      ),
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
                      "Game Levels",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Levels',
                      onPressed: () {
                        fetchLevels(topic: _selectedTopic);
                      },
                    ),
                    const Spacer(),
                    if (!isStudent)
                      ElevatedButton(
                        onPressed: _onAddLevelPressed,
                        child: const Text('Add Level'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // SEARCH BAR
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search levels...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 16),

                // FILTER CHIPS
                Wrap(
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
                          fetchLevels(topic: topic);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // LEVEL LIST
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredLevels.isEmpty
                      ? const Center(child: Text('No levels found'))
                      : ListView.builder(
                          itemCount: _filteredLevels.length,
                          itemBuilder: (context, index) {
                            final level = _filteredLevels[index];
                            final levelTypeName =
                                level.levelTypeName ?? 'Unknown';

                            return ListTile(
                              title: Text(
                                level.levelName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                                                "Failed to load level data",
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

                                            fetchLevels(topic: _selectedTopic);
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
                                                title: const Text(
                                                  'Delete Level',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this level?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('Cancel'),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  ),
                                                  TextButton(
                                                    child: const Text(
                                                      'Delete',
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
