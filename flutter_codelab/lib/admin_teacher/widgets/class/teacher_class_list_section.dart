import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_view_class_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/admin_edit_class_page.dart';
import 'package:flutter_codelab/constants/view_layout.dart';
import 'package:flutter_codelab/constants/class_constants.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

// Class List Item Widget
class _ClassListItem extends StatefulWidget {
  final dynamic item;
  final bool isLast;
  final String roleName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ClassListItem({
    required this.item,
    required this.isLast,
    required this.roleName,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_ClassListItem> createState() => _ClassListItemState();
}

class _ClassListItemState extends State<_ClassListItem> {
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: widget.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.colorScheme.primaryContainer,
          foregroundColor: widget.colorScheme.onPrimaryContainer,
          child: Icon(Icons.school_rounded, size: 20),
        ),
        title: Text(
          widget.item['class_name'] ?? 'No Name',
          style: widget.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: widget.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.item['description'] != null &&
                widget.item['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  widget.item['description'],
                  style: widget.textTheme.bodySmall?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
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
                // Focus display
                if (widget.item['focus'] != null &&
                    widget.item['focus'].toString().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getAchievementIcon(
                          widget.item['focus'].toString().toLowerCase(),
                        ),
                        size: 14,
                        color: getAchievementColor(
                          context,
                          widget.item['focus'].toString().toLowerCase(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.item['focus'].toString(),
                        style: widget.textTheme.labelSmall?.copyWith(
                          color: getAchievementColor(
                            context,
                            widget.item['focus'].toString().toLowerCase(),
                          ),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        trailing: widget.roleName.toLowerCase() == 'admin'
            ? PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: widget.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit' && widget.onEdit != null) {
                    widget.onEdit!();
                  } else if (value == 'delete' && widget.onDelete != null) {
                    widget.onDelete!();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: widget.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
                          ],
                        );
                      },
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: widget.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.delete,
                              style: TextStyle(color: widget.colorScheme.error),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              )
            : null,
        onTap: widget.onTap,
      ),
    );
  }
}

