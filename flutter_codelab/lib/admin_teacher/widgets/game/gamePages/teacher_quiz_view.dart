import 'dart:convert';
import 'package:code_play/admin_teacher/widgets/game/gamePages/play_game_page.dart';
import 'package:code_play/utils/local_asset_server.dart';
import 'package:flutter/material.dart';
import 'package:code_play/api/game_api.dart'; // Ensure this matches your path
import 'package:code_play/models/level.dart';
import 'package:intl/intl.dart';
import 'package:code_play/services/local_level_storage.dart';
import 'package:flutter/foundation.dart';

/// ===============================================================
/// Opens the teacher quiz results in a dialog "window"
/// ===============================================================
void showTeacherQuizResults({
  required BuildContext context,
  required LevelModel level,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TeacherQuizView(
          level: level,
          onBack: () => Navigator.pop(context),
        ),
      ),
    ),
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
  LocalAssetServer? _server;
  String? _serverUrl;
  final LocalLevelStorage _storage = LocalLevelStorage();

  @override
  void initState() {
    super.initState();
    _initServerAndData();
  }

  Future<void> _initServerAndData() async {
    // 1. Start Server
    _server = LocalAssetServer();
    try {
      final studentId = widget.student['user_id']?.toString();
      final storageBasePath = await _storage.getBasePath(userId: studentId);
      await _server!.start(path: storageBasePath);

      setState(() {
        _serverUrl = "http://localhost:${_server!.port}";
      });
    } catch (e) {
      print("Error starting local server: $e");
    }

    // 2. Write Student Data to Index folder (overwriting implementation)
    final indexFilesStr = widget.student['index_files'] as String?;
    final savedDataStr = widget.student['saved_data'] as String?;

    if (kDebugMode) {
      print(
        'DEBUG: [TeacherQuizPreviewPage] Student: ${widget.student['name']}',
      );
      print(
        'DEBUG: [TeacherQuizPreviewPage] index_files present: ${indexFilesStr != null}',
      );
      if (indexFilesStr != null) {
        print(
          'DEBUG: [TeacherQuizPreviewPage] index_files length: ${indexFilesStr.length}',
        );
      }
    }

    if (indexFilesStr != null) {
      try {
        final Map<String, dynamic> indexFiles = jsonDecode(indexFilesStr);
        final levelId = widget.level.levelId!;
        final studentId = widget.student['user_id']?.toString();

        for (final type in ['html', 'css', 'js', 'php']) {
          final content = indexFiles[type] as String?;
          if (content != null) {
            if (kDebugMode) {
              print(
                'DEBUG: [TeacherQuizPreviewPage] Writing index.$type, length: ${content.length}',
              );
            }
            await _storage.saveIndexFile(
              levelId: levelId,
              type: type,
              content: content,
              userId: studentId,
            );
          } else {
            if (kDebugMode)
              print(
                'DEBUG: [TeacherQuizPreviewPage] content for $type is NULL',
              );
          }
        }
      } catch (e) {
        print("Error parsing index files: $e");
      }
    } else if (savedDataStr != null) {
      // Fallback to saved_data if index_files is not present (legacy)
      if (kDebugMode)
        print('DEBUG: [TeacherQuizPreviewPage] Falling back to saved_data');
      try {
        final Map<String, dynamic> savedData = jsonDecode(savedDataStr);
        final levelId = widget.level.levelId!;
        final studentId = widget.student['user_id']?.toString();

        for (final type in ['html', 'css', 'js', 'php']) {
          final content = savedData[type] as String?;
          if (content != null) {
            await _storage.saveIndexFile(
              levelId: levelId,
              type: type,
              content: content,
              userId: studentId,
            );
          }
        }
      } catch (e) {
        print("Error parsing saved data: $e");
      }
    } else {
      if (kDebugMode)
        print(
          'DEBUG: [TeacherQuizPreviewPage] NO DATA FOUND for student preview',
        );
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.student['name']}'s Submission")),
      body: _loading || _serverUrl == null
          ? const Center(child: CircularProgressIndicator())
          : IndexFilePreview(
              userRole: 'teacher',
              serverUrl: _serverUrl!,
              levelId: widget.level.levelId!,
            ),
    );
  }
}