import 'package:flutter/material.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}

class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbNavigation({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // Scrollable row for long breadcrumbs
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Row(
            children: [
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              InkWell(
                onTap: isLast ? null : item.onTap,
                borderRadius: BorderRadius.circular(4.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isLast
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                      // Accessing textTheme correctly
                      fontSize: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.fontSize,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
