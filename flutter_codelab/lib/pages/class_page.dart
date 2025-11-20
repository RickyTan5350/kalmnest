import 'package:flutter/material.dart';
import '../widgets/class_list_statistic.dart';
import '../widgets/class_list_section.dart';
import '../widgets/create_class_page.dart';
// import '../widgets/search_bar.dart';

class ClassPage extends StatelessWidget {
  const ClassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Class"),
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateClassScreen(),
            ),
          );
        },
        child: Icon(
          Icons.add,
          color: colorScheme.onPrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ClassStatisticsSection(),
            const SizedBox(height: 20),

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

            const SizedBox(height: 20),
            const Expanded(child: ClassListSection()),
          ],
        ),
      ),
    );
  }
}

