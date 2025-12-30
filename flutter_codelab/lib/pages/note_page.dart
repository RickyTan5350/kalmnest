import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_codelab/models/user_data.dart';

// 1. Import Admin View normally
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_view_note_page.dart';

// 2. Import Student View
import 'package:flutter_codelab/student/widgets/note/student_view_page.dart';
import 'package:flutter_codelab/enums/sort_enums.dart'; // Shared Enums
import 'package:flutter_codelab/constants/view_layout.dart'; // Shared ViewLayout
import 'package:flutter_codelab/services/layout_preferences.dart'; // Layout Persistence
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

class NotePage extends StatefulWidget {
  final UserDetails currentUser;

  const NotePage({super.key, required this.currentUser});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final List<String> _topics = ['All', 'HTML', 'CSS', 'JS', 'PHP'];
  String _selectedTopic = 'All';
  String _searchQuery = '';
  ViewLayout _viewLayout = LayoutPreferences.getLayoutSync(
    LayoutPreferences.globalLayoutKey,
  );
  SortType _sortType = SortType.alphabetical;
  SortOrder _sortOrder = SortOrder.ascending;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController =
      TextEditingController(); // ADDED

  final GlobalKey<StudentViewPageState> _studentKey =
      GlobalKey<StudentViewPageState>();
  final GlobalKey<AdminViewNotePageState> _adminKey =
      GlobalKey<AdminViewNotePageState>();

  @override
  void initState() {
    super.initState();
    _loadLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    final savedLayout = await LayoutPreferences.getLayout(
      LayoutPreferences.globalLayoutKey,
    );
    if (mounted) {
      setState(() {
        _viewLayout = savedLayout;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // ADDED
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    _searchFocusNode.requestFocus();
  }

  Future<void> _handleRefresh() async {
    if (widget.currentUser.isStudent) {
      _studentKey.currentState?.refreshData();
    } else {
      _adminKey.currentState?.refreshData();
    }
  }

  String _getLocalizedTopic(String topic) {
    final l10n = AppLocalizations.of(context)!;
    switch (topic) {
      case 'All':
        return l10n.all;
      default:
        return topic; // HTML, CSS, JS, PHP
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _activateSearch,
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2.0, 2.0, 16.0, 16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // FIX: Align everything to the left (Start) instead of Center
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.notes,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Row(
                        children: [
                          SegmentedButton<ViewLayout>(
                            segments: const [
                              ButtonSegment(
                                value: ViewLayout.list,
                                icon: Icon(Icons.menu),
                              ),
                              ButtonSegment(
                                value: ViewLayout.grid,
                                icon: Icon(Icons.grid_view),
                              ),
                            ],
                            selected: {_viewLayout},
                            onSelectionChanged: (val) {
                              final newLayout = val.first;
                              setState(() => _viewLayout = newLayout);
                              LayoutPreferences.saveLayout(
                                LayoutPreferences.globalLayoutKey,
                                newLayout,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Search Bar (Left Aligned due to Column crossAxis) ---
                  SizedBox(
                    width: 300,
                    child: SearchBar(
                      controller: _searchController, // ADDED
                      focusNode: _searchFocusNode,
                      hintText: AppLocalizations.of(context)!.searchNotesHint,
                      padding: const WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      leading: const Icon(
                        Icons.search,
                      ), // Optional: Adds search icon inside bar like image 2
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear(); // ADDED
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Filter Chips (Left Aligned) ---
                  // --- Filter Chips (Left Aligned) + Filter Icon (Right Aligned) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: _topics
                              .map(
                                (topic) => FilterChip(
                                  label: Text(_getLocalizedTopic(topic)),
                                  selected: _selectedTopic == topic,
                                  onSelected: (selected) {
                                    if (selected)
                                      setState(() => _selectedTopic = topic);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter Icon (Sort)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        tooltip: AppLocalizations.of(context)!.sortOptions,
                        onSelected: (value) {
                          setState(() {
                            if (value == 'Name') {
                              _sortType = SortType.alphabetical;
                            } else if (value == 'Date') {
                              _sortType = SortType.updated;
                            } else if (value == 'Ascending') {
                              _sortOrder = SortOrder.ascending;
                            } else if (value == 'Descending') {
                              _sortOrder = SortOrder.descending;
                            }
                          });
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  AppLocalizations.of(context)!.sortBy,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Name',
                                checked: _sortType == SortType.alphabetical,
                                child: Text(AppLocalizations.of(context)!.name),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Date',
                                checked: _sortType == SortType.updated,
                                child: Text(AppLocalizations.of(context)!.date),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  AppLocalizations.of(context)!.order,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Ascending',
                                checked: _sortOrder == SortOrder.ascending,
                                child: Text(
                                  AppLocalizations.of(context)!.ascending,
                                ),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Descending',
                                checked: _sortOrder == SortOrder.descending,
                                child: Text(
                                  AppLocalizations.of(context)!.descending,
                                ),
                              ),
                            ],
                      ),
                      const SizedBox(width: 4),
                      // Refresh Icon (Right of Sort)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _handleRefresh,
                        tooltip: AppLocalizations.of(context)!.refreshList,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Body ---
                  Expanded(
                    child: widget.currentUser.isStudent
                        ? StudentViewPage(
                            key: _studentKey,
                            topic: _selectedTopic == 'All'
                                ? ''
                                : _selectedTopic,
                            query: _searchQuery,
                            isGrid: _viewLayout == ViewLayout.grid,
                            sortType: _sortType,
                            sortOrder: _sortOrder,
                          )
                        : AdminViewNotePage(
                            key: _adminKey,
                            layout: _viewLayout,
                            topic: _selectedTopic == 'All'
                                ? ''
                                : _selectedTopic,
                            query: _searchQuery,
                            sortType: _sortType,
                            sortOrder: _sortOrder,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
