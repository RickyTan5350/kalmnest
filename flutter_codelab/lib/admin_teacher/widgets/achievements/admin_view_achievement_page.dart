// lib/widgets/admin_view_achievement_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import '../selection_box_painter.dart';
import '../grid_layout_view.dart';
import 'admin_achievement_detail.dart';
import 'package:flutter_codelab/constants/view_layout.dart';

class AdminViewAchievementsPage extends StatefulWidget {
  final ViewLayout layout;
  final String userId;
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  // NEW: Filter Parameters
  final String searchText;
  final String? selectedTopic;

  const AdminViewAchievementsPage({
    super.key,
    required this.layout,
    required this.userId,
    required this.showSnackBar,
    // NEW: Added to constructor
    this.searchText = '',
    this.selectedTopic,
  });

  @override
  State<AdminViewAchievementsPage> createState() =>
      _AdminViewAchievementsPageState();
}

class _AdminViewAchievementsPageState extends State<AdminViewAchievementsPage> {
  // --- API State ---
  late Future<List<AchievementData>> _achievementsFuture;
  final AchievementApi _api = AchievementApi();

  // --- Selection State ---
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  // --- HYBRID SELECTION VARIABLES ---
  final Map<String, GlobalKey> _gridItemKeys = {};
  final Set<String> _dragProcessedIds = {};
  Offset? _dragStart;
  Offset? _dragEnd;
  Set<String> _initialSelection = {};

  // Helper to detect platform
  bool get _isDesktop {
    final p = Theme.of(context).platform;
    return p == TargetPlatform.windows ||
        p == TargetPlatform.linux ||
        p == TargetPlatform.macOS;
  }
  // ---------------------------------

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // NEW: Allow data refresh if filtering changes, though the filtering is primarily local here
  @override
  void didUpdateWidget(covariant AdminViewAchievementsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the API call supported filtering, we'd trigger _refreshData here.
    // For now, we rely on local filtering in the build method.
  }

  void _refreshData() {
    setState(() {
      // NOTE: Admin view fetches ALL achievements via fetchBriefAchievements()
      _achievementsFuture = _api.fetchBriefAchievements();
    });
  }

  void _toggleSelection(String achievementId) {
    if (_isDeleting) return;
    setState(() {
      if (_selectedIds.contains(achievementId)) {
        _selectedIds.remove(achievementId);
      } else {
        _selectedIds.add(achievementId);
      }
    });
  }

