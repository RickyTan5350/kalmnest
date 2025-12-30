import 'package:flutter/material.dart';
import 'package:code_play/api/note_api.dart';
import 'package:code_play/models/note_brief.dart';
// FIX: Imported Admin Detail Page
import 'package:code_play/admin_teacher/widgets/note/admin_note_detail.dart';
import 'package:code_play/admin_teacher/widgets/note/note_grid_layout.dart'; // Adjust path as needed
// Import Shared Grid (Adjust path if needed)
import 'package:code_play/admin_teacher/services/selection_gesture_wrapper.dart';
import 'package:code_play/admin_teacher/services/selection_box_painter.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:code_play/theme.dart'; // Import BrandColors

import 'package:code_play/enums/sort_enums.dart';
import 'package:code_play/constants/view_layout.dart';

class AdminViewNotePage extends StatefulWidget {
  final ViewLayout layout;
  final String topic;
  final String query;
  final SortType sortType;
  final SortOrder sortOrder;

  const AdminViewNotePage({
    super.key,
    required this.layout,
    required this.topic,
    required this.query,
    required this.sortType,
    required this.sortOrder,
  });

  @override
  State<AdminViewNotePage> createState() => AdminViewNotePageState();
}

class AdminViewNotePageState extends State<AdminViewNotePage> {
  late Future<List<NoteBrief>> _noteFuture;
  final NoteApi _api = NoteApi();

  // Removed local sort state
  bool _isSelectionMode = false;
  final Set<dynamic> _selectedIds = {};

  // High-performance selection State
  final Map<dynamic, GlobalKey> _gridItemKeys = {};
  final Set<dynamic> _dragProcessedIds = {};
  Offset? _dragStart;
  Offset? _dragEnd;
  Set<dynamic> _initialSelection = {};
  final GlobalKey _selectionAreaKey = GlobalKey();

