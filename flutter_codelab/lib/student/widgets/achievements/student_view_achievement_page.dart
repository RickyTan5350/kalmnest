import 'dart:async';
import 'package:flutter/material.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/student/services/local_achievement_storage.dart';
import 'package:code_play/constants/view_layout.dart';
import 'package:code_play/constants/achievement_constants.dart';
import 'package:code_play/enums/sort_enums.dart'; // Shared Enums
import 'package:code_play/student/widgets/achievements/student_achievement_detail_page.dart';

class StudentViewAchievementsPage extends StatefulWidget {
  final ViewLayout layout;
  final String userId;
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  final String searchText;
  final String? selectedTopic;
  final SortType sortType;
  final SortOrder sortOrder;

  const StudentViewAchievementsPage({
    super.key,
    required this.layout,
    required this.userId,
    required this.showSnackBar,
    this.searchText = '',
    this.selectedTopic,
    this.sortType = SortType.alphabetical,
    this.sortOrder = SortOrder.ascending,
  });

  @override
  State<StudentViewAchievementsPage> createState() =>
      StudentViewAchievementsPageState();
}

class StudentViewAchievementsPageState
    extends State<StudentViewAchievementsPage> {
  Future<List<AchievementData>>? _myAchievements;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refreshData() {
    _loadData();
  }

  List<Map<String, dynamic>> _transformData(List<AchievementData> briefs) {
    return briefs.map((brief) {
      final iconValue = brief.icon;
      return {
        'id': brief.achievementId,
        'title': brief.achievementTitle ?? 'No Title',
        'icon': getAchievementIcon(iconValue),
        'color': getAchievementColor(context, iconValue),
        'preview': brief.achievementDescription,
        'isUnlocked': brief.isUnlocked, // NEW
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
      // 1. Attempt to connect to the server for a longer time (30 seconds)
      final cloudData = await api.fetchMyUnlockedAchievements().timeout(
        const Duration(seconds: 30),
      );

      // 2. Only cache OBTAINED (unlocked) achievements locally
      final obtainedAchievements = cloudData
          .where((a) => a.isUnlocked)
          .toList();
      await localStore.saveUnlockedAchievements(
        widget.userId,
        obtainedAchievements,
      );

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

        String errorMessage = "Unable to sync. Showing cached data.";
        if (e is TimeoutException) {
          errorMessage = "Connection timed out. Showing cached achievements.";
        }

        widget.showSnackBar(context, errorMessage, Colors.orange.shade800);
      }
    }
  }

  // --- 1. HANDLE NAVIGATION LOGIC ---
  void _handleAchievementTap(AchievementData originalItem) {
    if (_isOffline) {
      widget.showSnackBar(
        context,
        "Cannot view details in offline mode.",
        Colors.grey.shade800,
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
        onTap: item['isUnlocked'] == true
            ? () => _handleAchievementTap(originalItem)
            : () {
                widget.showSnackBar(
                  context,
                  "Locked. Keep playing to unlock!",
                  Colors.grey,
                );
              },
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    icon,
                    color: item['isUnlocked'] == true
                        ? color.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                  ),
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
                      Icon(
                        icon,
                        color: item['isUnlocked'] == true ? color : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // NEW: Show Lock Icon if locked
                      item['isUnlocked'] == true
                          ? const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green,
                            )
                          : const Icon(
                              Icons.lock,
                              size: 20,
                              color: Colors.grey,
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
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Offline Mode: Details unavailable.",
              style: TextStyle(
                color: Colors.orange.shade900,
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
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text("No achievements yet."),
                  const Text("Keep learning to unlock them!"),
                ],
              ),
            );
          }

          List<AchievementData> originalData = snapshot.data!;

          // --- FILTERING LOGIC ---
          List<AchievementData> filteredData = filterAchievements(
            achievements: originalData,
            searchText: widget.searchText,
            selectedTopic: widget.selectedTopic,
            currentUserId: widget.userId,
          );

          // --- SORTING LOGIC ---
          filteredData = sortAchievements(
            achievements: filteredData,
            sortType: widget.sortType,
            sortOrder: widget.sortOrder,
          );

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

          final List<Map<String, dynamic>> uiData = _transformData(
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "${uiData.where((i) => i['isUnlocked'] == true).length} / ${uiData.length} Unlocked",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            foregroundColor: item.isUnlocked
                                ? transformedItem['color']
                                : Colors.grey,
                            child: Icon(transformedItem['icon']),
                          ),
                          title: Text(
                            item.achievementTitle ?? "Achievement",
                            style: TextStyle(
                              color: item.isUnlocked ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Text(item.achievementDescription ?? ""),
                          trailing: item.isUnlocked
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const Icon(Icons.lock, color: Colors.grey),
                          // --- 3. USE HANDLER IN LIST ---
                          onTap: item.isUnlocked
                              ? () => _handleAchievementTap(originalItem)
                              : () {
                                  widget.showSnackBar(
                                    context,
                                    "Locked. Keep playing to unlock!",
                                    Colors.grey,
                                  );
                                },
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
