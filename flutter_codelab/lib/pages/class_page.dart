import 'package:flutter/material.dart';
import '../widgets/class_list_statistic.dart';
import '../widgets/class_list_section.dart';
import '../widgets/bottom_navigation_bar.dart';
// import '../widgets/search_bar.dart' as custom_search; // add a prefix
// import '../models/models.dart';

class ClassPage extends StatelessWidget {
  const ClassPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Class statistics
                const ClassStatisticsSection(),
                const SizedBox(height: 16),

                // Search bar (use prefix)
                SizedBox(
                  width: 300,
                  child: SearchBar(
                    hintText: "Class Name",
                    trailing: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Class list
                const Expanded(child: ClassListSection()),
                const SizedBox(height: 16),

                // At the bottom of your Column
                const BottomNavigationBarWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
