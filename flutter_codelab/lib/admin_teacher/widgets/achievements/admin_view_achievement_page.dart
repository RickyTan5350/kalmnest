// lib/widgets/admin_view_achievement_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback
import 'package:flutter_codelab/admin_teacher/widgets/achievements/achievement_grid_layout.dart';
import 'package:flutter_codelab/api/achievement_api.dart';
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'package:flutter_codelab/admin_teacher/services/selection_box_painter.dart';
import 'package:flutter_codelab/admin_teacher/services/selection_gesture_wrapper.dart';
import 'admin_achievement_detail.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';
// IMPORT THE NEW WRAPPER

class AdminViewAchievementsPage extends StatefulWidget {
  final ViewLayout layout;
  final String userId;
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  // Filter Parameters
  final String searchText;
  final String? selectedTopic;
  final SortType sortType;
  final SortOrder sortOrder;
  final bool isAdmin; // NEW

  const AdminViewAchievementsPage({
    super.key,
    required this.layout,
    required this.userId,
    required this.showSnackBar,
    this.searchText = '',
    this.selectedTopic,
    this.sortType = SortType.alphabetical,
    this.sortOrder = SortOrder.ascending,
    this.isAdmin = false, // NEW
  });

  @override
  State<AdminViewAchievementsPage> createState() =>
      AdminViewAchievementsPageState();
}

class AdminViewAchievementsPageState extends State<AdminViewAchievementsPage> {
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
  final GlobalKey _selectionAreaKey = GlobalKey();

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

  @override
  void didUpdateWidget(covariant AdminViewAchievementsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If filtering logic was server-side, we would refresh here.
  }

  void refreshData() {
    _refreshData();
  }

