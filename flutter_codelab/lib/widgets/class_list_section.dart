import 'package:flutter/material.dart';
// import '../theme.dart';
// import '../util.dart';

class ClassItem {
  final String emoji;
  final String title;
  final String description;

  ClassItem({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

class ClassListSection extends StatefulWidget {
  const ClassListSection({Key? key}) : super(key: key);

  @override
  State<ClassListSection> createState() => _ClassListSectionState();
}

class _ClassListSectionState extends State<ClassListSection> {
  int currentPage = 2;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final classList = [
      ClassItem(
        emoji: '📚',
        title: 'Math 101',
        description: 'Introduction to Algebra',
      ),
      ClassItem(
        emoji: '📖',
        title: 'History 202',
        description: 'World History',
      ),
      ClassItem(
        emoji: '🔬',
        title: 'Science 303',
        description: 'Biology Basics',
      ),
      ClassItem(
        emoji: '🔬',
        title: 'Science 303',
        description: 'Biology Basics',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest, // theme color
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class List',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
                Text(
                  '2 of 28 entries',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Class items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: classList.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == classList.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                item.emoji,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: colorScheme.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                                Text(
                                  item.description,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.menu,
                            size: 20,
                            color: colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        color: colorScheme.outline,
                        height: 1,
                        thickness: 1,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Pagination
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.onSurface, width: 1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {
                      if (currentPage > 1) setState(() => currentPage--);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildPageNumber(context, 1),
                  const SizedBox(width: 8),
                  _buildPageNumber(context, 2),
                  const SizedBox(width: 8),
                  _buildPageNumber(context, 3),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: colorScheme.onSurface),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {
                      if (currentPage < 3) setState(() => currentPage++);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(BuildContext context, int page) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = currentPage == page;

    return GestureDetector(
      onTap: () => setState(() => currentPage = page),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          '$page',
          style: textTheme.titleMedium?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.surface : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
