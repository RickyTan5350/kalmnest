import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/note_api.dart';
import 'package:flutter_codelab/models/note_brief.dart';
// FIX: Imported Admin Detail Page
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_note_detail.dart';

// Import Shared Grid (Adjust path if needed)
import 'note_grid_layout_view.dart';

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
      _noteFuture = _api.searchNotes(widget.topic, widget.query);
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
        content: Text("Are you sure you want to delete ${_selectedIds.length} notes?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // await _api.deleteNotes(_selectedIds.toList()); 
      setState(() {
        _loadData(); 
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("${_selectedIds.length} notes deleted")),
        );
        _exitSelectionMode();
      });
    }
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
      return _currentSortOrder == SortOrder.ascending ? comparison : -comparison;
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
              return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: colorScheme.error)));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: colorScheme.outline),
                    const SizedBox(height: 10),
                    Text(
                      "No notes found.",
                      // FIX: 'textTheme' was undefined. Used 'theme.textTheme'.
                      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            final List<NoteBrief> rawList = snapshot.data!;
            final List<NoteBrief> sortedList = _sortNotes(rawList);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isSelectionMode
                          ? _buildSelectionHeader(context, sortedList.length)
                          : _buildSortHeader(context, sortedList.length),
                    ),
                  ),
                ),
                _buildSliverContent(context, sortedList),
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$count Results", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              DropdownButton<SortType>(
                value: _currentSortType,
                underline: const SizedBox(),
                isDense: true,
                onChanged: (SortType? newValue) {
                  if (newValue != null) setState(() => _currentSortType = newValue);
                },
                items: const [
                  DropdownMenuItem(value: SortType.alphabetical, child: Text("Name")),
                  DropdownMenuItem(value: SortType.number, child: Text("ID")),
                ],
              ),
              Container(height: 20, width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: colorScheme.outlineVariant),
              InkWell(
                onTap: () => setState(() => _currentSortOrder = _currentSortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending),
                child: Row(
                  children: [
                    Icon(_currentSortOrder == SortOrder.ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text(_currentSortOrder == SortOrder.ascending ? "Low-High" : "High-Low"),
                  ],
                ),
              ),
            ],
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
              IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
              Text("${_selectedIds.length} Selected", style: theme.textTheme.titleMedium),
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

  Widget _buildSliverContent(BuildContext context, List<NoteBrief> notes) {
    if (widget.layout == ViewLayout.grid) {
      // Use Shared Grid View
      return GridLayoutView(
        achievements: notes.map((n) => {
          'id': n.noteId,
          'title': n.title,
          'icon': Icons.article_outlined, 
          'color': Colors.blue,
          'preview': 'Tap to edit...',
        }).toList(),
        isStudent: false, // Explicitly Admin
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return _buildSelectableListTile(context, notes[index]);
            },
            childCount: notes.length,
          ),
        ),
      );
    }
  }

  Widget _buildSelectableListTile(BuildContext context, NoteBrief item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedIds.contains(item.noteId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : colorScheme.surface,
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
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => AdminNoteDetailPage(
                noteId: item.noteId, 
                noteTitle: item.title,
                isStudent: false, // Required by AdminNoteDetailPage constructor
              ),
            ));
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
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                  ),
                ),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_outlined, color: colorScheme.onPrimaryContainer),
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
                          color: colorScheme.onSurfaceVariant
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