  // --- HYBRID LOGIC 1: ANDROID (Finger Overlap) ---
  void _handleDragSelect(Offset position) {
    for (final entry in _gridItemKeys.entries) {
      final String id = entry.key;
      final GlobalKey key = entry.value;

      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null) {
        // Convert global finger position to local item position
        final localPosition = renderBox.globalToLocal(position);

        // Check if finger is inside this item
        if (renderBox.size.contains(localPosition)) {
          // Only toggle if we haven't touched this item yet in *this specific* drag session
          if (!_dragProcessedIds.contains(id)) {
            _toggleSelection(id);
            _dragProcessedIds.add(id);
            HapticFeedback.selectionClick(); // Tactile feedback
          }
        }
      }
    }
  }

  // --- HYBRID LOGIC 2: WINDOWS (Box Overlap) ---
  void _handleBoxSelect(Offset currentPosition) {
    setState(() {
      _dragEnd = currentPosition;
    });

    if (_dragStart == null) return;

    // Define the blue box
    final Rect selectionBox = Rect.fromPoints(_dragStart!, _dragEnd!);

    // Start with what we had before dragging
    final Set<String> newSelection = Set.from(_initialSelection);

    for (final entry in _gridItemKeys.entries) {
      final String id = entry.key;
      final GlobalKey key = entry.value;

      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      // Get item's position relative to the Stack (context)
      final Offset itemPosition = renderBox.localToGlobal(
        Offset.zero,
        ancestor: context.findRenderObject(),
      );
      final Rect itemRect = itemPosition & renderBox.size;

      // Check if Blue Box touches Item Box
      if (selectionBox.overlaps(itemRect)) {
        newSelection.add(id);
      } else if (!_initialSelection.contains(id)) {
        // If we shrink the box, unselect items (unless they were selected before drag started)
        newSelection.remove(id);
      }
    }

    // Update state if changed
    if (_selectedIds.length != newSelection.length ||
        !_selectedIds.containsAll(newSelection)) {
      setState(() {
        _selectedIds.clear();
        _selectedIds.addAll(newSelection);
      });
      // Optional: HapticFeedback.selectionClick();
    }
  }

  void _endDrag() {
    if (_isDesktop) {
      setState(() {
        _dragStart = null;
        _dragEnd = null;
      });
    }
    _dragProcessedIds.clear(); // Clear drag-select buffer
  }

  // --- DELETE FUNCTION ---
  Future<void> _deleteSelectedAchievements() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Achievements?'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} selected achievement(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    final BuildContext scaffoldContext = context;

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });
      try {
        await _api.deleteAchievements(_selectedIds);
        widget.showSnackBar(
          scaffoldContext,
          'Successfully deleted ${_selectedIds.length} achievement(s).',
          Colors.green,
        );
        setState(() {
          _selectedIds.clear();
        });
        _refreshData();
      } catch (e) {
        widget.showSnackBar(
          scaffoldContext,
          'Error deleting achievements: $e',
          Colors.red,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  // --- HELPER FUNCTIONS FOR UI TRANSFORMATION ---
  IconData _getIconData(String? iconValue) {
    final entry = achievementIconOptions.firstWhere(
      (opt) => opt['value'] == iconValue,
      orElse: () => {'icon': Icons.help},
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
        'progress': 0.0,
      };
    }).toList();
  }

  // --- CONTEXTUAL MENU BAR ---
  Widget _buildSelectionMenuBar() {
    final bool hasSelection = _selectedIds.isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: SizedBox(
        height: hasSelection ? 60 : 0,
        child: hasSelection
            ? Material(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _selectedIds.clear();
                        }),
                        tooltip: 'Clear selection',
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedIds.length} selected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (_isDeleting)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      else
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: _deleteSelectedAchievements,
                          tooltip: 'Delete selected',
                        ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSelectionMenuBar(),
        Expanded(
          child: FutureBuilder<List<AchievementData>>(
            future: _achievementsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                if (snapshot.error.toString().contains(
                  "type 'Null' is not a subtype of type 'String'",
                )) {
                  return const Center(
                    child: Text(
                      "Error: API data mismatch.\nCheck `AchievementData.fromJson`.",
                    ),
                  );
                }
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No achievements found."));
              }

              List<AchievementData> originalData = snapshot.data!;

              // --- FILTERING LOGIC (Copied from Student View) ---
              List<AchievementData> filteredData = originalData.where((item) {
                final String title = item.achievementTitle?.toLowerCase() ?? '';
                final String description =
                    item.achievementDescription?.toLowerCase() ?? '';
                final String icon = item.icon?.toLowerCase() ?? '';
                final String level = item.level?.toLowerCase() ?? '';

                // 1. Search Text Filter
                final isMatchingSearch =
                    widget.searchText.isEmpty ||
                    title.contains(widget.searchText) ||
                    description.contains(widget.searchText);

                // 2. Topic Filter
                final isMatchingTopic =
                    widget.selectedTopic == null ||
                    icon.contains(widget.selectedTopic!) ||
                    (widget.selectedTopic! == 'level' && level.isNotEmpty) ||
                    (widget.selectedTopic! == 'quiz');

                return isMatchingSearch && isMatchingTopic;
              }).toList();

              if (filteredData.isEmpty) {
                return const Center(
                  child: Text("No achievements match your search or filter."),
                );
              }
              // --- END FILTERING LOGIC ---

              final List<Map<String, dynamic>> uiData = _transformData(
                filteredData,
              );

              // --- GESTURE DETECTOR WRAPPING THE SCROLLVIEW ---
              return GestureDetector(
                // Start "Selection Mode" on Long Press
                onLongPressStart: (details) {
                  if (_isDesktop) {
                    // WINDOWS: Prepare box selection
                    _initialSelection = Set.from(_selectedIds);
                    setState(() {
                      _dragStart = details.localPosition;
                      _dragEnd = details.localPosition;
                    });
                    _handleBoxSelect(details.localPosition);
                  } else {
                    // MOBILE: Select item under finger
                    _dragProcessedIds.clear();
                    _handleDragSelect(details.globalPosition); // Uses Global
                  }
                },

                // Continue selection as finger/mouse moves
                onLongPressMoveUpdate: (details) {
                  if (_isDesktop) {
                    // WINDOWS: Update box size
                    _handleBoxSelect(details.localPosition);
                  } else {
                    // MOBILE: Check for new items under finger
                    _handleDragSelect(details.globalPosition);
                  }
                },

                // Cleanup on release
                onLongPressEnd: (_) => _endDrag(),

                // HitTestBehavior.translucent lets taps pass through to InkWells
                // (so single tap navigation still works)
                behavior: HitTestBehavior.translucent,

                child: Stack(
                  children: [
                    // Layer 1: The Grid Content
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              8.0,
                              16.0,
                              16.0,
                            ),
                            child: Text(
                              "Showing: ${uiData.length} achievements",
                            ), // Updated text
                          ),
                        ),
                        // Pass filteredData here
                        _buildSliverContent(context, uiData, filteredData),
                      ],
                    ),

                    // Layer 2: The Blue Selection Box (Desktop Only)
                    if (_isDesktop && _dragStart != null && _dragEnd != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          // IgnorePointer ensures the box doesn't block touches
                          child: CustomPaint(
                            painter: SelectionBoxPainter(
                              start: _dragStart,
                              end: _dragEnd,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliverContent(
    BuildContext context,
    List<Map<String, dynamic>> achievements,
    List<AchievementData> originalData, // Now receives filteredData
  ) {
    if (widget.layout == ViewLayout.grid) {
      // --- GRID VIEW ---
      return GridLayoutView(
        achievements: achievements,
        originalData: originalData,
        selectedIds: _selectedIds,
        onToggleSelection: _toggleSelection,
        itemKeys: _gridItemKeys,
      );
    } else {
      // --- LIST VIEW ---
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final item = achievements[index];
            final originalItem = originalData[index]; // <-- Get original item
            final String id = originalItem.achievementId!;
            final bool isSelected = _selectedIds.contains(id);

            return _buildAchievementListTile(
              context: context,
              item: item,
              originalItem: originalItem, // <-- Pass it here
              isSelected: isSelected,
              onToggle: () => _toggleSelection(id),
            );
          }, childCount: achievements.length),
        ),
      );
    }
  }

  Widget _buildAchievementListTile({
    required BuildContext context,
    required Map<String, dynamic> item,
    required bool isSelected,
    required VoidCallback onToggle,
    required AchievementData originalItem,
  }) {
    final String title = item['title'];
    final IconData icon = item['icon'];
    final Color iconColor = item['color'];
    final double progress = item['progress'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6.0),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
            const SizedBox(height: 2.0),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Handle more options tap
          },
        ),
        onTap: () {
          if (_selectedIds.isNotEmpty) {
            onToggle();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminAchievementDetailPage(
                  initialData: originalItem, // Pass the partial object here
                ),
              ),
            );
          }
        },
        onLongPress: onToggle,
      ),
    );
  }
}
