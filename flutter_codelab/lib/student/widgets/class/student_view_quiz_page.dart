import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/api/auth_api.dart';
import 'package:code_play/constants/api_constants.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:code_play/constants/class_constants.dart';
import 'package:code_play/admin_teacher/widgets/class/class_customization.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

/// Full-page student view: all quizzes for a single class.
///
/// - Fetches class data by [classId] to show class name & description
/// - Fetches quizzes (levels) assigned to this class
/// - Allows playing quizzes (opens Unity WebView)
/// - Uses the same theme/text styles as other student class pages
class StudentViewQuizPage extends StatefulWidget {
  final String classId;
  final String roleName;

  const StudentViewQuizPage({
    super.key,
    required this.classId,
    required this.roleName,
  });

  @override
  State<StudentViewQuizPage> createState() => _StudentViewQuizPageState();
}

class _StudentViewQuizPageState extends State<StudentViewQuizPage> {
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
      
      // Get current user ID from stored user data
      String? studentId;
      try {
        final storedUserJson = await AuthApi.getStoredUser();
        if (storedUserJson != null && storedUserJson['user_id'] != null) {
          studentId = storedUserJson['user_id'].toString();
        }
      } catch (e) {
        print('Error getting user ID: $e');
      }

      // If we have student ID, fetch quizzes with completion status
      // Otherwise, fall back to regular quiz list
      List<Map<String, dynamic>> quizzes;
      if (studentId != null && studentId.isNotEmpty) {
        final result = await ClassApi.getStudentQuizzes(widget.classId, studentId);
        quizzes = result['success'] == true 
            ? List<Map<String, dynamic>>.from(result['data'] ?? [])
            : await ClassApi.getClassQuizzes(widget.classId);
      } else {
        quizzes = await ClassApi.getClassQuizzes(widget.classId);
      }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorDeletingClass(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _playQuiz(Map<String, dynamic> quiz) {
    final levelId = quiz['level_id'];
    if (levelId == null) return;

    // Open Unity WebView with the level (same as game module)
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Dialog(
          child: SizedBox(
            width: 1200,
            height: 800,
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: EdgeInsets.all(ClassConstants.defaultPadding * 0.5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        quiz['level_name'] ?? l10n.quiz,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Unity WebView
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      "${ApiConstants.domain}/unity_build/index.html?role=${widget.roleName}&level=$levelId",
                    ),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    isInspectable: false,
                  ),
                  onWebViewCreated: (controller) {},
                  onLoadStart: (controller, url) {
                    debugPrint("Started loading: $url");
                  },
                  onLoadStop: (controller, url) async {
                    debugPrint("Finished loading: $url");
                  },
                  onLoadError: (controller, url, code, message) {
                    debugPrint("Failed to load $url: $message");
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
    );
  }

  List<Map<String, dynamic>> get _filteredQuizzes {
    if (_searchQuery.isEmpty) return _quizzes;
    final query = _searchQuery.toLowerCase();
    return _quizzes.where((quiz) {
      final name = (quiz['level_name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  String _formatDate(dynamic date, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (date == null) return l10n.unknown;
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return l10n.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get class color for AppBar
    final classColor = ClassCustomization.getColorByName(_classData?['color']);
    final color = classColor?.color ?? cs.primary;

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: l10n.classes,
              onTap: () {
                // Pop twice to go back to class list (once from All Quizzes, once from Details)
                Navigator.of(context).pop();
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
                          context,
                        )
                      : l10n.never,
                ),
              ),
              const Divider(height: 30),
              const SizedBox(height: 24),

              // Search Bar - Outside and full width
              SearchBar(
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
              const SizedBox(height: 16),

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
                                l10n.quizzesAvailable(_filteredQuizzes.length),
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
                        _buildEmptyState(cs, textTheme)
                      else
                        ..._filteredQuizzes.map((quiz) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _StudentQuizItem(
                              quiz: quiz,
                              onPlay: () => _playQuiz(quiz),
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
    String value,
  ) {
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
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme textTheme) {
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
              l10n.noQuizzesAssigned,
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
}

class _StudentQuizItem extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final VoidCallback onPlay;

  const _StudentQuizItem({required this.quiz, required this.onPlay});

  String _formatDate(BuildContext context, dynamic date) {
    final l10n = AppLocalizations.of(context)!;
    if (date == null) return l10n.unknown;
    try {
      final dateTime = DateTime.parse(date.toString());
      final formatted = DateFormat('MMM d, yyyy').format(dateTime);
      return l10n.uploaded(formatted);
    } catch (e) {
      return l10n.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outline.withOpacity(0.3), width: 1.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon container
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
            // Quiz info
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
                      // Completion status indicator
                      if (quiz['is_completed'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(context, quiz['created_at']),
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Play button (change text if completed)
            FilledButton.icon(
              onPressed: onPlay,
              icon: Icon(
                quiz['is_completed'] == true ? Icons.replay : Icons.play_arrow,
                size: 18,
              ),
              label: Text(
                quiz['is_completed'] == true 
                    ? 'Replay'
                    : l10n.play,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: quiz['is_completed'] == true
                    ? cs.tertiary
                    : cs.primary,
                foregroundColor: quiz['is_completed'] == true
                    ? cs.onTertiary
                    : cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
