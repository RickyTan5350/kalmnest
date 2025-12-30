import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/student/widgets/class/student_view_class_page.dart';
import 'package:code_play/constants/view_layout.dart';
import 'package:code_play/constants/class_constants.dart';
import 'package:code_play/admin_teacher/widgets/class/class_customization.dart';
import 'package:code_play/enums/sort_enums.dart';

// Class List Item Widget for Student (no edit/delete buttons)
class _ClassListItem extends StatefulWidget {
  final dynamic item;
  final bool isLast;
  final String roleName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _ClassListItem({
    required this.item,
    required this.isLast,
    required this.roleName,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
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
          color: widget.colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
                leading: Builder(
                  builder: (context) {
                    final classColor = ClassCustomization.getColorByName(
                      widget.item['color'],
                    );
                    final classIcon = ClassCustomization.getIconByName(
                      widget.item['icon'],
                    );
                    return CircleAvatar(
                      backgroundColor: classColor?.color.withOpacity(0.1) ??
                          widget.colorScheme.primaryContainer,
                      foregroundColor: classColor?.color ??
                          widget.colorScheme.onPrimaryContainer,
                      child: Icon(
                        classIcon?.icon ?? Icons.school_rounded,
                        size: 20,
                      ),
                    );
                  },
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
                      ],
                    ),
                  ],
                ),
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

  const _ClassGridCard({
    required this.item,
    required this.roleName,
    required this.colorScheme,
    required this.textTheme,
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
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.3),
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
                  Builder(
                    builder: (context) {
                      final classColor = ClassCustomization.getColorByName(
                        item['color'],
                      );
                      final classIcon = ClassCustomization.getIconByName(
                        item['icon'],
                      );
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              classColor?.color.withOpacity(0.2) ??
                              colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            ClassConstants.cardBorderRadius * 0.67,
                          ),
                        ),
                        child: Icon(
                          classIcon?.icon ?? Icons.school_rounded,
                          size: 24,
                          color:
                              classColor?.color ??
                              colorScheme.onPrimaryContainer,
                        ),
                      );
                    },
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
  final String searchQuery;
  final ViewLayout layout;
  final SortType sortType;
  final SortOrder sortOrder;
  final String? iconFilter;
  final String? colorFilter;

  const ClassListSection({
    Key? key,
    required this.roleName,
    this.searchQuery = '',
    required this.layout,
    this.sortType = SortType.alphabetical,
    this.sortOrder = SortOrder.ascending,
    this.iconFilter,
    this.colorFilter,
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
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.layout != widget.layout ||
        oldWidget.sortType != widget.sortType ||
        oldWidget.sortOrder != widget.sortOrder ||
        oldWidget.iconFilter != widget.iconFilter ||
        oldWidget.colorFilter != widget.colorFilter) {
      if (oldWidget.searchQuery != widget.searchQuery ||
          oldWidget.sortType != widget.sortType ||
          oldWidget.sortOrder != widget.sortOrder ||
          oldWidget.iconFilter != widget.iconFilter ||
          oldWidget.colorFilter != widget.colorFilter) {
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

      // Apply icon filter
      if (widget.iconFilter != null) {
        filtered = filtered.where((classItem) {
          final classIcon = classItem['icon']?.toString();
          return classIcon == widget.iconFilter;
        }).toList();
      }

      // Apply color filter
      if (widget.colorFilter != null) {
        filtered = filtered.where((classItem) {
          final classColor = classItem['color']?.toString();
          return classColor == widget.colorFilter;
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

  void _applyFiltersAndSort() {
    // Apply search filter
    List<dynamic> filtered = classList;
    if (widget.searchQuery.isNotEmpty) {
      final query = widget.searchQuery.toLowerCase();
      filtered = classList.where((classItem) {
        final className = (classItem['class_name'] ?? '')
            .toString()
            .toLowerCase();
        return className.contains(query);
      }).toList();
    }

    // Apply icon filter
    if (widget.iconFilter != null) {
      filtered = filtered.where((classItem) {
        final classIcon = classItem['icon']?.toString();
        return classIcon == widget.iconFilter;
      }).toList();
    }

    // Apply color filter
    if (widget.colorFilter != null) {
      filtered = filtered.where((classItem) {
        final classColor = classItem['color']?.toString();
        return classColor == widget.colorFilter;
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
                padding: EdgeInsets.all(ClassConstants.defaultPadding * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    SizedBox(height: ClassConstants.defaultPadding),
                    Text(
                      'No classes found',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: ClassConstants.defaultPadding * 0.5),
                    Text(
                      widget.searchQuery.isNotEmpty
                          ? 'Try adjusting your search query'
                          : 'You are not enrolled in any classes yet',
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
                          padding: EdgeInsets.all(ClassConstants.defaultPadding * 0.5),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 250.0,
                              mainAxisSpacing: ClassConstants.defaultPadding * 0.75,
                              crossAxisSpacing: ClassConstants.defaultPadding * 0.75,
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
                      );
                    }, childCount: filteredList.length),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ClassConstants.defaultPadding * 0.5,
                          ),
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
                      );
                    }, childCount: filteredList.length),
                  ),
                ),
              ],
            ),
    );
  }
}