  bool get _isDesktop {
    final p = Theme.of(context).platform;
    return p == TargetPlatform.windows ||
        p == TargetPlatform.linux ||
        p == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  @override
  void didUpdateWidget(AdminViewNotePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if query or topic changes
    if (oldWidget.topic != widget.topic || oldWidget.query != widget.query) {
      refreshData();
    }
  }

  void refreshData() {
    setState(() {
      if (widget.topic.isEmpty && widget.query.isEmpty) {
        _noteFuture = _api.fetchBriefNote();
      } else {
        _noteFuture = _api.searchNotes(widget.topic, widget.query);
      }
      _exitSelectionMode();
    });
  }

  // --- Selection Logic ---
  void _enterSelectionMode(dynamic noteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(noteId);
    });
  }

  void _toggleSelection(dynamic noteId) {
    setState(() {
      if (_selectedIds.contains(noteId)) {
        _selectedIds.remove(noteId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(noteId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteSelectedNotes() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Notes"),
        content: Text(
          "Are you sure you want to delete ${_selectedIds.length} notes?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _api.deleteNotes(_selectedIds.toList());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_selectedIds.length} notes deleted")),
      ); // Show message while deleting

      refreshData(); // Reload list
      // Exit selection mode after deletion
      _exitSelectionMode();
    }
  }

  // --- HYBRID SELECTION LOGIC ---

  void _handleDragSelect(Offset position) {
    if (!_isSelectionMode) {
      setState(() => _isSelectionMode = true);
    }
    for (final entry in _gridItemKeys.entries) {
      final dynamic id = entry.key;
      final GlobalKey key = entry.value;

      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(position);
        if (renderBox.size.contains(localPosition)) {
          if (!_dragProcessedIds.contains(id)) {
            _toggleSelection(id);
            _dragProcessedIds.add(id);
            HapticFeedback.selectionClick();
          }
        }
      }
    }
  }

  void _handleBoxSelect(Offset currentPosition) {
    setState(() {
      _dragEnd = currentPosition;
      if (!_isSelectionMode) _isSelectionMode = true;
    });

    if (_dragStart == null) return;

    final Rect selectionBox = Rect.fromPoints(_dragStart!, _dragEnd!);
    final Set<dynamic> newSelection = Set.from(_initialSelection);

    // Get the selection area (Stack) render object
    final RenderBox? ancestor =
        _selectionAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (ancestor == null) return;

    for (final entry in _gridItemKeys.entries) {
      final dynamic id = entry.key;
      final GlobalKey key = entry.value;

      final RenderBox? itemBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null) continue;

      final Offset itemPosition = itemBox.localToGlobal(
        Offset.zero,
        ancestor: ancestor,
      );
      final Rect itemRect = itemPosition & itemBox.size;

      if (selectionBox.overlaps(itemRect)) {
        newSelection.add(id);
      } else if (!_initialSelection.contains(id)) {
        newSelection.remove(id);
      }
    }

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
    _dragProcessedIds.clear();
  }

  List<NoteBrief> _sortNotes(List<NoteBrief> notes) {
    List<NoteBrief> sortedList = List.from(notes);
    sortedList.sort((a, b) {
      int comparison;
      if (widget.sortType == SortType.alphabetical) {
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else {
        // SortType.updated
        comparison = a.updatedAt.compareTo(b.updatedAt);
      }
      return widget.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        body: FutureBuilder<List<NoteBrief>>(
          future: _noteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "No notes found.",
                      // FIX: 'textTheme' was undefined. Used 'theme.textTheme'.
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final List<NoteBrief> rawList = snapshot.data!;
            final List<NoteBrief> sortedList = _sortNotes(rawList);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- STICKY HEADER ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSelectionMode
                        ? _buildSelectionHeader(context, sortedList.length)
                        : _buildSortHeader(context, sortedList.length),
                  ),
                ),

                // --- SCROLLABLE CONTENT ---
                Expanded(
                  child: SelectionGestureWrapper(
                    isDesktop: _isDesktop,
                    selectedIds: _selectedIds.map((e) => e.toString()).toSet(),
                    itemKeys: _gridItemKeys.map(
                      (k, v) => MapEntry(k.toString(), v),
                    ),

                    onLongPressStart: (details) {
                      if (_isDesktop) {
                        _initialSelection = Set.from(_selectedIds);
                        setState(() {
                          _dragStart = details.localPosition;
                          _dragEnd = details.localPosition;
                        });
                        _handleBoxSelect(details.localPosition);
                      } else {
                        _dragProcessedIds.clear();
                        _handleDragSelect(details.globalPosition);
                      }
                    },
                    onLongPressMoveUpdate: (details) {
                      if (_isDesktop) {
                        _handleBoxSelect(details.localPosition);
                      } else {
                        _handleDragSelect(details.globalPosition);
                      }
                    },
                    onLongPressEnd: (_) => _endDrag(),

                    child: Stack(
                      key: _selectionAreaKey,
                      children: [
                        CustomScrollView(
                          slivers: [_buildSliverContent(context, sortedList)],
                        ),
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
    );
  }

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
          // Match the height of IconButton (40) from SelectionHeader
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
                onPressed: _exitSelectionMode,
              ),
              Text(
                "${_selectedIds.length} Selected",
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: _deleteSelectedNotes,
          ),
        ],
      ),
    );
  }

  // --- CONTENT BUILDERS ---

  // In admin_view_note_page.dart

  Widget _buildSliverContent(BuildContext context, List<NoteBrief> notes) {
    if (widget.layout == ViewLayout.grid) {
      // 1. Create a map for fast lookup (Optimization)
      final noteMap = {for (var n in notes) n.noteId: n};

      return NoteGridLayout(
        notes: notes
            .map(
              (n) => {
                'id': n.noteId,
                'title': n.title,
                'topic': n.topic,
                'updatedAt': n.updatedAt.toString().substring(0, 16),
              },
            )
            .toList(),
        isStudent: false,
        selectedIds: _selectedIds,
        onToggleSelection: _toggleSelection,
        itemKeys: _gridItemKeys,

        // 2. ADD THIS: Handle the tap event for Admin
        onTap: (id) {
          final note = noteMap[id];
          if (note != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminNoteDetailPage(
                  noteId: note.noteId,
                  noteTitle: note.title,
                  isStudent: false,
                ),
              ),
            );
          }
        },
      );
    } else {
      // List View logic remains the same...
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final note = notes[index];
            final GlobalKey key = _gridItemKeys.putIfAbsent(
              note.noteId,
              () => GlobalKey(),
            );
            return Container(
              key: key,
              child: _buildSelectableListTile(context, note),
            );
          }, childCount: notes.length),
        ),
      );
    }
  }

  Widget _buildSelectableListTile(BuildContext context, NoteBrief item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedIds.contains(item.noteId);

    // Resolve Brand Colors
    final brandColors = Theme.of(context).extension<BrandColors>();
    Color topicColor;
    IconData topicIcon;

    switch (item.topic.toLowerCase()) {
      case 'html':
        topicColor = brandColors?.html ?? Colors.orange;
        topicIcon = Icons.html;
        break;
      case 'css':
        topicColor = brandColors?.css ?? Colors.blue;
        topicIcon = Icons.css;
        break;
      case 'js':
      case 'javascript':
        topicColor = brandColors?.javascript ?? Colors.yellow;
        topicIcon = Icons.javascript;
        break;
      case 'php':
        topicColor = brandColors?.php ?? Colors.indigo;
        topicIcon = Icons.php;
        break;

      default:
        topicColor = brandColors?.other ?? Colors.grey;
        topicIcon = Icons.folder_open;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: isSelected
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onLongPress: () => _enterSelectionMode(item.noteId),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(item.noteId);
          } else {
            // FIX: Use AdminNoteDetailPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminNoteDetailPage(
                  noteId: item.noteId,
                  noteTitle: item.title,
                  isStudent:
                      false, // Required by AdminNoteDetailPage constructor
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Checkbox removed as per request to rely on background selection only
              CircleAvatar(
                backgroundColor: topicColor.withOpacity(0.1),
                foregroundColor: topicColor,
                child: Icon(topicIcon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    const SizedBox(height: 4),
                    Text(
                      'Updated: ${item.updatedAt.toString().substring(0, 16)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode)
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

