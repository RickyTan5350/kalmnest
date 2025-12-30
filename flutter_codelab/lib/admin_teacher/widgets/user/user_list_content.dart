import 'package:flutter/material.dart';
import 'package:code_play/api/user_api.dart';
import 'package:code_play/models/user_data.dart';
import 'package:code_play/constants/view_layout.dart';
import 'package:code_play/enums/sort_enums.dart';
import 'package:code_play/admin_teacher/widgets/user/user_grid_layout.dart';
import 'package:flutter/services.dart';
import 'package:code_play/admin_teacher/services/selection_gesture_wrapper.dart';
import 'package:code_play/widgets/user_avatar.dart';
import 'package:code_play/admin_teacher/services/selection_box_painter.dart';
import 'user_detail_page.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class UserListContent extends StatefulWidget {
  final String searchQuery;
  final String? selectedRole;
  final String? selectedStatus;
  final ViewLayout viewLayout;
  final SortType sortType;
  final SortOrder sortOrder;
  final UserDetails? currentUser;

  const UserListContent({
    super.key,
    required this.searchQuery,
    required this.selectedRole,
    required this.selectedStatus,
    required this.viewLayout,
    required this.sortType,
    required this.sortOrder,
    this.currentUser,
  });

  @override
  State<UserListContent> createState() => UserListContentState();
}

class UserListContentState extends State<UserListContent> {
  final UserApi _userApi = UserApi();

  // State variables
  List<UserListItem> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selection Logic
  bool _isSelectionMode = false;
  final Set<dynamic> _selectedIds = {};
  final Map<dynamic, GlobalKey> _gridItemKeys = {};

  // --- Selection State (Hybrid) ---
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

  // --- Drag Selection Handlers ---
  void _handleDragSelect(Offset position) {
    if ((widget.currentUser?.roleName.toLowerCase() ?? '') != 'admin') return;

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
    if ((widget.currentUser?.roleName.toLowerCase() ?? '') != 'admin') return;

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

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void didUpdateWidget(UserListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.selectedRole != widget.selectedRole ||
        oldWidget.selectedStatus != widget.selectedStatus) {
      _fetchUsers();
    }
  }

  Future<void> refreshData() async {
    await _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _userApi.getUsers(
        search: widget.searchQuery,
        roleName: widget.selectedRole,
        accountStatus: widget.selectedStatus,
      );
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // --- Sorting ---
  List<UserListItem> _sortUsers(List<UserListItem> users) {
    List<UserListItem> sortedList = List.from(users);
    sortedList.sort((a, b) {
      int comparison;
      if (widget.sortType == SortType.alphabetical) {
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return widget.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return sortedList;
  }

  // --- Selection Helpers ---
  void _toggleSelection(dynamic id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  Color _getRoleColor(String role, ColorScheme scheme) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.pink;
      case 'teacher':
        return Colors.orange;
      case 'student':
        return Colors.blue;
      default:
        return scheme.secondary;
    }
  }

  String _getLocalizedRole(String role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role.toLowerCase()) {
      case 'student':
        return l10n.student;
      case 'teacher':
        return l10n.teacher;
      case 'admin':
        return l10n.admin;
      default:
        return role;
    }
  }

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'active':
        return l10n.active;
      case 'inactive':
        return l10n.inactive;
      default:
        return status;
    }
  }

