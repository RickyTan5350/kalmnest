import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/note_api.dart';
import 'package:flutter_codelab/models/note_brief.dart';
// FIX: Imported Admin Detail Page
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_note_detail.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/note_grid_layout.dart'; // Adjust path as needed
// Import Shared Grid (Adjust path if needed)
import 'package:flutter_codelab/admin_teacher/services/selection_gesture_wrapper.dart';
import 'package:flutter_codelab/admin_teacher/services/selection_box_painter.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_codelab/theme.dart'; // Import BrandColors

import 'note_grid_layout.dart';

enum ViewLayout { list, grid }

enum SortType { alphabetical, number }

enum SortOrder { ascending, descending }

class AdminViewNotePage extends StatefulWidget {
  final ViewLayout layout;
  final String topic;
  final String query;

  const AdminViewNotePage({
    super.key,
    required this.layout,
    required this.topic,
    required this.query,
  });

  @override
  State<AdminViewNotePage> createState() => _AdminViewNotePageState();
}

class _AdminViewNotePageState extends State<AdminViewNotePage> {
  late Future<List<NoteBrief>> _noteFuture;
  final NoteApi _api = NoteApi();

  SortType _currentSortType = SortType.alphabetical;
  SortOrder _currentSortOrder = SortOrder.ascending;
  bool _isSelectionMode = false;
  final Set<dynamic> _selectedIds = {};

  // High-performance selection State
  final Map<dynamic, GlobalKey> _gridItemKeys = {};
  final Set<dynamic> _dragProcessedIds = {};
  Offset? _dragStart;
  Offset? _dragEnd;
  Set<dynamic> _initialSelection = {};

  bool get _isDesktop {
    final p = Theme.of(context).platform;
    return p == TargetPlatform.windows ||
        p == TargetPlatform.linux ||
        p == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(AdminViewNotePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic || oldWidget.query != widget.query) {
      _loadData();
    }
  }

  void _loadData() {
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
      setState(() {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_selectedIds.length} notes deleted")),
        );
        _exitSelectionMode();
      });
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

    for (final entry in _gridItemKeys.entries) {
      final dynamic id = entry.key;
      final GlobalKey key = entry.value;

      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final Offset itemPosition = renderBox.localToGlobal(
        Offset.zero,
        ancestor: context.findRenderObject(),
      );
      final Rect itemRect = itemPosition & renderBox.size;

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
      if (_currentSortType == SortType.alphabetical) {
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else {
        comparison = a.noteId.compareTo(b.noteId);
      }
      return _currentSortOrder == SortOrder.ascending
          ? comparison
          : -comparison;
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

            return SelectionGestureWrapper(
              isDesktop: _isDesktop,
              selectedIds: _selectedIds
                  .map((e) => e.toString())
                  .toSet(), // Conv to set string if needed, or update wrapper to generic?
              // Wrapper expects Set<String>. NoteBrief ID might be int.
              // Let's check wrapper definition. Wrapper: final Set<String> selectedIds;
              // So I must cast or convert. 'NoteBrief' id is likely int.
              // Correction: specific admin_view_note handles dynamic, but wrapper expects String?
              // checking wrapper file: "final Set<String> selectedIds;"
              // So I better convert to String for the wrapper, or update the wrapper.
              // Updating the wrapper is risky if used elsewhere. Converting here is safer.
              itemKeys: _gridItemKeys.map((k, v) => MapEntry(k.toString(), v)),

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
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            12.0,
                            16.0,
                            16.0,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isSelectionMode
                                ? _buildSelectionHeader(
                                    context,
                                    sortedList.length,
                                  )
                                : _buildSortHeader(context, sortedList.length),
                          ),
                        ),
                      ),
                      _buildSliverContent(context, sortedList),
                    ],
                  ),
                  if (_isDesktop && _dragStart != null && _dragEnd != null)
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$count Results",
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              DropdownButton<SortType>(
                value: _currentSortType,
                underline: const SizedBox(),
                isDense: true,
                onChanged: (SortType? newValue) {
                  if (newValue != null)
                    setState(() => _currentSortType = newValue);
                },
                items: const [
                  DropdownMenuItem(
                    value: SortType.alphabetical,
                    child: Text("Name"),
                  ),
                  DropdownMenuItem(value: SortType.number, child: Text("ID")),
                ],
              ),
              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: colorScheme.outlineVariant,
              ),
              InkWell(
                onTap: () => setState(
                  () => _currentSortOrder =
                      _currentSortOrder == SortOrder.ascending
                      ? SortOrder.descending
                      : SortOrder.ascending,
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentSortOrder == SortOrder.ascending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentSortOrder == SortOrder.ascending
                          ? "Low-High"
                          : "High-Low",
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: () => _loadData(),
            tooltip: "Refresh List",
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
                'preview': 'Tap to edit...',
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
      case 'backend':
        topicColor = brandColors?.backend ?? Colors.purple;
        topicIcon = Icons.storage;
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
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: topicColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topicIcon, color: topicColor),
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
                    Text(
                      'Tap to edit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
