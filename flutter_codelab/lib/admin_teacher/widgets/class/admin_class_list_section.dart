import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/admin_edit_class_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_view_class_page.dart';
import 'package:flutter_codelab/constants/view_layout.dart';

// Class List Item Widget with hover effect
class _ClassListItem extends StatefulWidget {
  final dynamic item;
  final bool isLast;
  final String roleName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ClassListItem({
    required this.item,
    required this.isLast,
    required this.roleName,
    required this.colorScheme,
    required this.textTheme,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_ClassListItem> createState() => _ClassListItemState();
}

class _ClassListItemState extends State<_ClassListItem> {
  bool _isHovered = false;

  // Get teacher name from item
  String get _teacherName {
    if (widget.item['teacher'] != null) {
      return widget.item['teacher']['name'] ?? 'Unknown Teacher';
    }
    return 'No teacher assigned';
  }

  // Get student count
  int get _studentCount {
    if (widget.item['students'] != null && widget.item['students'] is List) {
      return (widget.item['students'] as List).length;
    }
    return 0;
  }

  // Check if teacher is assigned
  bool get _hasTeacher {
    return widget.item['teacher'] != null &&
        widget.item['teacher']['name'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.colorScheme.surfaceVariant.withOpacity(0.6)
                    : widget.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isHovered
                      ? widget.colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Class Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: widget.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Class Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Class Name
                        Text(
                          widget.item['class_name'] ?? 'No Name',
                          style: widget.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Class Description (single line)
                        if (widget.item['description'] != null &&
                            widget.item['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              widget.item['description'],
                              style: widget.textTheme.bodySmall?.copyWith(
                                color: widget.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Teacher and Student Info Row
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            // Assigned Teacher
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: widget.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _hasTeacher ? _teacherName : 'No teacher',
                                  style: widget.textTheme.labelSmall?.copyWith(
                                    color: _hasTeacher
                                        ? widget.colorScheme.onSurfaceVariant
                                        : widget.colorScheme.error,
                                    fontStyle: _hasTeacher
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            // Enrolled Students
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 14,
                                  color: widget.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _studentCount > 0
                                      ? '$_studentCount ${_studentCount == 1 ? 'student' : 'students'}'
                                      : 'No students',
                                  style: widget.textTheme.labelSmall?.copyWith(
                                    color: _studentCount > 0
                                        ? widget.colorScheme.onSurfaceVariant
                                        : widget.colorScheme.error,
                                    fontStyle: _studentCount > 0
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit and Delete Buttons (shown on hover)
                  if (_isHovered) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: widget.onEdit,
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: widget.colorScheme.primary,
                      ),
                      tooltip: 'Edit',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      tooltip: 'Delete',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!widget.isLast)
          Divider(
            height: 1,
            color: widget.colorScheme.outlineVariant.withOpacity(0.4),
          ),
      ],
    );
  }
}

// Grid Card Widget
class _ClassGridCard extends StatelessWidget {
  final dynamic item;
  final String roleName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ClassGridCard({
    required this.item,
    required this.roleName,
    required this.colorScheme,
    required this.textTheme,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  String get _teacherName {
    if (item['teacher'] != null) {
      return item['teacher']['name'] ?? 'Unknown Teacher';
    }
    return 'No teacher assigned';
  }

  int get _studentCount {
    if (item['students'] != null && item['students'] is List) {
      return (item['students'] as List).length;
    }
    return 0;
  }

  bool get _hasTeacher {
    return item['teacher'] != null && item['teacher']['name'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and Title Row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 24,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['class_name'] ?? 'No Name',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              if (item['description'] != null &&
                  item['description'].toString().isNotEmpty)
                Text(
                  item['description'],
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              const SizedBox(height: 12),
              // Teacher and Student Info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _hasTeacher ? _teacherName : 'No teacher',
                      style: textTheme.labelSmall?.copyWith(
                        color: _hasTeacher
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.error,
                        fontStyle: _hasTeacher
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _studentCount > 0
                          ? '$_studentCount ${_studentCount == 1 ? 'student' : 'students'}'
                          : 'No students',
                      style: textTheme.labelSmall?.copyWith(
                        color: _studentCount > 0
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.error,
                        fontStyle: _studentCount > 0
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassListSection extends StatefulWidget {
  final String roleName;
  final VoidCallback? onReload;
  final String searchQuery;
  final ViewLayout layout;

  const ClassListSection({
    Key? key,
    required this.roleName,
    this.onReload,
    this.searchQuery = '',
    required this.layout,
  }) : super(key: key);

  @override
  State<ClassListSection> createState() => _ClassListSectionState();
}

class _ClassListSectionState extends State<ClassListSection> {
  bool loading = true;
  List<dynamic> classList = [];
  List<dynamic> filteredList = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  @override
  void didUpdateWidget(ClassListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if key changed (which indicates a forced reload) or search query changed
    if (widget.key != oldWidget.key ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.layout != widget.layout) {
      loadClasses();
    }
  }

  void _onEditClass(dynamic item) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditClassPage(classData: item)),
    );

    if (updated == true) {
      loadClasses(); // refresh after edit
      // Trigger statistics reload
      if (widget.onReload != null) {
        widget.onReload!();
      }
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onDeleteClass(dynamic item) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Class"),
          content: Text(
            "Are you sure you want to delete '${item['class_name']}'?",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => loading = true);

      final success = await ClassApi.deleteClass(item['class_id']);

      if (!mounted) return;

      if (success) {
        loadClasses(); // refresh list
        // Trigger statistics reload
        if (widget.onReload != null) {
          widget.onReload!();
        }
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class "${item['class_name']}" deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete class'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> loadClasses() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final allClasses = await ClassApi.fetchAllClasses();
      if (!mounted) return;

      // Apply search filter if search query is provided
      List<dynamic> filtered = allClasses;
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        filtered = allClasses.where((classItem) {
          final className = (classItem['class_name'] ?? '')
              .toString()
              .toLowerCase();
          return className.contains(query);
        }).toList();
      }

      if (mounted) {
        setState(() {
          classList = allClasses;
          filteredList = filtered;
          loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading classes: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          classList = [];
          filteredList = [];
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No classes found',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.searchQuery.isNotEmpty
                          ? 'Try adjusting your search query'
                          : 'Create a new class to get started',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : widget.layout == ViewLayout.grid
          ? CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250.0,
                          mainAxisSpacing: 12.0,
                          crossAxisSpacing: 12.0,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredList[index];
                      return _ClassGridCard(
                        item: item,
                        roleName: widget.roleName,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        onEdit: () => _onEditClass(item),
                        onDelete: () => _onDeleteClass(item),
                        onTap: () async {
                          // Block admin from viewing class details
                          if (widget.roleName.toLowerCase() == 'admin') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Admins cannot view class details',
                                ),
                                backgroundColor: colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailPage(
                                classId: item['class_id'].toString(),
                                roleName: widget.roleName,
                              ),
                            ),
                          );
                          // Reload if result is true (e.g., after edit/delete)
                          if (result == true) {
                            loadClasses();
                          }
                        },
                      );
                    }, childCount: filteredList.length),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredList[index];
                      final isLast = index == filteredList.length - 1;
                      return _ClassListItem(
                        item: item,
                        isLast: isLast,
                        roleName: widget.roleName,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        onEdit: () => _onEditClass(item),
                        onDelete: () => _onDeleteClass(item),
                        onTap: () async {
                          // Block admin from viewing class details
                          if (widget.roleName.toLowerCase() == 'admin') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Admins cannot view class details',
                                ),
                                backgroundColor: colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailPage(
                                classId: item['class_id'].toString(),
                                roleName: widget.roleName,
                              ),
                            ),
                          );
                          // Reload if result is true (e.g., after edit/delete)
                          if (result == true) {
                            loadClasses();
                          }
                        },
                      );
                    }, childCount: filteredList.length),
                  ),
                ),
              ],
            ),
    );
  }
}
