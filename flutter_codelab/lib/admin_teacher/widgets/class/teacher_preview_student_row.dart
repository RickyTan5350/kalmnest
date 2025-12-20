import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/student.dart';

class StudentPreviewRow extends StatelessWidget {
  final List<Student> students;
  final VoidCallback onViewAll;

  const StudentPreviewRow({
    super.key,
    required this.students,
    required this.onViewAll,
  });

  Widget _studentCard(BuildContext context, Student student) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1E5EA)),
        color: const Color(0xFFE7F9FF),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFCFEFF7),
            child: Text(
              student.name,
              style: const TextStyle(
                color: Color(0xFF004B63),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              student.fullName,
              style: const TextStyle(color: Color(0xFF004B63), fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Proper "OTHERS" card
  Widget _othersCard(BuildContext context, int extra) {
    return InkWell(
      onTap: onViewAll,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade700,
              child: const Icon(Icons.group, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$extra more",
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No students have been enrolled in this class yet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final shown = students.take(6).toList();
    final extra = students.length - shown.length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'List of enrolled students',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: onViewAll,
                  child: const Text("View All"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Horizontal scroll of student cards + others card
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...shown.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _studentCard(context, s),
                    ),
                  ),

                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _othersCard(context, extra),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
