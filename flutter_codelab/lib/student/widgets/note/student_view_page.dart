import 'package:flutter/material.dart';
import 'package:code_play/api/note_api.dart';
import 'package:code_play/models/note_brief.dart';
import 'package:code_play/student/widgets/note/student_note_detail.dart';
import 'package:code_play/theme.dart'; // BrandColors

// --- NEW IMPORTS: Reuse Admin/Teacher Widgets for consistency ---
import 'package:code_play/admin_teacher/widgets/note/note_grid_layout.dart';
import 'package:code_play/admin_teacher/services/selection_gesture_wrapper.dart';

import 'package:code_play/enums/sort_enums.dart'; // Shared Enums
// Removed unused ViewLayout import

// Removing local SortType and SortOrder enums

class StudentViewPage extends StatefulWidget {
  final String topic;
  final String query;
  final bool isGrid;
  final SortType sortType;
  final SortOrder sortOrder;

  const StudentViewPage({
    super.key,
    required this.topic,
    required this.query,
    required this.isGrid,
    required this.sortType,
    required this.sortOrder,
    this.onTopicChanged,
  });

  final void Function(String)? onTopicChanged;

  @override
  State<StudentViewPage> createState() => StudentViewPageState();
}

class StudentViewPageState extends State<StudentViewPage> {
  late Future<List<NoteBrief>> _noteFuture;
  final NoteApi _api = NoteApi();

  // Removed local sort state variables

  // --- NEW: Keys required by GridLayoutView ---
  final Map<dynamic, GlobalKey> _gridItemKeys = {};

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  @override
  void didUpdateWidget(StudentViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic || oldWidget.query != widget.query) {
      refreshData();
    }
  }

  void refreshData() {
    setState(() {
      if (widget.topic.isEmpty) {
        _noteFuture = _api.fetchBriefNote();
      } else {
        _noteFuture = _api.searchNotes(widget.topic, '');
      }
    });
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: FutureBuilder<List<NoteBrief>>(
        future: _noteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No notes found.",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }

          final List<NoteBrief> rawList = snapshot.data!;
          final filteredList = rawList.where((note) {
            // Filter out private notes
            if (!note.visibility) return false;

            return note.title.toLowerCase().contains(
              widget.query.toLowerCase(),
            );
          }).toList();

          if (filteredList.isEmpty) {
            return Center(
              child: Text(
                "No results match '${widget.query}'",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }

          final List<NoteBrief> sortedList = _sortNotes(filteredList);

          // Prepare map for onTap lookup
          final Map<dynamic, NoteBrief> noteMap = {
            for (var note in sortedList) note.noteId: note,
          };

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
                    ? NoteGridLayout(
                        notes: sortedList
                            .map(
                              (n) => {
                                'id': n.noteId,
                                'title': n.title,
                                'topic': n.topic,
                                'updatedAt': n.updatedAt.toString().substring(
                                  0,
                                  16,
                                ),
                              },
                            )
                            .toList(),
                        isStudent:
                            true, // IMPORTANT: Sets specific student interaction
                        selectedIds: const {},
                        onToggleSelection: (_) {},
                        itemKeys: _gridItemKeys,
                        onTap: (id) async {
                          // Handle navigation here
                          if (noteMap.containsKey(id)) {
                            final result = await _openNote(
                              context,
                              noteMap[id]!,
                            );
                            if (result is String &&
                                widget.onTopicChanged != null) {
                              widget.onTopicChanged!(result);
                            }
                          }
                        },
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildListCard(context, sortedList[index]),
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

  // NOTE: _buildGridCard was deleted as it is replaced by GridLayoutView
  // inside student_view_page.dart

  Widget _buildListCard(BuildContext context, NoteBrief note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolve Brand Colors
    final brandColors = Theme.of(context).extension<BrandColors>();
    Color topicColor;
    IconData topicIcon;

    switch (note.topic.toLowerCase()) {
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

      // Match Admin color (Surface) instead of SurfaceContainer
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () async {
          final result = await _openNote(context, note);
          if (result is String && widget.onTopicChanged != null) {
            widget.onTopicChanged!(result);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 1. The Circle Icon (Same as Admin)
              CircleAvatar(
                backgroundColor: topicColor.withOpacity(0.1),
                foregroundColor: topicColor,
                child: Icon(topicIcon),
              ),
              const SizedBox(width: 16),

              // 2. Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightText(
                      text: note.title,
                      query: widget.query,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    const SizedBox(height: 4),
                    Text(
                      'Updated: ${note.updatedAt.toString().substring(0, 16)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> _openNote(BuildContext context, NoteBrief note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentNoteDetailPage(
          noteId: note.noteId,
          noteTitle: note.title,
          topic: widget.topic,
        ),
      ),
    );

    if (widget.onTopicChanged != null) {
      if (result == 'navigate_home') {
        widget.onTopicChanged!('All');
      } else if (result is String && result.isNotEmpty) {
        // Assume it's a topic
        widget.onTopicChanged!(result);
      }
    }
    return result;
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
      return Text(
        text,
        style: style,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      );
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
      spans.add(
        TextSpan(
          text: match,
          style:
              highlightStyle ??
              style?.copyWith(
                backgroundColor: colorScheme.primaryContainer,
                color: colorScheme.onPrimaryContainer,
              ) ??
              TextStyle(
                backgroundColor: colorScheme.primaryContainer,
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: style ?? DefaultTextStyle.of(context).style,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 4,
    );
  }
}

