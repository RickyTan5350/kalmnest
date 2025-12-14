import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/student/services/local_achievement_storage.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'package:flutter_codelab/student/widgets/achievements/student_achievement_detail_page.dart';

class StudentViewAchievementsPage extends StatefulWidget {
  final ViewLayout layout;
  final String userId;
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  final String searchText;
  final String? selectedTopic;

  const StudentViewAchievementsPage({
    super.key,
    required this.layout,
    required this.userId,
    required this.showSnackBar,
    this.searchText = '',
    this.selectedTopic,
  });

  @override
  State<StudentViewAchievementsPage> createState() =>
      _StudentViewAchievementsPageState();
}

class _StudentViewAchievementsPageState
    extends State<StudentViewAchievementsPage> {
  Future<List<AchievementData>>? _myAchievements;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  IconData _getIconData(String? iconValue) {
    final entry = achievementIconOptions.firstWhere(
      (opt) => opt['value'] == iconValue,
      orElse: () => {'icon': Icons.help_outline},
    );
    return entry['icon'] as IconData;
  }



  List<Map<String, dynamic>> _transformData(BuildContext context, List<AchievementData> briefs) {
    return briefs.map((brief) {
      final iconValue = brief.icon;
      return {
        'id': brief.achievementId,
        'title': brief.achievementTitle ?? 'No Title',
        'icon': _getIconData(iconValue),
        'color': getAchievementColor(context, iconValue),
        'preview': brief.achievementDescription,
      };
    }).toList();
  }

  Future<void> _loadData() async {
    final localStore = LocalAchievementStorage();
    final api = AchievementApi();

    final localFuture = localStore.getUnlockedAchievements(widget.userId);

    setState(() {
      _myAchievements = localFuture;
      _isOffline = false;
    });

    try {
      final cloudData = await api.fetchMyUnlockedAchievements();
      await localStore.saveUnlockedAchievements(widget.userId, cloudData);

      if (mounted) {
        setState(() {
          _myAchievements = Future.value(cloudData);
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
        widget.showSnackBar(
          context,
          "Unable to sync. Showing cached data.",
          Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  // --- 1. HANDLE NAVIGATION LOGIC ---
  void _handleAchievementTap(AchievementData originalItem) {
    if (_isOffline) {
      widget.showSnackBar(
        context,
        "Cannot view details in offline mode.",
        Theme.of(context).colorScheme.onSurface,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAchievementDetailPage(
          initialData: originalItem,
          obtainedAt: originalItem.createdAt,
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Map<String, dynamic> item,
    AchievementData originalItem,
  ) {
    final String title = item['title'];
    final IconData icon = item['icon'];
    final Color color = item['color'];
    final String? preview = item['preview'];

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        // --- 2. USE HANDLER IN GRID ---
        onTap: () => _handleAchievementTap(originalItem),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(icon, color: color.withOpacity(0.1)),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 4.0, 8.0),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      preview ?? 'Description not available.',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Offline Mode: Details unavailable.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: FutureBuilder<List<AchievementData>>(
        future: _myAchievements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _myAchievements == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOfflineBanner(),
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text("No achievements yet."),
                  const Text("Keep learning to unlock them!"),
                ],
              ),
            );
          }

          List<AchievementData> originalData = snapshot.data!;

          List<AchievementData> filteredData = originalData.where((item) {
            final String title = item.achievementTitle?.toLowerCase() ?? '';
            final String description =
                item.achievementDescription?.toLowerCase() ?? '';
            final String icon = item.icon?.toLowerCase() ?? '';
            final String level = item.levelName?.toLowerCase() ?? '';

            final isMatchingSearch =
                widget.searchText.isEmpty ||
                title.contains(widget.searchText) ||
                description.contains(widget.searchText);

            final isMatchingTopic =
                widget.selectedTopic == null ||
                icon.contains(widget.selectedTopic!) ||
                (widget.selectedTopic! == 'level' && level.isNotEmpty) ||
                (widget.selectedTopic! == 'quiz');

            return isMatchingSearch && isMatchingTopic;
          }).toList();

          if (filteredData.isEmpty) {
            return Column(
              children: [
                _buildOfflineBanner(),
                const Expanded(
                  child: Center(
                    child: Text("No achievements match your search or filter."),
                  ),
                ),
              ],
            );
          }

          final List<Map<String, dynamic>> uiData = _transformData(context,
            filteredData,
          );

          if (widget.layout == ViewLayout.grid) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOfflineBanner(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          8.0,
                          16.0,
                          16.0,
                        ),
                        child: Text(
                          "Showing ${uiData.length} unlocked achievements",
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverGrid.builder(
                    itemCount: uiData.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250.0,
                          mainAxisSpacing: 12.0,
                          crossAxisSpacing: 12.0,
                          childAspectRatio: 0.9,
                        ),
                    itemBuilder: (context, index) {
                      final item = uiData[index];
                      final originalItem = filteredData[index];
                      return _buildAchievementCard(context, item, originalItem);
                    },
                  ),
                ),
              ],
            );
          } else {
            // --- LIST VIEW ---
            return Column(
              children: [
                _buildOfflineBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final originalItem =
                          filteredData[index]; // Needed for nav
                      final transformedItem = uiData[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
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
                            backgroundColor: transformedItem['color']
                                .withOpacity(0.1),
                            foregroundColor: transformedItem['color'],
                            child: Icon(transformedItem['icon']),
                          ),
                          title: Text(item.achievementTitle ?? "Achievement"),
                          subtitle: Text(item.achievementDescription ?? ""),
                          trailing: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          // --- 3. USE HANDLER IN LIST ---
                          onTap: () => _handleAchievementTap(originalItem),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
