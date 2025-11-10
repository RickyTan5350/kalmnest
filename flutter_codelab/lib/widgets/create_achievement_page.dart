import 'package:flutter/material.dart';

class CreateAchievementPage extends StatefulWidget {
  const CreateAchievementPage({Key? key}) : super(key: key);

  @override
  State<CreateAchievementPage> createState() => _CreateAchievementPageState();
}

class _CreateAchievementPageState extends State<CreateAchievementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Clean up the controllers when the widget is disposed
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveAchievement() {
    if (_formKey.currentState!.validate()) {
      // Get the data from the form
      final String name = _nameController.text;
      final String description = _descriptionController.text;

      // TODO: Add your logic here to save the achievement
      // (e.g., send to API, save to database)

      print('Saving Achievement: $name, $description');

      // Go back to the previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a dark theme AppBar to match your UI
      appBar: AppBar(
        title: Text('Create New Achievement'),
        backgroundColor: Color(0xFF1E1E2F), // Adjust color to match your theme
        elevation: 0,
      ),
      // Set background color to match your app
      backgroundColor: Color(0xFF1E1E2F), // Adjust color to match your theme
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Achievement Name',
                  // Add styling here to match your other text fields
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveAchievement,
                child: Text('Save Achievement'),
                // Add styling to your button
              ),
            ],
          ),
        ),
      ),
    );
  }
}