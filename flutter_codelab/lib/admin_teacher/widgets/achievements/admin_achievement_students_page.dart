import 'package:flutter/material.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:intl/intl.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import '../user/user_detail_page.dart';

class AdminAchievementStudentsPage extends StatefulWidget {
  final String achievementId;
  final String achievementName;
  final String? excludedStudentId;
  final List<BreadcrumbItem>? breadcrumbs;

  const AdminAchievementStudentsPage({
    super.key,
    required this.achievementId,
    required this.achievementName,
    this.excludedStudentId,
    this.breadcrumbs,
  });

  @override
  State<AdminAchievementStudentsPage> createState() =>
      _AdminAchievementStudentsPageState();
}

class _AdminAchievementStudentsPageState
    extends State<AdminAchievementStudentsPage> {
  final AchievementApi _api = AchievementApi();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String? _errorMessage;

  // Search and Filter State
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClassFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final students = await _api.fetchAchievementStudents(
        widget.achievementId,
      );
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().add_jm().format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items:
              widget.breadcrumbs ??
              [
                BreadcrumbItem(
                  label: 'Achievements',
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                BreadcrumbItem(
                  label: widget.achievementName,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const BreadcrumbItem(label: 'Students'),
              ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _selectedClassFilter = null;
                _searchController.clear();
              });
              _fetchStudents();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            ElevatedButton(
              onPressed: _fetchStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(
        child: Text('No students have unlocked this achievement yet.'),
      );
    }

    // 1. Filter Students
    final filteredList = _students.where((student) {
      final name = student['name']?.toString().toLowerCase() ?? '';
      final email = student['email']?.toString().toLowerCase() ?? '';
      final className = student['class_name']?.toString() ?? 'Other / No Class';

      // Dropdown Filter
      if (_selectedClassFilter != null &&
          _selectedClassFilter != 'All Classes') {
        if (className != _selectedClassFilter) return false;
      }

      // Text Search (Matches Student Name, Email, Class Name, or Achievement Name)
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        final matchesName = name.contains(query);
        final matchesEmail = email.contains(query);
        final matchesClass = className.toLowerCase().contains(query);
        // Also match achievement name if user searches for it (as requested)
        final matchesAchievement = widget.achievementName
            .toLowerCase()
            .contains(query);

        return matchesName ||
            matchesEmail ||
            matchesClass ||
            matchesAchievement;
      }

      return true;
    }).toList();

    if (filteredList.isEmpty &&
        (_searchController.text.isNotEmpty || _selectedClassFilter != null)) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchAndFilter(),
                const Expanded(
                  child: Center(child: Text('No students match your search.')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Group filtered students
    final Map<String, List<Map<String, dynamic>>> groupedStudents = {};

    for (var student in filteredList) {
      final className = student['class_name'] as String? ?? 'Other / No Class';
      if (!groupedStudents.containsKey(className)) {
        groupedStudents[className] = [];
      }
      groupedStudents[className]!.add(student);
    }

    // 3. Prepare display data
    final sortedKeys = groupedStudents.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Card(
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchAndFilter(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, sectionIndex) {
                    final className = sortedKeys[sectionIndex];
                    final studentsInClass = groupedStudents[className]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Text(
                            className,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        // List of Students inside Cards
                        // Note: Using individual cards for students as before
                        ...studentsInClass.map((student) {
                          // ... mapping logic remains distinct for readability
                          return _buildStudentItem(context, student);
                        }),
                        const SizedBox(height: 12.0),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentItem(BuildContext context, Map<String, dynamic> student) {
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? 'No Email';
    final userId = student['user_id'];
    final unlockedAt = student['unlocked_at'];
    final isExcluded =
        widget.excludedStudentId != null &&
        userId.toString() == widget.excludedStudentId.toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 0.5,
      color: isExcluded
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isExcluded ? Theme.of(context).disabledColor : null,
          ),
        ),
        subtitle: Text(email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Unlocked',
                  style: TextStyle(
                    fontSize: 10,
                    color: isExcluded
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(unlockedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isExcluded ? Theme.of(context).disabledColor : null,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: isExcluded ? Theme.of(context).disabledColor : Colors.grey,
            ),
          ],
        ),
        onTap: () {
          if (isExcluded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Press back to view $name"),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailPage(
                  userId: userId,
                  userName: name,
                  userRole: 'Student',
                  breadcrumbs: widget.breadcrumbs != null
                      ? [
                          ...BreadcrumbItem.wrap(widget.breadcrumbs!, context),
                          BreadcrumbItem(
                            label: 'Students',
                            // Current page is Students, so popping goes back to 'Achievement' (parent).
                            // Wait, if we use default logic, 'Students' has no onTap.
                            // If we click it from next page, we want to come back here.
                            // If we click it HERE, nothing happens.
                            // So 'null' onTap is fine for 'Students' item itself.
                            // But usually last item has NO onTap.
                          ),
                          BreadcrumbItem(label: '$name Profile'),
                        ]
                      : [
                          BreadcrumbItem(
                            label: 'Achievements',
                            onTap: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                          ),
                          BreadcrumbItem(
                            label: widget.achievementName,
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                          ),
                          BreadcrumbItem(
                            label: 'Students',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          BreadcrumbItem(label: '$name Profile'),
                        ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    // Extract unique classes for dropdown
    final classNames =
        _students
            .map((e) => e['class_name'] as String? ?? 'Other / No Class')
            .toSet()
            .toList()
          ..sort();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar (M3)
        Expanded(
          flex: 2,
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search students...',
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() {}),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
            ],
            elevation: const WidgetStatePropertyAll<double>(1.0),
            backgroundColor: WidgetStatePropertyAll<Color>(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Filter Dropdown (DropdownButtonFormField)
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: _selectedClassFilter,
            decoration: InputDecoration(
              labelText: 'Filter by Class',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.filter_list),
            onChanged: (newValue) {
              setState(() {
                _selectedClassFilter = newValue;
              });
            },
            items: [
              const DropdownMenuItem(value: null, child: Text('All Classes')),
              ...classNames.map((cls) {
                return DropdownMenuItem(
                  value: cls,
                  child: Text(cls, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
