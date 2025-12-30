import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/api/game_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:flutter_codelab/models/level.dart';
import 'package:intl/intl.dart';

/// Full-page teacher view: all quizzes for a single class.
///
/// - Fetches class data by [classId] to show class name & description
/// - Fetches quizzes (levels) assigned to this class
/// - Allows creating new quizzes (using Unity game creation)
/// - Allows assigning existing levels to this class
/// - Uses the same theme/text styles as other admin/teacher class pages
class TeacherViewQuizPage extends StatefulWidget {
  final String classId;
  final String roleName;

  const TeacherViewQuizPage({
    super.key,
    required this.classId,
    required this.roleName,
  });

  @override
  State<TeacherViewQuizPage> createState() => _TeacherViewQuizPageState();
}

class _TeacherViewQuizPageState extends State<TeacherViewQuizPage> {
  bool _loading = true;
  Map<String, dynamic>? _classData;
  List<Map<String, dynamic>> _quizzes = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final classData = await ClassApi.fetchClassById(widget.classId);
      final quizzes = await ClassApi.getClassQuizzes(widget.classId);

      if (!mounted) return;
      setState(() {
        _classData = classData;
        _quizzes = quizzes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(
        context,
        'Error loading data: $e',
        Theme.of(context).colorScheme.error,
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleCreateQuiz() async {
    // Open create game page (Unity WebView)
    // After creation, teacher can manually assign it using "Assign Quiz"
    showCreateGamePage(
      context: context,
      userRole: widget.roleName,
      showSnackBar: _showSnackBar,
    );

    // Refresh quizzes after a delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _fetchData();
  }

  Future<void> _handleAssignQuiz() async {
    // Fetch all available levels (excluding private ones)
    final allLevels = await GameAPI.fetchLevels(forceRefresh: true);

    if (!mounted) return;

    // Show dialog to select a level to assign
    final selectedLevel = await showDialog<LevelModel>(
      context: context,
      builder: (context) => _AssignQuizDialog(
        levels: allLevels,
        onReload: () async {
          // Reload levels and reopen dialog
          await GameAPI.fetchLevels(forceRefresh: true);
          if (context.mounted) {
            Navigator.pop(context);
            // Reopen dialog with new levels
            _handleAssignQuiz();
          }
        },
      ),
    );

    if (selectedLevel != null) {
      final result = await ClassApi.assignQuizToClass(
        classId: widget.classId,
        levelId: selectedLevel.levelId!,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar(context, 'Quiz assigned successfully', Colors.green);
        _fetchData();
      } else {
        _showSnackBar(
          context,
          result['message'] ?? 'Failed to assign quiz',
          Colors.red,
        );
      }
    }
  }

  Future<void> _handleRemoveQuiz(String levelId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Quiz'),
        content: const Text(
          'Are you sure you want to remove this quiz from the class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ClassApi.removeQuizFromClass(
        classId: widget.classId,
        levelId: levelId,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(context, 'Quiz removed successfully', Colors.green);
        _fetchData();
      } else {
        _showSnackBar(context, 'Failed to remove quiz', Colors.red);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredQuizzes {
    if (_searchQuery.isEmpty) return _quizzes;
    final query = _searchQuery.toLowerCase();
    return _quizzes.where((quiz) {
      final name = (quiz['level_name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header + stats card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Header(
                                className:
                                    _classData?['class_name'] ?? 'No Name',
                                classDescription:
                                    _classData?['description'] ??
                                    'No description',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Total Quizzes',
                                      value: '${_quizzes.length}',
                                      icon: Icons.quiz,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Last Updated',
                                      value: _quizzes.isNotEmpty
                                          ? _formatDate(
                                              _quizzes.first['updated_at'] ??
                                                  _quizzes.first['created_at'],
                                            )
                                          : 'Never',
                                      icon: Icons.schedule,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quizzes card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: cs.outlineVariant, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'Quizzes',
                                subtitle: 'Browse and manage class quizzes',
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _handleAssignQuiz,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Assign Quiz'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: _handleCreateQuiz,
                                      icon: const Icon(Icons.add_circle),
                                      label: const Text('Create Quiz'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search quizzes...',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor: cs.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cs.outlineVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cs.outlineVariant,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cs.primary,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _filteredQuizzes.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32.0),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.quiz_outlined,
                                              size: 64,
                                              color: cs.onSurfaceVariant
                                                  .withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _searchQuery.isNotEmpty
                                                  ? 'No quizzes match your search'
                                                  : 'No quizzes assigned to this class',
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _searchQuery.isNotEmpty
                                                  ? 'Try adjusting your search query'
                                                  : 'Create or assign a quiz to get started',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant
                                                        .withOpacity(0.7),
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: _filteredQuizzes
                                          .map(
                                            (quiz) => _QuizItem(
                                              quiz: quiz,
                                              onRemove: () => _handleRemoveQuiz(
                                                quiz['level_id'],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _Header extends StatelessWidget {
  final String className;
  final String classDescription;

  const _Header({required this.className, required this.classDescription});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: cs.primary),
          label: Text(
            'Back to Class',
            style: textTheme.bodyMedium?.copyWith(color: cs.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'All Quizzes',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          className,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          classDescription,
          style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _QuizItem extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final VoidCallback onRemove;

  const _QuizItem({required this.quiz, required this.onRemove});

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final levelType = quiz['level_type'];
    final levelTypeName = levelType != null
        ? levelType['level_type_name'] ?? 'Unknown'
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz, color: cs.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quiz['level_name'] ?? 'No Name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        levelTypeName,
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded: ${_formatDate(quiz['created_at'])}',
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Remove from class',
          ),
        ],
      ),
    );
  }
}

class _AssignQuizDialog extends StatefulWidget {
  final List<LevelModel> levels;
  final VoidCallback? onReload;

  const _AssignQuizDialog({required this.levels, this.onReload});

  @override
  State<_AssignQuizDialog> createState() => _AssignQuizDialogState();
}

class _AssignQuizDialogState extends State<_AssignQuizDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LevelModel> get _filteredLevels {
    if (_searchQuery.isEmpty) return widget.levels;
    final query = _searchQuery.toLowerCase();
    return widget.levels.where((level) {
      final name = (level.levelName ?? '').toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assign Quiz to Class',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onReload != null)
                      IconButton(
                        onPressed: widget.onReload,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Reload quizzes',
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search levels...',
                prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredLevels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quizzes available',
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a quiz first or check back later',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredLevels.length,
                      itemBuilder: (context, index) {
                        final level = _filteredLevels[index];
                        return ListTile(
                          leading: Icon(Icons.quiz, color: cs.primary),
                          title: Text(level.levelName ?? 'No Name'),
                          subtitle: Text(level.levelTypeName ?? 'Unknown Type'),
                          onTap: () => Navigator.pop(context, level),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