  // --- Bulk Delete Logic ---
  void _deleteSelectedUsers() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteUsers),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteUsersConfirmation(_selectedIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deletingUsers)),
      );

      try {
        await _userApi.deleteUsers(_selectedIds.toList());

        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.deletedUsersSuccess(_selectedIds.length),
            ),
            backgroundColor: Colors.green,
          ),
        );

        _selectedIds.clear();
        _isSelectionMode = false;
        refreshData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.errorDeletingUsers(e.toString().replaceAll('Exception: ', '')),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  // --- Header Widgets ---
  Widget _buildSelectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(
                  context,
                )!.selectedCount(_selectedIds.length),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: _deleteSelectedUsers,
            tooltip: AppLocalizations.of(context)!.deleteSelectedUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildSortHeader(
    BuildContext context,
    int count,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
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
              child: Text(
                AppLocalizations.of(context)!.resultsCount(count),
                style: textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Error: $_errorMessage',
          style: TextStyle(color: colorScheme.error),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noUsersFound,
              style: textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final sortedUsers = _sortUsers(_users);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: SelectionGestureWrapper(
        isDesktop: _isDesktop,
        selectedIds: _selectedIds.map((e) => e.toString()).toSet(),
        itemKeys: _gridItemKeys.map((k, v) => MapEntry(k.toString(), v)),
        onLongPressStart: (details) {
          if ((widget.currentUser?.roleName.toLowerCase() ?? '') != 'admin')
            return;

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
          if ((widget.currentUser?.roleName.toLowerCase() ?? '') != 'admin')
            return;

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
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isSelectionMode
                          ? _buildSelectionHeader(context)
                          : _buildSortHeader(
                              context,
                              sortedUsers.length,
                              textTheme,
                              colorScheme,
                            ),
                    ),
                  ),
                ),
                widget.viewLayout == ViewLayout.grid
                    ? _buildSliverGrid(sortedUsers)
                    : _buildSliverList(sortedUsers, colorScheme, textTheme),
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
      ),
    );
  }

  Widget _buildSliverGrid(List<UserListItem> users) {
    final bool isAdmin = widget.currentUser?.roleName.toLowerCase() == 'admin';

    final userMaps = users
        .map(
          (u) => {
            'id': u.id,
            'name': u.name,
            'email': u.email,
            'role': u.roleName,
            'status': u.accountStatus,
          },
        )
        .toList();

    return UserGridLayout(
      users: userMaps,
      selectedIds: _selectedIds,
      onToggleSelection: isAdmin ? _toggleSelection : (id) {},
      itemKeys: _gridItemKeys,
      onTap: (id) {
        if (isAdmin && _isSelectionMode) {
          _toggleSelection(id);
        } else {
          _navigateToDetail(
            id.toString(),
            users.firstWhere((u) => u.id == id).name,
          );
        }
      },
    );
  }

  Widget _buildSliverList(
    List<UserListItem> users,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final bool isAdmin = widget.currentUser?.roleName.toLowerCase() == 'admin';

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final user = users[index];
          final isSelected = _selectedIds.contains(user.id);

          final GlobalKey key = _gridItemKeys.putIfAbsent(
            user.id,
            () => GlobalKey(),
          );

          return Container(
            key: key,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.3),
                  width: isSelected ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: UserAvatar(
                  name: user.name,
                  role: user.roleName,
                  size: 42,
                  fontSize: 16,
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
                subtitle: Text(user.email, style: textTheme.bodySmall),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(
                          user.roleName,
                          colorScheme,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getLocalizedRole(user.roleName),
                        style: textTheme.labelSmall?.copyWith(
                          color: _getRoleColor(user.roleName, colorScheme),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (user.accountStatus == 'active'
                                    ? Colors.green
                                    : colorScheme.error)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getLocalizedStatus(user.accountStatus).toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: user.accountStatus == 'active'
                              ? Colors.green
                              : colorScheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (isAdmin && _isSelectionMode) {
                    _toggleSelection(user.id);
                  } else {
                    _navigateToDetail(user.id.toString(), user.name);
                  }
                },
                onLongPress: isAdmin ? () => _toggleSelection(user.id) : null,
              ),
            ),
          );
        }, childCount: users.length),
      ),
    );
  }

  Future<void> _navigateToDetail(String userId, String userName) async {
    final bool isSelf = widget.currentUser?.id == userId;
    final bool? deleted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailPage(
          userId: userId,
          userName: userName,
          viewerRole: widget.currentUser?.roleName ?? 'Student',
          isSelfProfile: isSelf,
        ),
      ),
    );
    if (deleted == true) {
      _fetchUsers();
    }
  }
}
