import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:code_play/api/game_api.dart';
import 'package:code_play/models/level.dart';
import 'package:intl/intl.dart';

/// ===============================================================
/// Opens the teacher quiz results in a dialog "window"
/// ===============================================================
void showTeacherQuizResults({
  required BuildContext context,
  required LevelModel level,
}) {
  showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TeacherQuizView(
            level: level,
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

class TeacherQuizView extends StatefulWidget {
  final LevelModel level;
  final VoidCallback onBack;

  const TeacherQuizView({super.key, required this.level, required this.onBack});

  @override
  State<TeacherQuizView> createState() => _TeacherQuizViewState();
}

class _TeacherQuizViewState extends State<TeacherQuizView> {
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    final users = await GameAPI.fetchLevelUsers(widget.level.levelId!);
    setState(() {
      _students = users;
      _loading = false;
    });
  }

  String _formatTime(dynamic timerValue) {
    if (timerValue == null) return "N/A";
    int seconds = int.tryParse(timerValue.toString()) ?? 0;
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _openStudentPreview(Map<String, dynamic> student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            StudentQuizPreviewPage(level: widget.level, student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Text(
                "Quiz Results: ${widget.level.levelName}",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: _fetchStudents,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? const Center(
                  child: Text("No students have played this quiz yet."),
                )
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final dateStr = student['last_played'] as String?;
                    final date = dateStr != null
                        ? DateTime.tryParse(dateStr)
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student['name'][0].toUpperCase()),
                        ),
                        title: Text(student['name']),
                        subtitle: Text(
                          date != null
                              ? DateFormat('MMM d, y h:mm a').format(date)
                              : "Unknown date",
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            "Time: ${_formatTime(student['time_remaining'])}",
                          ),
                        ),
                        onTap: () => _openStudentPreview(student),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class StudentQuizPreviewPage extends StatefulWidget {
  final LevelModel level;
  final Map<String, dynamic> student;

  const StudentQuizPreviewPage({
    super.key,
    required this.level,
    required this.student,
  });

  @override
  State<StudentQuizPreviewPage> createState() => _StudentQuizPreviewPageState();
}

class _StudentQuizPreviewPageState extends State<StudentQuizPreviewPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // No server initialization needed - we'll display code directly
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.student['name']}'s Submission")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildCodeView(),
    );
  }

  Widget _buildCodeView() {
    final indexFilesStr = widget.student['index_files'] as String?;
    
    if (indexFilesStr == null) {
      return const Center(
        child: Text('No submission data available'),
      );
    }

    try {
      final Map<String, dynamic> indexFiles = jsonDecode(indexFilesStr);
      
      return DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'HTML'),
                Tab(text: 'CSS'),
                Tab(text: 'JS'),
                Tab(text: 'PHP'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCodeTab('HTML', indexFiles['html'] as String?),
                  _buildCodeTab('CSS', indexFiles['css'] as String?),
                  _buildCodeTab('JS', indexFiles['js'] as String?),
                  _buildCodeTab('PHP', indexFiles['php'] as String?),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Center(
        child: Text('Error loading submission: $e'),
      );
    }
  }

  Widget _buildCodeTab(String title, String? content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use theme-aware colors for code display
    final codeBackgroundColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHighest;
    final codeBorderColor = isDark
        ? theme.colorScheme.outline
        : theme.colorScheme.outlineVariant;
    final codeTextColor = isDark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: codeBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: codeBorderColor),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: SelectableText(
                    content ?? 'No $title code available',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: codeTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