  void _refreshData() {
    setState(() {
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

    // Get the selection area (Stack) render object
    final RenderBox? ancestor =
        _selectionAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (ancestor == null) return;

    for (final entry in _gridItemKeys.entries) {
      final String id = entry.key;
      final GlobalKey key = entry.value;

      final RenderBox? itemBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null) continue;

      // Get item's position relative to the Stack (ancestor)
      final Offset itemPosition = itemBox.localToGlobal(
        Offset.zero,
        ancestor: ancestor,
      );
      final Rect itemRect = itemPosition & itemBox.size;

      // Check if Blue Box touches Item Box
      if (selectionBox.overlaps(itemRect)) {
        newSelection.add(id);
      }
      // FIX: Only remove if it wasn't selected BEFORE the drag started
      else if (!_initialSelection.contains(id)) {
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
  // --- DELETE FUNCTION ---
  Future<void> _deleteSelectedAchievements() async {
    final BuildContext scaffoldContext = context;

    // Load current data to check permissions
    final List<AchievementData> allAchievements = await _achievementsFuture;

    // 1. Separate items by permission
    final List<String> toDeleteIds = [];
    final List<String> skippedIds = [];

    for (var id in _selectedIds) {
      final achievement = allAchievements.firstWhere(
        (a) => a.achievementId == id,
        orElse: () => AchievementData(achievementId: ''),
      );

      if (achievement.achievementId == null ||
          achievement.achievementId!.isEmpty)
        continue;

      // Access Control Logic: Admin OR Creator
      final isCreator =
          achievement.creatorId != null &&
          widget.userId.toString() == achievement.creatorId.toString();

      if (widget.isAdmin || isCreator) {
        toDeleteIds.add(id);
      } else {
        skippedIds.add(id);
      }
    }

    if (!mounted) return;

    if (toDeleteIds.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Access Denied'),
          content: Text(
            skippedIds.isEmpty
                ? 'No valid items selected.'
                : 'You do not have permission to delete the selected items. You can only delete achievements you created.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Confirmation Dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Achievements?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${toDeleteIds.length} achievement(s)? This action cannot be undone.',
            ),
            if (skippedIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Note: ${skippedIds.length} item(s) will be skipped because you did not create them.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
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

    if (confirmed != true) return;

    if (!mounted) return;

    setState(() {
      _isDeleting = true;
    });

    // 3. Partial Success Execution
    int successCount = 0;
    int failCount = 0;
    List<String> successfullyDeletedIds = [];

    for (final id in toDeleteIds) {
      try {
        await _api.deleteAchievements({id});
        successCount++;
        successfullyDeletedIds.add(id);
      } catch (e) {
        print("Failed to delete achievement $id: $e");
        failCount++;
      }
    }

    // 4. Feedback & Cleanup
    if (mounted) {
      setState(() {
        _isDeleting = false;
        _selectedIds.removeWhere((id) => successfullyDeletedIds.contains(id));
      });

      String message;
      if (failCount == 0 && skippedIds.isEmpty) {
        message = 'Successfully deleted $successCount achievement(s).';
      } else {
        message =
            'Deleted: $successCount, Failed: $failCount, Skipped: ${skippedIds.length}';
      }

      Color snackColor = (failCount > 0 || skippedIds.isNotEmpty)
          ? Colors.orange
          : Colors.green;

      if (successCount == 0 && failCount > 0) {
        snackColor = Colors.red;
      }

      widget.showSnackBar(scaffoldContext, message, snackColor);

      if (successCount > 0) {
        _refreshData();
      }
    }
  }

  // --- HELPER FUNCTIONS FOR UI TRANSFORMATION ---
  // Local _getIconData and _getColor removed. using shared constants.

  List<Map<String, dynamic>> _transformData(List<AchievementData> briefs) {
    return briefs.map((brief) {
      final iconValue = brief.icon;
      return {
        'achievementId': brief.achievementId,
        'title': brief.achievementTitle ?? 'No Title',
        'icon': getAchievementIcon(iconValue),
        'color': getAchievementColor(context, iconValue),
        'preview': brief.achievementDescription,
        'progress': 0.0,
        'unlockedCount': brief.unlockedCount,
        'totalStudents': brief.totalStudents,
      };
    }).toList();
  }

  // --- CONTEXTUAL MENU BAR ---
  // --- HEADER WIDGETS ---
  Widget _buildSortHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey("SortHeader"),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("$count Results", style: theme.textTheme.titleMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(BuildContext context, int totalCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey("SelectionHeader"),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
              Text(
                "${_selectedIds.length} Selected",
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          if (_isDeleting)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: _deleteSelectedAchievements,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedIds.isNotEmpty) {
            setState(() => _selectedIds.clear());
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
        ): () async {
          if (_selectedIds.isNotEmpty) {
            final List<AchievementData> allAchievements =
                await _achievementsFuture;
            final selectedItems = allAchievements
                .where((a) => _selectedIds.contains(a.achievementId))
                .map(
                  (a) => "${a.achievementTitle} - ${a.achievementDescription}",
                )
                .join('\n');

            await Clipboard.setData(ClipboardData(text: selectedItems));

            if (context.mounted) {
              widget.showSnackBar(
                context,
                "Copied ${_selectedIds.length} item(s) to clipboard.",
                Colors.green,
              );
            }
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            // _buildSelectionMenuBar() removed
            Expanded(
              child: FutureBuilder<List<AchievementData>>(
                future: _achievementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No achievements found."));
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
                    return const Center(
                      child: Text(
                        "No achievements match your search or filter.",
                      ),
                    );
                  }

                  final List<Map<String, dynamic>> uiData = _transformData(
                    filteredData,
                  );

                  // --- REPLACED Gesture Logic with WRAPPER ---
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- STICKY HEADER ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          8.0,
                          16.0,
                          16.0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedIds.isNotEmpty
                              ? _buildSelectionHeader(context, uiData.length)
                              : _buildSortHeader(context, uiData.length),
                        ),
                      ),

                      // --- SCROLLABLE CONTENT ---
                      Expanded(
                        child: SelectionGestureWrapper(
                          isDesktop: _isDesktop,
                          selectedIds: _selectedIds,
                          itemKeys: _gridItemKeys,

                          // Start "Selection Mode"
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
                              _handleDragSelect(details.globalPosition);
                            }
                          },

                          // Continue selection
                          onLongPressMoveUpdate: (details) {
                            if (_isDesktop) {
                              // WINDOWS: Update box size
                              _handleBoxSelect(details.localPosition);
                            } else {
                              // MOBILE: Check for new items under finger
                              _handleDragSelect(details.globalPosition);
                            }
                          },

                          // Cleanup on release (ignoring details)
                          onLongPressEnd: (_) => _endDrag(),

                          child: Stack(
                            key:
                                _selectionAreaKey, // Coordinate reference for drag
                            children: [
                              // Layer 1: The Grid Content
                              CustomScrollView(
                                slivers: [
                                  // Pass filteredData here
                                  _buildSliverContent(
                                    context,
                                    uiData,
                                    filteredData,
                                  ),
                                ],
                              ),

                              // Layer 2: The Blue Selection Box (Desktop Only)
                              if (_isDesktop &&
                                  _dragStart != null &&
                                  _dragEnd != null)
                                Positioned.fill(
                                  child: IgnorePointer(
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverContent(
    BuildContext context,
    List<Map<String, dynamic>> achievements,
    List<AchievementData> originalData,
  ) {
    if (widget.layout == ViewLayout.grid) {
      // --- GRID VIEW ---
      return AchievementGridLayout(
        achievements: achievements,
        originalData: originalData,
        selectedIds: _selectedIds,
        onToggleSelection: _toggleSelection,
        itemKeys: _gridItemKeys,
        currentUserId: widget.userId, // NEW
        isAdmin: widget.isAdmin, // NEW
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
            final originalItem = originalData[index];
            final String id = originalItem.achievementId!;
            final bool isSelected = _selectedIds.contains(id);

            // FIX: Generate and store GlobalKey for list items
            final GlobalKey key = _gridItemKeys.putIfAbsent(
              id,
              () => GlobalKey(),
            );

            return _buildAchievementListTile(
              context: context,
              item: item,
              originalItem: originalItem,
              isSelected: isSelected,
              onToggle: () => _toggleSelection(id),
              key: key, // Pass the key
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
    required GlobalKey key, // Receive the key
  }) {
    final String title = item['title'];
    final IconData icon = item['icon'];
    final Color iconColor = item['color'];
    final int? unlockedCount = item['unlockedCount'];
    final int? totalStudents = item['totalStudents'];

    // Calculate progress
    double displayProgress = 0.0;
    if (unlockedCount != null && totalStudents != null && totalStudents > 0) {
      displayProgress = unlockedCount / totalStudents;
    }

    // FIX: Wrap in Container with GlobalKey for selection logic
    return Container(
      key: key,
      child: Card(
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
              const SizedBox(height: 4.0),
              if (unlockedCount != null && totalStudents != null)
                Text(
                  '$unlockedCount / $totalStudents Students',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 4.0),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: displayProgress),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  borderRadius: BorderRadius.circular(4.0),
                  minHeight: 4.0,
                ),
              ),
              const SizedBox(height: 2.0),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle more options tap if needed
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
                    initialData: originalItem,
                    currentUserId: widget.userId, // NEW
                    isAdmin: widget.isAdmin, // NEW
                  ),
                ),
              );
            }
          },
          onLongPress: onToggle,
        ),
      ),
    );
  }
}
