import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';

/// Full-page student view: all quizzes for a single class.
///
/// - Fetches class data by [classId] to show class name & description
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

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  Future<void> _fetchClassData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await ClassApi.fetchClassById(widget.classId);
    if (!mounted) return;
    setState(() {
      _classData = data;
      _loading = false;
    });
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
                      side: BorderSide(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          Expanded(
                            child: _StudentStatCard(
                              title: 'Total Quizzes',
                              value: '10',
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _StudentStatCard(
                              title: 'Last Updated',
                              value: '2 days ago',
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
                      side: BorderSide(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'Quizzes',
                            subtitle: 'All quizzes for this class',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search,
                                color: cs.onSurfaceVariant,
                              ),
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
                          Column(
                            children: const [
                              _StudentQuizItem(
                                title: 'Chapter 5: Integration Techniques',
                                meta: '15 Questions • Uploaded: Nov 26, 2025',
                              ),
                              SizedBox(height: 12),
                              _StudentQuizItem(
                                title: 'Statistical Distribution Tables',
                                meta: '20 Questions • Uploaded: Nov 24, 2025',
                              ),
                              SizedBox(height: 12),
                              _StudentQuizItem(
                                title: 'Practice Problems Set 4',
                                meta: '12 Questions • Uploaded: Nov 22, 2025',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing 1 to 10 of 12 entries',
                                style: textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Previous',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const _PageChip(label: '1', active: true),
                                  const _PageChip(label: '2'),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Next',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          className,
          style: textTheme.titleMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
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
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentQuizItem extends StatelessWidget {
  final String title;
  final String meta;

  const _StudentQuizItem({required this.title, required this.meta});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
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
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meta,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  final String label;
  final bool active;

  const _PageChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: active ? cs.onPrimary : cs.onSurfaceVariant,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
        ),
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
