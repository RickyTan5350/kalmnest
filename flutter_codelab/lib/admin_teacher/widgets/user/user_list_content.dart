import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'user_detail_page.dart';

class UserListContent extends StatefulWidget {
  const UserListContent({super.key});

  @override
  State<UserListContent> createState() => _UserListContentState();
}

class _UserListContentState extends State<UserListContent> {
  final UserApi _userApi = UserApi();

  // State variables
  List<UserListItem> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter States
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;
  String? _selectedStatus;

  // Filter Options
  final List<String> _roles = ['Student', 'Teacher', 'Admin'];
  final List<String> _statuses = ['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _userApi.getUsers(
        search: _searchController.text,
        roleName: _selectedRole,
        accountStatus: _selectedStatus,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to get colors based on role
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

    return Column(
      children: [
        // --- 1. M3 Search Bar ---
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search users...',
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchUsers();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchUsers,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward, color: colorScheme.primary),
                onPressed: _fetchUsers,
              ),
            ],
            onSubmitted: (_) => _fetchUsers(),
            elevation: const WidgetStatePropertyAll(1.0),
          ),
        ),

        // --- 2. M3 Filter Chips ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Filters:', style: textTheme.labelLarge),
              const SizedBox(width: 12),

              // Role Filters
              ..._roles.map((role) {
                final isSelected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedRole = selected ? role : null;
                      });
                      _fetchUsers();
                    },
                  ),
                );
              }),

              SizedBox(
                height: 24,
                child: VerticalDivider(
                  width: 24,
                  color: colorScheme.outlineVariant,
                ),
              ),

              // Status Filters
              ..._statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(status.toUpperCase()),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                      _fetchUsers();
                    },
                    avatar: isSelected
                        ? const Icon(Icons.check, size: 18)
                        : null,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),

        // --- 3. User List ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Text(
                    'Error: $_errorMessage',
                    style: TextStyle(color: colorScheme.error),
                  ),
                )
              : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text('No users found', style: textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.hardEdge,
                      elevation:
                          0, // Reduced elevation for cleaner look inside the main card
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        // --- Added Hover Effects ---
                        hoverColor: colorScheme.primary.withOpacity(0.08),
                        splashColor: colorScheme.primary.withOpacity(0.12),
                        mouseCursor: SystemMouseCursors.click,

                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(
                            user.roleName,
                            colorScheme,
                          ),
                          foregroundColor: colorScheme.onPrimary,
                          child: Text(
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
                        onTap: () async {
                          // Use await to wait for the detail page to close
                          final bool? deleted = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailPage(
                                userId: user.id,
                                userName: user.name,
                              ),
                            ),
                          );
                          // If the result is true (meaning user was deleted), refresh the list
                          if (deleted == true) {
                            _fetchUsers();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
