import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/admin_edit_class_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_view_class_page.dart';

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
                          style: widget.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
                                fontSize: 12,
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
                                  style: widget.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
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
                                  style: widget.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
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

class ClassListSection extends StatefulWidget {
  final String roleName;
  final VoidCallback? onReload;
  final String searchQuery;

  const ClassListSection({
    Key? key,
    required this.roleName,
    this.onReload,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  State<ClassListSection> createState() => _ClassListSectionState();
}

class _ClassListSectionState extends State<ClassListSection> {
  int currentPage = 1;
  int totalPages = 1;
  bool loading = true;
  List<dynamic> classList = [];

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
        oldWidget.searchQuery != widget.searchQuery) {
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
      print('Loading classes - Page: $currentPage');
      final data = await ClassApi.fetchClasses(currentPage);
      if (!mounted) return;

      print('Received data: ${data.keys}');
      print('Data keys: current_page=${data['current_page']}, last_page=${data['last_page']}, total=${data['total']}');
      
      List<dynamic> allClasses = data['data'] ?? [];
      print('Classes count from API: ${allClasses.length}');

      // Apply search filter if search query is provided
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        allClasses = allClasses.where((classItem) {
          final className = (classItem['class_name'] ?? '')
              .toString()
              .toLowerCase();
          return className.contains(query);
        }).toList();
        print('Classes after search filter: ${allClasses.length}');
      }

      if (mounted) {
        setState(() {
          classList = allClasses;
          totalPages = data['last_page'] ?? 1;
          loading = false;
        });
        print('State updated - classList.length: ${classList.length}, totalPages: $totalPages');
      }
    } catch (e, stackTrace) {
      print('Error loading classes: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          classList = [];
          totalPages = 1;
          loading = false;
        });
      }
    }
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> buttons = [];
    int start = currentPage - 1;
    int end = currentPage + 1;

    if (start < 1) {
      start = 1;
      end = (totalPages >= 3) ? 3 : totalPages;
    }

    if (end > totalPages) {
      end = totalPages;
      start = (totalPages - 2 > 1) ? totalPages - 2 : 1;
    }

    for (int page = start; page <= end; page++) {
      buttons.add(_pageNumber(page));
      if (page != end) buttons.add(const SizedBox(width: 8));
    }

    return buttons;
  }

  Widget _pageNumber(int page) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = page == currentPage;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentPage = page;
          loading = true;
        });
        loadClasses();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _pageButton(IconData icon, Function() onTap) {
    return IconButton(icon: Icon(icon), onPressed: onTap);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ===== Header =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class List',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  loading ? "Loading..." : "${classList.length} entries",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          if (loading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),

          if (!loading)
            Expanded(
              child: classList.isEmpty
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: classList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isLast = index == classList.length - 1;

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
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
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
                        }).toList(),
                      ),
                    ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageButton(Icons.chevron_left, () {
                  if (currentPage > 1 && mounted) {
                    setState(() {
                      currentPage--;
                      loading = true;
                    });
                    loadClasses();
                  }
                }),
                const SizedBox(width: 8),
                ..._buildPageNumbers(),
                const SizedBox(width: 8),
                _pageButton(Icons.chevron_right, () {
                  if (currentPage < totalPages && mounted) {
                    setState(() {
                      currentPage++;
                      loading = true;
                    });
                    loadClasses();
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
