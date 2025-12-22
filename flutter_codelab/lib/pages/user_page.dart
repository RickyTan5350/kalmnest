import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/user_list_content.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';
import 'package:flutter_codelab/services/layout_preferences.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // Filter States
  final List<String> _roles = ['All', 'Student', 'Teacher', 'Admin'];
  final List<String> _statuses = ['All Status', 'Active', 'Inactive'];
  String _selectedRole = 'All';
  String _selectedStatus = 'All Status';
  String _searchQuery = '';

  // Layout & Sort States
  ViewLayout _viewLayout = ViewLayout.grid;
  SortType _sortType = SortType.alphabetical;
  SortOrder _sortOrder = SortOrder.ascending;

  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<UserListContentState> _userListKey =
      GlobalKey<UserListContentState>();
  final UserApi _userApi = UserApi();

  @override
  void initState() {
    super.initState();
    _loadLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    final savedLayout = await LayoutPreferences.getLayout('user_layout');
    if (mounted) {
      setState(() {
        _viewLayout = savedLayout;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    _searchFocusNode.requestFocus();
  }

  Future<void> _handleRefresh() async {
    _userListKey.currentState?.refreshData();
  }

  Future<void> _importUsers() async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        // 2. Show loading
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Importing users...'),
            duration: Duration(days: 1), // Indefinite until dismissed
          ),
        );

        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // 3. Call API
        await _userApi.importUsers(filePath, fileName);

        // 4. Success handling
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Users imported successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _handleRefresh(); // Refresh list via key
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import Failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive layout if needed
    // final width = MediaQuery.of(context).size.width;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _activateSearch,
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Users",
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
                                'user_layout',
                                newLayout,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Search Bar (Left Aligned) ---
                  // --- Search Bar & Import Button ---
                  Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: SearchBar(
                          focusNode: _searchFocusNode,
                          hintText: "Search user...",
                          padding: const WidgetStatePropertyAll<EdgeInsets>(
                            EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          leading: const Icon(Icons.search),
                          trailing: [
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _importUsers,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import Users'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Filter Chips & Sort Controls ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: [
                            ..._roles.map((role) {
                              return FilterChip(
                                label: Text(role),
                                selected: _selectedRole == role,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedRole = role);
                                  }
                                },
                              );
                            }),
                            // Vertical Divider between Roles and Status
                            SizedBox(
                              height: 32,
                              child: VerticalDivider(
                                width: 24,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            ..._statuses.map((status) {
                              return FilterChip(
                                label: Text(status),
                                selected: _selectedStatus == status,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedStatus = status);
                                  }
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sort Menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Sort Options',
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
                              const PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  'Sort By',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Name',
                                checked: _sortType == SortType.alphabetical,
                                child: const Text('Name'),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Date',
                                checked: _sortType == SortType.updated,
                                child: const Text('Date'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  'Order',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Ascending',
                                checked: _sortOrder == SortOrder.ascending,
                                child: const Text('Ascending'),
                              ),
                              CheckedPopupMenuItem<String>(
                                value: 'Descending',
                                checked: _sortOrder == SortOrder.descending,
                                child: const Text('Descending'),
                              ),
                            ],
                      ),
                      const SizedBox(width: 4),
                      // Refresh Icon
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _handleRefresh,
                        tooltip: "Refresh List",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Body ---
                  Expanded(
                    child: UserListContent(
                      key: _userListKey,
                      searchQuery: _searchQuery,
                      selectedRole: _selectedRole == 'All'
                          ? null
                          : _selectedRole,
                      selectedStatus: _selectedStatus == 'All Status'
                          ? null
                          : _selectedStatus
                                .toLowerCase(), // API expects lowercase
                      viewLayout: _viewLayout,
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
