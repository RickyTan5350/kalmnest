import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/user_grid_layout.dart';
import 'package:flutter_codelab/theme.dart'; // Ensure BrandColors or others if needed
import 'package:flutter/services.dart';
import 'package:flutter_codelab/admin_teacher/services/selection_gesture_wrapper.dart';
import 'package:flutter_codelab/admin_teacher/services/selection_box_painter.dart';
import 'user_detail_page.dart';

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

  // Selection Logic for Grid (Mock for now or fully implement if needed)
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
        // Fallback to CreatedAt if available or Name if not.
        // Assuming Name for now as UserListItem might not have Date exposed deeply
        // If you have createdAt/updatedAt in UserListItem, use it.
        // Checking UserListItem definition might be good, but safe fallback:
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return widget.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return sortedList;
  }

  // --- Selection Helpers (Grid) ---
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
        return scheme.error;
      case 'teacher':
        return scheme.tertiary;
      case 'student':
        return scheme.primary;
      default:
        return scheme.secondary;
    }
  }

  // --- Bulk Delete Logic ---
  void _deleteSelectedUsers() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Users"),
        content: Text(
          "Are you sure you want to delete ${_selectedIds.length} users? This action cannot be undone.",
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleting selected users...")),
      );

      try {
        await _userApi.deleteUsers(_selectedIds.toList());

        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully deleted ${_selectedIds.length} users"),
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
              "Error deleting users: ${e.toString().replaceAll('Exception: ', '')}",
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
                "${_selectedIds.length} Selected",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: _deleteSelectedUsers,
            tooltip: 'Delete Selected Users',
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
              child: Text("$count Results", style: textTheme.titleMedium),
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
            Text('No users found', style: textTheme.titleMedium),
          ],
        ),
      );
    }

    final sortedUsers = _sortUsers(_users);

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
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
    // Only allow selection if user is Admin
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
    // Only allow selection if user is Admin
    final bool isAdmin = widget.currentUser?.roleName.toLowerCase() == 'admin';

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final user = users[index];
          final isSelected = _selectedIds.contains(user.id);

          // Populate key for gesture detection
          final GlobalKey key = _gridItemKeys.putIfAbsent(
            user.id,
            () => GlobalKey(),
          );

          return Container(
            key: key,
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              clipBehavior: Clip.hardEdge,
              elevation: 0,
              color: isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                hoverColor: colorScheme.primary.withOpacity(0.08),
                splashColor: colorScheme.primary.withOpacity(0.12),
                mouseCursor: SystemMouseCursors.click,
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(user.roleName, colorScheme),
                  foregroundColor: colorScheme.onPrimary,
                  child: isSelected
                      ? const Icon(Icons.check)
                      : Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                        ),
                ),
                title: Text(
                  user.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(user.email, style: textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.roleName,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.accountStatus.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: user.accountStatus == 'active'
                                ? Colors.green
                                : colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                // REMOVED onLongPress as requested by User
                onTap: () {
                  if (isAdmin && _isSelectionMode) {
                    _toggleSelection(user.id);
                  } else {
                    _navigateToDetail(user.id, user.name);
                  }
                },
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
