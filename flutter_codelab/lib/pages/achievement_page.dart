import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/admin_teacher/widgets/achievements/admin_view_achievement_page.dart';
import 'package:flutter_codelab/student/widgets/achievements/student_view_achievement_page.dart';
import 'package:flutter_codelab/constants/view_layout.dart' show ViewLayout;

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
    'Level',
    'Quiz',
  ]; // Reordered 'All' to front
  String _selectedTopic = 'All'; // Default to 'All'
  ViewLayout _viewLayout = ViewLayout.grid;

  // NEW: State for Search Text
  String _searchText = '';

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
                        setState(() {
                          _viewLayout = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- SEARCH & CHIPS ---
                SizedBox(
                  width: 300,
                  child: SearchBar(
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
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: _topics.map((topic) {
                    final isSelected = _selectedTopic == topic;
                    return FilterChip(
                      label: Text(
                        topic,
                        style: TextStyle(
                          color: isSelected ? colors.primary : colors.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          // NEW: Handle selection/deselection
                          _selectedTopic = selected ? topic : 'All';
                        });
                      },
                    );
                  }).toList(),
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
                              : _selectedTopic.toLowerCase(),
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
                              : _selectedTopic.toLowerCase(),
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