// Grid Card Widget
class _ClassGridCard extends StatelessWidget {
  final dynamic item;
  final String roleName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ClassGridCard({
    required this.item,
    required this.roleName,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.onEdit,
    this.onDelete,
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
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(ClassConstants.defaultPadding),
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
                      borderRadius: BorderRadius.circular(
                        ClassConstants.cardBorderRadius * 0.67,
                      ),
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
                  if (roleName.toLowerCase() == 'admin')
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        final l10n = AppLocalizations.of(context)!;
                        return [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(l10n.edit),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.delete,
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                ],
              ),
              SizedBox(height: ClassConstants.defaultPadding * 0.75),
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
              SizedBox(height: ClassConstants.defaultPadding * 0.75),
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
              // Focus display
              if (item['focus'] != null &&
                  item['focus'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      getAchievementIcon(
                        item['focus'].toString().toLowerCase(),
                      ),
                      size: 14,
                      color: getAchievementColor(
                        context,
                        item['focus'].toString().toLowerCase(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['focus'].toString(),
                        style: textTheme.labelSmall?.copyWith(
                          color: getAchievementColor(
                            context,
                            item['focus'].toString().toLowerCase(),
                          ),
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ClassListSection extends StatefulWidget {
  final String roleName;
  final String searchQuery;
  final ViewLayout layout;
  final SortType sortType;
  final SortOrder sortOrder;
  final VoidCallback? onReload;
  final String ownerFilter; // 'all' or 'created_by_me'
  final String? focusFilter; // null, 'HTML', 'CSS', 'JavaScript', 'PHP'
  final String currentUserId; // Current user's ID for filtering

  const ClassListSection({
    super.key,
    required this.roleName,
    this.searchQuery = '',
    required this.layout,
    this.sortType = SortType.alphabetical,
    this.sortOrder = SortOrder.ascending,
    this.onReload,
    this.ownerFilter = 'all',
    this.focusFilter,
    this.currentUserId = '',
  });

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
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.layout != widget.layout ||
        oldWidget.sortType != widget.sortType ||
        oldWidget.sortOrder != widget.sortOrder ||
        oldWidget.ownerFilter != widget.ownerFilter ||
        oldWidget.focusFilter != widget.focusFilter) {
      if (oldWidget.searchQuery != widget.searchQuery ||
          oldWidget.sortType != widget.sortType ||
          oldWidget.sortOrder != widget.sortOrder ||
          oldWidget.ownerFilter != widget.ownerFilter ||
          oldWidget.focusFilter != widget.focusFilter) {
        // Just re-filter and sort, don't reload from API
        _applyFiltersAndSort();
      } else {
        loadClasses();
      }
    }
  }

  Future<void> loadClasses() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final allClasses = await ClassApi.fetchAllClasses();
      if (!mounted) return;

      // Apply filters
      List<dynamic> filtered = allClasses;

      // Apply owner filter (created by me)
      if (widget.ownerFilter == 'created_by_me' &&
          widget.currentUserId.isNotEmpty) {
        final role = widget.roleName.toLowerCase();
        if (role == 'admin') {
          // For admin: filter by admin_id
          filtered = filtered.where((classItem) {
            final adminId = classItem['admin_id']?.toString() ?? '';
            return adminId == widget.currentUserId;
          }).toList();
        } else if (role == 'teacher') {
          // For teacher: filter by teacher_id
          filtered = filtered.where((classItem) {
            final teacherId = classItem['teacher_id']?.toString() ?? '';
            return teacherId == widget.currentUserId;
          }).toList();
        }
      }

      // Apply focus filter
      if (widget.focusFilter != null && widget.focusFilter!.isNotEmpty) {
        filtered = filtered.where((classItem) {
          final focus = classItem['focus']?.toString();
          return focus == widget.focusFilter;
        }).toList();
      }

      // Apply search filter if search query is provided
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        filtered = filtered.where((classItem) {
          final className = (classItem['class_name'] ?? '')
              .toString()
              .toLowerCase();
          return className.contains(query);
        }).toList();
      }

      // Apply sorting
      filtered = _sortClasses(filtered);

      if (mounted) {
        setState(() {
          classList = allClasses;
          filteredList = filtered;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          classList = [];
          filteredList = [];
          loading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    // Apply filters
    List<dynamic> filtered = classList;

    // Apply owner filter (created by me)
    if (widget.ownerFilter == 'created_by_me' &&
        widget.currentUserId.isNotEmpty) {
      final role = widget.roleName.toLowerCase();
      if (role == 'admin') {
        // For admin: filter by admin_id
        filtered = filtered.where((classItem) {
          final adminId = classItem['admin_id']?.toString() ?? '';
          return adminId == widget.currentUserId;
        }).toList();
      } else if (role == 'teacher') {
        // For teacher: filter by teacher_id
        filtered = filtered.where((classItem) {
          final teacherId = classItem['teacher_id']?.toString() ?? '';
          return teacherId == widget.currentUserId;
        }).toList();
      }
    }

    // Apply focus filter
    if (widget.focusFilter != null && widget.focusFilter!.isNotEmpty) {
      filtered = filtered.where((classItem) {
        final focus = classItem['focus']?.toString();
        return focus == widget.focusFilter;
      }).toList();
    }

    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      final query = widget.searchQuery.toLowerCase();
      filtered = filtered.where((classItem) {
        final className = (classItem['class_name'] ?? '')
            .toString()
            .toLowerCase();
        return className.contains(query);
      }).toList();
    }

    // Apply sorting
    filtered = _sortClasses(filtered);

    if (mounted) {
      setState(() {
        filteredList = filtered;
      });
    }
  }

  List<dynamic> _sortClasses(List<dynamic> classes) {
    final sortedList = List<dynamic>.from(classes);
    sortedList.sort((a, b) {
      int result = 0;
      switch (widget.sortType) {
        case SortType.alphabetical:
          final nameA = (a['class_name'] ?? '').toString().toLowerCase();
          final nameB = (b['class_name'] ?? '').toString().toLowerCase();
          result = nameA.compareTo(nameB);
          break;
        case SortType.updated:
          final dateA = a['created_at'] != null
              ? DateTime.tryParse(a['created_at'].toString()) ?? DateTime(0)
              : DateTime(0);
          final dateB = b['created_at'] != null
              ? DateTime.tryParse(b['created_at'].toString()) ?? DateTime(0)
              : DateTime(0);
          result = dateA.compareTo(dateB);
          break;
        case SortType.unlocked:
          // Classes don't have unlocked status, fallback to alphabetical
          final nameA = (a['class_name'] ?? '').toString().toLowerCase();
          final nameB = (b['class_name'] ?? '').toString().toLowerCase();
          result = nameA.compareTo(nameB);
          break;
      }
      if (widget.sortOrder == SortOrder.descending) {
        result = -result;
      }
      return result;
    });
    return sortedList;
  }

  void _onEditClass(dynamic item) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditClassPage(classData: item)),
    );

    if (updated == true) {
      loadClasses(); // refresh after edit
      // Trigger reload callback if provided
      if (widget.onReload != null) {
        widget.onReload!();
      }
      // Note: Success message is already shown in EditClassPage, so we don't show it here to avoid duplicate
    }
  }

  void _onDeleteClass(dynamic item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteClass),
          content: Text(l10n.deleteClassConfirmation(item['class_name'] ?? '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await ClassApi.deleteClass(item['class_id'].toString());
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.classDeletedSuccessfully),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          loadClasses(); // refresh after delete
          // Trigger reload callback if provided
          if (widget.onReload != null) {
            widget.onReload!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToUpdateClass),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noClassesFound,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.searchQuery.isNotEmpty
                          ? l10n.tryAdjustingSearchQuery
                          : l10n.notEnrolledInAnyClasses,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                                l10n.resultsCount(filteredList.length),
                                style: textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailPage(
                                classId: item['class_id'].toString(),
                                roleName: widget.roleName,
                              ),
                            ),
                          );
                        },
                        onEdit: widget.roleName.toLowerCase() == 'admin'
                            ? () => _onEditClass(item)
                            : null,
                        onDelete: widget.roleName.toLowerCase() == 'admin'
                            ? () => _onDeleteClass(item)
                            : null,
                      );
                    }, childCount: filteredList.length),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                                l10n.resultsCount(filteredList.length),
                                style: textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailPage(
                                classId: item['class_id'].toString(),
                                roleName: widget.roleName,
                              ),
                            ),
                          );
                        },
                        onEdit: widget.roleName.toLowerCase() == 'admin'
                            ? () => _onEditClass(item)
                            : null,
                        onDelete: widget.roleName.toLowerCase() == 'admin'
                            ? () => _onDeleteClass(item)
                            : null,
                      );
                    }, childCount: filteredList.length),
                  ),
                ),
              ],
            ),
    );
  }
}
