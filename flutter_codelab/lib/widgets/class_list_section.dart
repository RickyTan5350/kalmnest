import 'package:flutter/material.dart';
import '../api/class_api.dart';
import 'edit_class_page.dart';

class ClassListSection extends StatefulWidget {
  const ClassListSection({Key? key}) : super(key: key);

  @override
  State<ClassListSection> createState() => _ClassListSectionState();
}

class _ClassListSectionState extends State<ClassListSection> {
  int currentPage = 1;
  int totalPages = 1;
  bool loading = true;
  List<dynamic> classList = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  void _onEditClass(dynamic item) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditClassPage(classData: item),
      ),
    );

    if (updated == true) {
      loadClasses(); // refresh after edit
    }
  }

  void _onDeleteClass(dynamic item) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Class"),
          content: Text(
            "Are you sure you want to delete '${item['class_name']}'?",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await ClassApi.deleteClass(item['class_id']);
      if (success) {
        loadClasses(); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete class")),
        );
      }
    }
  }

  Future<void> loadClasses() async {
    try {
      final json = await ClassApi.fetchClasses(currentPage);

      setState(() {
        classList = json['data'];
        totalPages = json['last_page'];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> buttons = [];
    int start = currentPage - 1;
    int end = currentPage + 1;

    if (start < 1) {
      start = 1;
      end = (totalPages >= 3) ? 3 : totalPages;
    }

    if (end > totalPages) {
      end = totalPages;
      start = (totalPages - 2 > 1) ? totalPages - 2 : 1;
    }

    for (int page = start; page <= end; page++) {
      buttons.add(_pageNumber(page));
      if (page != end) buttons.add(const SizedBox(width: 8));
    }

    return buttons;
  }

  Widget _pageNumber(int page) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = page == currentPage;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentPage = page;
          loading = true;
        });
        loadClasses(); // IMPORTANT
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _pageButton(IconData icon, Function() onTap) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ===== Header =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class List',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  loading ? "Loading..." : "${classList.length} entries",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          if (loading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),

          if (!loading)
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(
                                  0.4,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.school_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['class_name'] ?? 'No Name',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    item['description']?.isNotEmpty == true
                                        ? item['description']
                                        : "No description",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: colorScheme.onSurface,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _onEditClass(item);
                                } else if (value == 'delete') {
                                  _onDeleteClass(item);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Edit",
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withOpacity(0.4),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageButton(Icons.chevron_left, () {
                  if (currentPage > 1) {
                    setState(() {
                      currentPage--;
                      loading = true;
                    });
                    loadClasses();
                  }
                }),
                const SizedBox(width: 8),
                ..._buildPageNumbers(),
                const SizedBox(width: 8),
                _pageButton(Icons.chevron_right, () {
                  if (currentPage < totalPages) {
                    setState(() {
                      currentPage++;
                      loading = true;
                    });
                    loadClasses();
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
