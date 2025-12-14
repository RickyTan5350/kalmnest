import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/user_list_content.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Padding around the card
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding inside the card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Users',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                // Replaced '---Users---' with the actual widget content
                const Expanded(
                  child: UserListContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}