import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';

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
                padding: const EdgeInsets.all(8),
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
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Header + class meta
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _Header(
                        className: _classData?['class_name'] ?? 'No Name',
                        classDescription:
                            _classData?['description'] ?? 'No description',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: cs.outlineVariant, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StudentStatCard(
                              title: 'Total Quizzes',
                              value: '${_quizzes.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StudentStatCard(
                              title: 'Last Updated',
                              value: _quizzes.isNotEmpty
                                  ? _formatDate(
                                      _quizzes.first['updated_at'] ??
                                          _quizzes.first['created_at'],
                                    )
                                  : 'Never',
                            ),
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
                            subtitle: 'All quizzes for this class',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search,
                                color: cs.onSurfaceVariant,
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
                              hintText: 'Search quizzes...',
                              hintStyle: textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
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
                                              : 'No quizzes available',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? 'Try adjusting your search query'
                                              : 'Your teacher hasn\'t assigned any quizzes yet',
                                          style: textTheme.bodySmall?.copyWith(
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
                                        (quiz) => _StudentQuizItem(
                                          quiz: quiz,
                                          onPlay: () => _playQuiz(quiz),
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
    );
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
          icon: Icon(Icons.arrow_back, color: cs.primary, size: 18),
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

class _StudentStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StudentStatCard({required this.title, required this.value});

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
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.quiz, color: cs.primary),
          ),
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
                const SizedBox(height: 8),
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
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
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
          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
