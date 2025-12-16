import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';

/// Teacher view: All students in a class with search, pagination, and compact cards.
class TeacherAllStudentsPage extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherAllStudentsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherAllStudentsPage> createState() => _TeacherAllStudentsPageState();
}

class _TeacherAllStudentsPageState extends State<TeacherAllStudentsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _perPage = 6;
  int _totalPages = 1;

  // Statistics
  int _totalStudents = 0;
  double _averageScore = 0.0;
  double _quizzesCompleted = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    // 0 letters -> show all, 1+ letters -> filter
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_students);
      } else {
        final q = query.toLowerCase();
        _filteredStudents = _students.where((student) {
          final name = (student['name'] ?? '').toString().toLowerCase();
          // Filter by name only
          return name.contains(q);
        }).toList();
      }
      _currentPage = 1;
      _applyPagination();
    });
  }

  Future<void> _fetchClassData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ClassApi.fetchClassById(widget.classId);
      if (!mounted || data == null) return;

      setState(() {
        _students = List<Map<String, dynamic>>.from(data['students'] ?? []);
        _totalStudents = _students.length;
        _calculateStatistics();

        final query = _searchController.text.trim().toLowerCase();
        if (query.isEmpty) {
          _filteredStudents = List.from(_students);
        } else {
          _filteredStudents = _students.where((student) {
            final name = (student['name'] ?? '').toString().toLowerCase();
            // Filter by name only
            return name.contains(query);
          }).toList();
        }

        _applyPagination();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching class data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _calculateStatistics() {
    if (_students.isEmpty) {
      _averageScore = 0.0;
      _quizzesCompleted = 0.0;
      return;
    }

    double totalScore = 0.0;
    int totalQuizzes = 0;
    int completedQuizzes = 0;

    for (var student in _students) {
      // Mock performance values until backend provides real data
      final mockScore = 70.0 + (student.hashCode % 30); // 70-100
      const mockTotalQuizzes = 18;
      final mockCompleted = 13 + (student.hashCode % 6); // 13-18

      totalScore += mockScore;
      totalQuizzes += mockTotalQuizzes;
      completedQuizzes += mockCompleted;
    }

    _averageScore = totalScore / _students.length;
    _quizzesCompleted = totalQuizzes == 0
        ? 0
        : (completedQuizzes / totalQuizzes) * 100;
  }

  void _applyPagination() {
    _totalPages = (_filteredStudents.length / _perPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = 1;
  }

  List<Map<String, dynamic>> get _paginatedStudents {
    if (_filteredStudents.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _perPage;
    if (startIndex >= _filteredStudents.length) return [];
    final endIndex = (startIndex + _perPage) > _filteredStudents.length
        ? _filteredStudents.length
        : (startIndex + _perPage);
    return _filteredStudents.sublist(startIndex, endIndex);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFF4CAF50),
      Color(0xFF9C27B0),
      Color(0xFF795548),
      Color(0xFF009688),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(cs),
                  const SizedBox(height: 24),
                  _buildStatisticsSection(cs),
                  const SizedBox(height: 24),
                  _buildSearchSection(cs),
                  const SizedBox(height: 24),
                  _filteredStudents.isEmpty
                      ? _buildEmptyState(cs)
                      : _buildStudentsGrid(cs),
                  const SizedBox(height: 24),
                  if (_filteredStudents.isNotEmpty) _buildPagination(cs),
                ],
              ),
            ),
    );
  }

  /* ---------------- HEADER ---------------- */
  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: cs.primary),
          label: Text('Back to Class', style: TextStyle(color: cs.primary)),
        ),
        const SizedBox(height: 8),
        Text(
          'All Students',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        Text(widget.className, style: TextStyle(color: cs.onSurfaceVariant)),
      ],
    );
  }

  /* ---------------- STATS ---------------- */
  Widget _buildStatisticsSection(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            cs,
            'Total Students',
            '$_totalStudents',
            Icons.people,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            cs,
            'Average Score',
            _averageScore.toStringAsFixed(0),
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            cs,
            'Quizzes Completed',
            '${_quizzesCompleted.toStringAsFixed(0)}%',
            Icons.quiz,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ColorScheme cs,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  /* ---------------- SEARCH ---------------- */
  Widget _buildSearchSection(ColorScheme cs) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _onSearchChanged(),
      decoration: InputDecoration(
        hintText: 'Search students...',
        prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
    );
  }

  /* ---------------- GRID ---------------- */
  Widget _buildStudentsGrid(ColorScheme cs) {
    final width = MediaQuery.of(context).size.width;
    // On narrow screens (mobile/portrait), switch to a single column
    // and give each card more vertical space to avoid overflow.
    final bool isNarrow = width < 800;
    final int crossAxisCount = isNarrow ? 1 : 2;
    final double aspectRatio = isNarrow ? 2.1 : 2.8;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedStudents.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        // Wider cards on desktop/tablet, taller on mobile to prevent overflow
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, index) =>
          _buildStudentCard(cs, _paginatedStudents[index], index),
    );
  }

  Widget _buildStudentCard(
    ColorScheme cs,
    Map<String, dynamic> student,
    int index,
  ) {
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final phone = student['phone_no'] ?? '+1 234 567 8901';
    final initials = _getInitials(name);
    final score = 70 + (student.hashCode % 30); // mock until real data
    final progress = 70 + (student.hashCode % 30); // mock until real data

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _getAvatarColor(index).withOpacity(0.18),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: cs.onSurfaceVariant,
                  size: 18,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Divider(color: cs.outlineVariant, thickness: 0.6, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avg Score',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: Colors.green.shade400,
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quizzes',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '15/18',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Course Progress',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress / 100,
            minHeight: 4,
            backgroundColor: cs.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  /* ---------------- EMPTY ---------------- */
  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Text(
        'No students found',
        style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
      ),
    );
  }

  /* ---------------- PAGINATION ---------------- */
  Widget _buildPagination(ColorScheme cs) {
    final startIndex = (_currentPage - 1) * _perPage + 1;
    final endIndex = (_currentPage * _perPage) > _filteredStudents.length
        ? _filteredStudents.length
        : (_currentPage * _perPage);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startIndex to $endIndex of ${_filteredStudents.length} entries',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        Row(
          children: [
            _pageButton(
              cs,
              label: 'Previous',
              enabled: _currentPage > 1,
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
            const SizedBox(width: 8),
            ..._buildPageNumberButtons(cs),
            const SizedBox(width: 8),
            _pageButton(
              cs,
              label: 'Next',
              enabled: _currentPage < _totalPages,
              onPressed: _currentPage < _totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageNumberButtons(ColorScheme cs) {
    final buttons = <Widget>[];
    int start = (_currentPage - 1).clamp(1, _totalPages);
    int end = (_currentPage + 1).clamp(1, _totalPages);
    if (start == 1 && end < 3 && _totalPages >= 3) end = 3;
    if (end == _totalPages && start > 1 && _totalPages >= 3)
      start = _totalPages - 2;

    for (int i = start; i <= end; i++) {
      buttons.add(
        _pageButton(
          cs,
          label: '$i',
          enabled: true,
          active: i == _currentPage,
          onPressed: () => setState(() => _currentPage = i),
        ),
      );
      if (i != end) buttons.add(const SizedBox(width: 6));
    }
    return buttons;
  }

  Widget _pageButton(
    ColorScheme cs, {
    required String label,
    required bool enabled,
    bool active = false,
    VoidCallback? onPressed,
  }) {
    final bg = active ? cs.primary : cs.surfaceContainerHighest;
    final fg = active ? cs.onPrimary : cs.onSurface;
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: enabled
            ? bg
            : cs.surfaceContainerHighest.withOpacity(0.6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: active ? cs.primary : cs.outlineVariant),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? fg : cs.onSurfaceVariant.withOpacity(0.7),
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
