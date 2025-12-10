import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/student/services/local_achievement_storage.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';

class StudentViewAchievementsPage extends StatefulWidget {
  final ViewLayout layout;
  final String userId;
  final void Function(BuildContext context, String message, Color color) showSnackBar;

  const StudentViewAchievementsPage({
    super.key,
    required this.layout,
    required this.userId,
    required this.showSnackBar,
  });

  @override
  State<StudentViewAchievementsPage> createState() => _StudentViewAchievementsPageState();
}

class _StudentViewAchievementsPageState extends State<StudentViewAchievementsPage> {
  Future<List<AchievementData>>? _myAchievements;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- HELPER FUNCTIONS FOR UI TRANSFORMATION (Copied from Admin View) ---
  IconData _getIconData(String? iconValue) {
    // Uses the imported achievementIconOptions list
    final entry = achievementIconOptions.firstWhere(
          (opt) => opt['value'] == iconValue,
      orElse: () => {'icon': Icons.help_outline},
    );
    return entry['icon'] as IconData;
  }

  Color _getColor(String? iconValue) {
    switch (iconValue) {
      case 'html':
        return Colors.orange;
      case 'css':
        return Colors.green;
      case 'javascript':
        return Colors.yellow;
      case 'php':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _transformData(List<AchievementData> briefs) {
    return briefs.map((brief) {
      final iconValue = brief.icon;
      return {
        'id': brief.achievementId,
        'title': brief.achievementTitle ?? 'No Title',
        'icon': _getIconData(iconValue),
        'color': _getColor(iconValue),
        'preview': brief.achievementDescription,
        // 'progress' is not relevant for student's unlocked list, but let's keep the map structure simple
      };
    }).toList();
  }
  // ------------------------------------------------------------------------

  Future<void> _loadData() async {
    final localStore = LocalAchievementStorage();
    final api = AchievementApi();

    final localFuture = localStore.getUnlockedAchievements(widget.userId);

    setState(() {
      _myAchievements = localFuture;
    });

    try {
      final cloudData = await api.fetchMyUnlockedAchievements();

      await localStore.saveUnlockedAchievements(widget.userId, cloudData);

      if (mounted) {
        setState(() {
          _myAchievements = Future.value(cloudData);
        });
      }
    } catch (e) {
      print("Offline or Server Error: $e");
      // Optional: Show a small snackbar saying "Offline mode"
    }
  }

  // --- Simplified Achievement Card for Student Grid View ---
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
          // Use a subtle outline color, matching the admin's unselected outline
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          // Student view can show a dialog or navigate to a dedicated detail page
          // For now, let's keep it simple and just show a message.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing $title'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Stack(
          children: [
            // Background Icon
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    icon,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Title Row
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
                      const Icon(Icons.check_circle, size: 20, color: Colors.green), // Unlocked indicator
                    ],
                  ),
                ),
                // Description Preview
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
  // ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: FutureBuilder<List<AchievementData>>(
        future: _myAchievements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _myAchievements == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No achievements yet."),
                  Text("Keep learning to unlock them!"),
                ],
              ),
            );
          }

          final List<AchievementData> originalData = snapshot.data!;
          // Transform the full data into the UI-friendly map list
          final List<Map<String, dynamic>> uiData = _transformData(originalData);

          if (widget.layout == ViewLayout.grid) {
            // --- GRID VIEW IMPLEMENTATION (CustomScrollView + SliverGrid) ---
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    child: Text("Total unlocked: ${uiData.length} achievements"),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverGrid.builder(
                    itemCount: uiData.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250.0, // Same max width as Admin View
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 0.9, // Same aspect ratio as Admin View
                    ),
                    itemBuilder: (context, index) {
                      final item = uiData[index];
                      final originalItem = originalData[index];
                      return _buildAchievementCard(context, item, originalItem);
                    },
                  ),
                ),
              ],
            );
          } else {
            // --- LIST VIEW (Updated to include the outline shape) ---
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: originalData.length,
              itemBuilder: (context, index) {
                final item = originalData[index];
                final transformedItem = uiData[index]; // Use transformed data for icon/color

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  // >>> START CHANGES HERE <<<
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  // >>> END CHANGES HERE <<<
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transformedItem['color'].withOpacity(0.1),
                      foregroundColor: transformedItem['color'],
                      child: Icon(transformedItem['icon']),
                    ),
                    title: Text(item.achievementTitle ?? "Achievement"),
                    subtitle: Text(item.achievementDescription ?? ""),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}