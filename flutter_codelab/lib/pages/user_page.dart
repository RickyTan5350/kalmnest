import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_play/admin_teacher/widgets/user/user_list_content.dart';
import 'package:code_play/api/user_api.dart';
import 'package:code_play/models/user_data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:code_play/constants/view_layout.dart';
import 'package:code_play/enums/sort_enums.dart';
import 'package:code_play/services/layout_preferences.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class UserPage extends StatefulWidget {
  final UserDetails?
  currentUser; // Make it optional to avoid breaking if not passed immediately, but ideally required
  const UserPage({super.key, this.currentUser});

  @override
  State<UserPage> createState() => UserPageState();
}

final GlobalKey<UserPageState> userPageGlobalKey = GlobalKey<UserPageState>();

class UserPageState extends State<UserPage> {
  // Filter States
  final List<String> _roles = ['All', 'Student', 'Teacher', 'Admin'];
  final List<String> _statuses = ['All Status', 'Active', 'Inactive'];
  String _selectedRole = 'All';
  String _selectedStatus = 'All Status';
  String _searchQuery = '';

  // Layout & Sort States
  ViewLayout _viewLayout = LayoutPreferences.getLayoutSync(
    LayoutPreferences.globalLayoutKey,
  );
  SortType _sortType = SortType.alphabetical;
  SortOrder _sortOrder = SortOrder.ascending;

  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    _searchFocusNode.requestFocus();
  }

  Future<void> _handleRefresh() async {
    _userListKey.currentState?.refreshData();
  }

  String _getLocalizedRole(String role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role) {
      case 'All':
        return l10n.all;
      case 'Student':
        return l10n.student;
      case 'Teacher':
        return l10n.teacher;
      case 'Admin':
        return l10n.admin;
      default:
        return role;
    }
  }

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'All Status':
        return l10n.allStatus;
      case 'Active':
        return l10n.active;
      case 'Inactive':
        return l10n.inactive;
      default:
        return status;
    }
  }

  Future<void> importUsers() async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // 3. Call API
        await _userApi.importUsers(filePath, fileName);

        // 4. Success handling
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.usersImportedSuccess,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        _handleRefresh(); // Refresh list via key
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.importFailed(e.toString()),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
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
          padding: const EdgeInsets.fromLTRB(2.0, 2.0, 16.0, 16.0),
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
                        AppLocalizations.of(context)!.users,
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

                  // --- Search Bar (Left Aligned) ---
                  // --- Search Bar & Import Button ---
                  Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: SearchBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchUserHint,
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
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                          ],
                        ),
                      ),

                      // Removed Import Button from here as it's now in the main FAB menu
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
                                label: Text(_getLocalizedRole(role)),
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
                                label: Text(_getLocalizedStatus(status)),
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
                      // Refresh Icon
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
                      currentUser: widget.currentUser,
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
