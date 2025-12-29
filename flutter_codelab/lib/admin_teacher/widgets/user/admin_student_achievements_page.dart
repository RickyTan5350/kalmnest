import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'package:flutter_codelab/admin_teacher/widgets/achievements/admin_achievement_detail.dart';

class AdminStudentAchievementsPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminStudentAchievementsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminStudentAchievementsPage> createState() =>
      _AdminStudentAchievementsPageState();
}

class _AdminStudentAchievementsPageState
    extends State<AdminStudentAchievementsPage> {
  final AchievementApi _achievementApi = AchievementApi();
  Future<List<AchievementData>>? _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAchievements();
  }

  Future<void> _fetchAchievements() async {
    setState(() {
      _achievementsFuture = _achievementApi.fetchUserAchievements(
        widget.userId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.userName}'s Achievements")),
      body: FutureBuilder<List<AchievementData>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading achievements: ${snapshot.error.toString().split("Exception: ").last}',
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No achievements unlocked yet."));
          }

          final achievements = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final color = getAchievementColor(context, achievement.icon);
              final icon = getAchievementIcon(achievement.icon);
              final dateStr = achievement.unlockedAt != null
                  ? achievement.unlockedAt!.toString().split(' ')[0]
                  : 'N/A';

              return Card(
                elevation: 2.0,
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminAchievementDetailPage(
                          initialData: achievement,
                          studentName: widget.userName,
                          // If we know the current admin ID, pass it here, but it's optional
                          // isAdmin: true, // Assuming access to this page implies admin/teacher rights
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large Icon Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: color.withOpacity(0.1),
                          foregroundColor: color,
                          child: Icon(icon, size: 28),
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.achievementTitle ?? "Achievement",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Unlocked on $dateStr",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              if (achievement.achievementDescription != null)
                                Text(
                                  achievement.achievementDescription!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
