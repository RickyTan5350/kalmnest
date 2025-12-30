import 'dart:async';
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/api/game_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_quiz_detail_page.dart';
import 'package:flutter_codelab/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_customization.dart';
import 'package:flutter_codelab/models/level.dart';
import 'package:intl/intl.dart';
import 'package:flutter_codelab/constants/class_constants.dart';
=======
import 'package:code_play/api/class_api.dart';
import 'package:code_play/api/game_api.dart';
import 'package:code_play/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:code_play/admin_teacher/widgets/class/teacher_quiz_detail_page.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/models/level.dart';
import 'package:intl/intl.dart';
import 'package:code_play/constants/class_constants.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';
>>>>>>> Stashed changes

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
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(
        context,
        l10n.errorLoadingData(e.toString()),
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
    final l10n = AppLocalizations.of(context)!;

    // Ask user if quiz should be private or public
    final isPrivateResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.quizVisibility),
        content: Text(l10n.selectQuizVisibility),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Private
            child: Text(l10n.private),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false), // Public
            child: Text(l10n.public),
          ),
        ],
      ),
    );

    if (isPrivateResult == null) return; // User cancelled

    final isPrivate = isPrivateResult;

    // Use Completer to wait for level creation
    final Completer<String?> levelIdCompleter = Completer<String?>();

    // Now open create game page with callback
    showCreateGamePage(
      context: context,
      userRole: widget.roleName,
      showSnackBar: _showSnackBar,
      onLevelCreated: (levelId) {
        if (!levelIdCompleter.isCompleted) {
          levelIdCompleter.complete(levelId);
        }
      },
    );

    // Wait for level creation (with timeout)
    final createdLevelId = await levelIdCompleter.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => null,
    );

    // If we got the level ID, assign it immediately
    if (createdLevelId != null && mounted) {
      final result = await ClassApi.assignQuizToClass(
        classId: widget.classId,
        levelId: createdLevelId,
        isPrivate: isPrivate,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (result['success'] == true) {
          _showSnackBar(
            context,
            l10n.quizCreatedAndAssignedSuccessfully,
            Colors.green,
          );
          // Refresh the quiz list
          _fetchData();
        } else {
          _showSnackBar(
            context,
            result['message'] ?? l10n.failedToAssignQuiz,
            Theme.of(context).colorScheme.error,
          );
        }
      }
    } else if (mounted) {
      // Fallback: try to find the newly created level
      await Future.delayed(const Duration(seconds: 2));
      final allLevels = await GameAPI.fetchLevels(forceRefresh: true);

      if (mounted && allLevels.isNotEmpty) {
        // Get the most recently created level by current user
        final newLevel = allLevels.firstWhere(
          (level) => level.isCreatedByMe == true,
          orElse: () => allLevels.first,
        );

        if (newLevel.levelId != null) {
          final result = await ClassApi.assignQuizToClass(
            classId: widget.classId,
            levelId: newLevel.levelId!,
            isPrivate: isPrivate,
          );

          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            if (result['success'] == true) {
              _showSnackBar(
                context,
                l10n.quizCreatedAndAssignedSuccessfully,
                Colors.green,
              );
              _fetchData();
            } else {
              _showSnackBar(
                context,
                result['message'] ?? l10n.failedToAssignQuiz,
                Theme.of(context).colorScheme.error,
              );
            }
          }
        }
      }
    }
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
      final l10n = AppLocalizations.of(context)!;

      // Ask user if quiz should be private or public
      final isPrivateResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.quizVisibility),
          content: Text(l10n.selectQuizVisibility),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Private
              child: Text(l10n.private),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, false), // Public
              child: Text(l10n.public),
            ),
          ],
        ),
      );

      if (isPrivateResult == null) return; // User cancelled

      final isPrivate = isPrivateResult;

      final result = await ClassApi.assignQuizToClass(
        classId: widget.classId,
        levelId: selectedLevel.levelId!,
        isPrivate: isPrivate,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar(context, l10n.quizAssignedSuccessfully, Colors.green);
        _fetchData();
      } else {
        _showSnackBar(
          context,
          result['message'] ?? l10n.failedToAssignQuiz,
          Colors.red,
        );
      }
    }
  }

  Future<void> _handleRemoveQuiz(String levelId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeQuiz),
        content: Text(l10n.removeQuizConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.remove),
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

      final l10n = AppLocalizations.of(context)!;
      if (success) {
        _showSnackBar(context, l10n.quizRemovedSuccessfully, Colors.green);
        _fetchData();
      } else {
        _showSnackBar(context, l10n.failedToRemoveQuiz, Colors.red);
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
    if (_loading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get class color for AppBar
    final color = cs.primary;

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: l10n.classes,
              onTap: () {
                // Navigate back to class list
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(
              label: l10n.details,
              onTap: () => Navigator.of(context).pop(),
            ),
            BreadcrumbItem(label: l10n.allQuizzes),
          ],
        ),
        backgroundColor: color.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _fetchData();
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Centered with icon, title, and class name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(Icons.school_rounded, color: color, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.allQuizzes,
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_classData?['class_name'] ?? l10n.noName),
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Statistics Section - General Info style
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  l10n.statistics,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              _buildInfoRow(
                cs,
                textTheme,
                Icons.quiz,
                l10n.totalQuizzes,
                '${_quizzes.length}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.schedule,
                  l10n.lastUpdated,
                  _quizzes.isNotEmpty
                      ? _formatDate(
                          _quizzes.first['updated_at'] ??
                              _quizzes.first['created_at'],
                        )
                      : l10n.never,
                ),
              ),
              const Divider(height: 30),
              const SizedBox(height: 32),

              // Search Section with Action Buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SearchBar(
                      controller: _searchController,
                      hintText: l10n.searchQuizzes,
                      padding: const WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _handleAssignQuiz,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.assignQuiz),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _handleCreateQuiz,
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: Text(l10n.createQuiz),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quizzes List Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: cs.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                color: cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.quizzes,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_filteredQuizzes.length} quiz${_filteredQuizzes.length != 1 ? 'es' : ''} available',
                                style: textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Content
                      if (_filteredQuizzes.isEmpty)
                        _buildEmptyState(context, cs, textTheme)
                      else
                        ..._filteredQuizzes.map((quiz) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _QuizItem(
                              quiz: quiz,
                              classId: widget.classId,
                              onRemove: () =>
                                  _handleRemoveQuiz(quiz['level_id']),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ColorScheme cs,
    TextTheme textTheme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: valueColor ?? cs.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noQuizzesYet,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.createOrAssignQuizzes,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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

class _QuizItem extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final String classId;
  final VoidCallback onRemove;

  const _QuizItem({
    required this.quiz,
    required this.classId,
    required this.onRemove,
  });

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
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final levelType = quiz['level_type'];
    final levelTypeName = levelType != null
        ? levelType['level_type_name'] ?? l10n.unknown
        : l10n.unknown;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outline.withOpacity(0.3), width: 1.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TeacherQuizDetailPage(
                classId: classId,
                levelId: quiz['level_id'],
                quizName: quiz['level_name'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(Icons.quiz, color: cs.onPrimaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quiz['level_name'] ?? l10n.noName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            levelTypeName,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: cs.primaryContainer.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.uploaded}: ${_formatDate(quiz['created_at'])}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tapToViewStudentCompletion,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: l10n.moreOptions,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove();
                  } else if (value == 'view') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TeacherQuizDetailPage(
                          classId: classId,
                          levelId: quiz['level_id'],
                          quizName: quiz['level_name'],
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  final l10n = AppLocalizations.of(context)!;
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20, color: cs.onSurface),
                          const SizedBox(width: 12),
                          Text(l10n.viewDetails),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: cs.error),
                          const SizedBox(width: 12),
                          Text(l10n.remove, style: TextStyle(color: cs.error)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.assignQuizToClass,
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
            SizedBox(height: ClassConstants.defaultPadding),
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
            SizedBox(height: ClassConstants.defaultPadding),
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
                          SizedBox(height: ClassConstants.defaultPadding),
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
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
