import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';
import 'package:flutter_codelab/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_customization.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:flutter_codelab/constants/class_constants.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
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
      builder: (context) => Dialog(
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
                      quiz['level_name'] ?? 'Quiz',
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
      ),
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
    if (_loading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
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
              label: 'Classes',
              onTap: () {
                // Pop twice to go back to class list (once from All Quizzes, once from Details)
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(
              label: 'Details',
              onTap: () => Navigator.of(context).pop(),
            ),
            const BreadcrumbItem(label: 'All Quizzes'),
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
            tooltip: 'Refresh',
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
                      child: Icon(
                        Icons.school_rounded,
                        color: color,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Quizzes',
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_classData?['class_name'] ?? 'No Name'),
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
                  'Statistics',
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
                'Total Quizzes',
                '${_quizzes.length}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.schedule,
                  'Last Updated',
                  _quizzes.isNotEmpty
                      ? _formatDate(
                          _quizzes.first['updated_at'] ??
                              _quizzes.first['created_at'],
                        )
                      : 'Never',
                ),
              ),
              const Divider(height: 30),
              const SizedBox(height: 24),

              // Search Bar - Outside and full width
              SearchBar(
                controller: _searchController,
                hintText: "Search quizzes...",
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
                                'Quizzes',
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
                  style: TextStyle(
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme textTheme) {
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
              'No quizzes yet',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your teacher hasn\'t assigned any quizzes yet',
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

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: cs.outline.withOpacity(0.3),
          width: 1.0,
        ),
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
              child: Icon(
                Icons.quiz,
                color: cs.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Quiz info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz['level_name'] ?? 'No Name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uploaded: ${_formatDate(quiz['created_at'])}',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Play button
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Play'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
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

