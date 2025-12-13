import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/note_api.dart';
import 'package:flutter_codelab/models/note_brief.dart';
import 'package:flutter_codelab/student/widgets/note/student_note_detail.dart';

// --- NEW IMPORTS: Reuse Admin/Teacher Widgets for consistency ---
import 'package:flutter_codelab/admin_teacher/widgets/note/note_grid_layout_view.dart';
import 'package:flutter_codelab/admin_teacher/services/selection_gesture_wrapper.dart';

// Local Enums
enum SortType { alphabetical, number }
enum SortOrder { ascending, descending }

class StudentViewPage extends StatefulWidget {
  final String topic;
  final String query;
  final bool isGrid;

  const StudentViewPage({
    super.key, 
    required this.topic, 
    required this.query,
    required this.isGrid,
  });

  @override
  State<StudentViewPage> createState() => _StudentViewPageState();
}

class _StudentViewPageState extends State<StudentViewPage> {
  late Future<List<NoteBrief>> _noteFuture;
  final NoteApi _api = NoteApi();

  SortType _currentSortType = SortType.alphabetical;
  SortOrder _currentSortOrder = SortOrder.ascending;

  // --- NEW: Keys required by GridLayoutView ---
  final Map<dynamic, GlobalKey> _gridItemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(StudentViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _noteFuture = _api.searchNotes(widget.topic, ''); 
    });
  }

  List<NoteBrief> _sortNotes(List<NoteBrief> notes) {
    List<NoteBrief> sortedList = List.from(notes);
    sortedList.sort((a, b) {
      int comparison;
      if (_currentSortType == SortType.alphabetical) {
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else {
        comparison = a.noteId.toString().compareTo(b.noteId.toString());
      }
      return _currentSortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FutureBuilder<List<NoteBrief>>(
        future: _noteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No notes found.", style: TextStyle(color: colorScheme.onSurfaceVariant)));
          }

          final List<NoteBrief> rawList = snapshot.data!;
          final filteredList = rawList.where((note) {
            return note.title.toLowerCase().contains(widget.query.toLowerCase());
          }).toList();

          if (filteredList.isEmpty) {
            return Center(child: Text("No results match '${widget.query}'", style: TextStyle(color: colorScheme.onSurfaceVariant)));
          }

          final List<NoteBrief> sortedList = _sortNotes(filteredList);

          // Prepare map for onTap lookup
          final Map<dynamic, NoteBrief> noteMap = { for (var note in sortedList) note.noteId: note };

          // --- MODIFIED: Wrap in SelectionGestureWrapper & use GridLayoutView ---
          return SelectionGestureWrapper(
            // Students don't use selection, but the wrapper is needed for layout consistency
            isDesktop: false, 
            selectedIds: const {},
            itemKeys: _gridItemKeys.map((k, v) => MapEntry(k.toString(), v)),
            onLongPressStart: (_) {}, // No-op for student
            onLongPressMoveUpdate: (_) {},
            onLongPressEnd: (_) {},
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                    child: _buildSortHeader(context, sortedList.length),
                  ),
                ),
                
                widget.isGrid
                    ? GridLayoutView(
                        achievements: sortedList.map((n) => {
                          'id': n.noteId,
                          'title': n.title,
                          'icon': Icons.description_outlined, // Consistent icon
                          'color': Colors.blue, 
                          'preview': 'Tap to read...', // Text shown in image
                        }).toList(),
                        isStudent: true, // IMPORTANT: Sets specific student interaction
                        selectedIds: const {},
                        onToggleSelection: (_) {}, 
                        itemKeys: _gridItemKeys,
                        onTap: (id) {
                           // Handle navigation here
                           if (noteMap.containsKey(id)) {
                             _openNote(context, noteMap[id]!);
                           }
                        },
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildListCard(context, sortedList[index]),
                            childCount: sortedList.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
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
              color: colorScheme.onSurface, 
            ),
          ),
          Row(
            children: [
              DropdownButton<SortType>(
                value: _currentSortType,
                underline: const SizedBox(),
                isDense: true,
                dropdownColor: colorScheme.surfaceContainer,
                style: TextStyle(color: colorScheme.onSurface), 
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
                    Icon(
                      _currentSortOrder == SortOrder.ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                      size: 16,
                      color: colorScheme.onSurface, 
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentSortOrder == SortOrder.ascending ? "Low-High" : "High-Low",
                      style: TextStyle(color: colorScheme.onSurface), 
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NOTE: _buildGridCard was deleted as it is replaced by GridLayoutView
// inside student_view_page.dart

  Widget _buildListCard(BuildContext context, NoteBrief note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      // Match Admin color (Surface) instead of SurfaceContainer
      color: colorScheme.surface, 
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _openNote(context, note),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 1. The Square Icon Container (Same as Admin)
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_outlined, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              
              // 2. Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Keep HighlightText so search still works visually
                    HighlightText(
                      text: note.title,
                      query: widget.query,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to read',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                      ),
                    ),
                  ],
                ),
              ),
              
              // 3. The Chevron Arrow (Same as Admin)
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _openNote(BuildContext context, NoteBrief note) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => StudentNoteDetailPage(
        noteId: note.noteId, 
        noteTitle: note.title,
      ),
    ));
  }
}

class HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (query.isEmpty) {
      return Text(text, style: style, maxLines: 4, overflow: TextOverflow.ellipsis);
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      final String match = text.substring(index, index + query.length);
      spans.add(TextSpan(
        text: match,
        style: highlightStyle ?? 
            style?.copyWith(
              backgroundColor: colorScheme.primaryContainer, 
              color: colorScheme.onPrimaryContainer
            ) ?? 
            TextStyle(
              backgroundColor: colorScheme.primaryContainer, 
              color: colorScheme.onPrimaryContainer, 
              fontWeight: FontWeight.bold
            ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans, style: style ?? DefaultTextStyle.of(context).style),
      overflow: TextOverflow.ellipsis,
      maxLines: 4, 
    );
  }
}