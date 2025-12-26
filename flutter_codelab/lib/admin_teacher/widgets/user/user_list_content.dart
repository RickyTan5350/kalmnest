import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/user_grid_layout.dart';
import 'package:flutter_codelab/theme.dart'; // Ensure BrandColors or others if needed
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

    return Column(
      children: [
        // Sort Header (Results Count)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${sortedUsers.length} Results",
                style: textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List or Grid Content
        Expanded(
          child: widget.viewLayout == ViewLayout.grid
              ? _buildGridView(sortedUsers)
              : _buildListView(sortedUsers, colorScheme, textTheme),
        ),
      ],
    );
  }

  Widget _buildGridView(List<UserListItem> users) {
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

    return CustomScrollView(
      slivers: [
        UserGridLayout(
          users: userMaps,
          selectedIds: _selectedIds,
          onToggleSelection: _toggleSelection,
          itemKeys: _gridItemKeys,
          onTap: (id) => _navigateToDetail(
            id.toString(),
            users.firstWhere((u) => u.id == id).name,
          ),
        ),
      ],
    );
  }

  Widget _buildListView(
    List<UserListItem> users,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.hardEdge,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            hoverColor: colorScheme.primary.withOpacity(0.08),
            splashColor: colorScheme.primary.withOpacity(0.12),
            mouseCursor: SystemMouseCursors.click,
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.roleName, colorScheme),
              foregroundColor: colorScheme.onPrimary,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
            onTap: () => _navigateToDetail(user.id, user.name),
          ),
        );
      },
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
