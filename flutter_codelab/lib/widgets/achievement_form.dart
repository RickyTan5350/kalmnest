// lib/widgets/achievement_form.dart

import 'package:flutter/material.dart';

// 1. Define the options for your radio buttons
enum AchievementType { level, quiz }

// 2. This is the reusable widget class
class AchievementTypeRadio extends StatefulWidget {
  const AchievementTypeRadio({
    super.key,
    this.initialValue,
    required this.onTypeSelected,
  });

  // Use this to pre-select a value (e.g., when editing a form)
  final AchievementType? initialValue;

  // This is the callback function to send the data back to the parent form
  final void Function(AchievementType? selectedType) onTypeSelected;

  @override
  State<AchievementTypeRadio> createState() => _AchievementTypeRadioState();
}

class _AchievementTypeRadioState extends State<AchievementTypeRadio> {
  // 3. This variable holds the currently selected value
  AchievementType? _selectedType;

  @override
  void initState() {
    super.initState();
    // 4. Set the initial value when the widget is first created
    _selectedType = widget.initialValue;
  }

  // 5. This function updates the state and calls the callback
  void _onChanged(AchievementType? value) {
    setState(() {
      _selectedType = value;
    });
    // Send the new value back to the parent widget
    widget.onTypeSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A simple label for the group
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 16.0),
          child: Text(
            'Achievement Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // 6. The RadioListTile widgets
        RadioListTile<AchievementType>(
          title: const Text('Level'),
          subtitle: const Text('A single level in the syllabus'),
          value: AchievementType.level,
          groupValue: _selectedType,
          onChanged: _onChanged,
        ),
        RadioListTile<AchievementType>(
          title: const Text('Quiz'),
          subtitle: const Text('A custom quiz'),
          value: AchievementType.quiz,
          groupValue: _selectedType,
          onChanged: _onChanged,
        ),
      ],
    );
  }
}

class AchievementFormDialog extends StatefulWidget {
  const AchievementFormDialog({super.key});

  @override
  State<AchievementFormDialog> createState() => _AchievementFormDialogState();
}

class _AchievementFormDialogState extends State<AchievementFormDialog> {
  // 1. Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  // 2. Create controllers for the form fields
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedLevel;
  AchievementType? _selectedAchievementType;

  // 3. Remember to dispose of controllers
  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 4. Create the submit logic
  void _submitForm() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      // Form is valid, do something with the data
      final String achievementName = _nameController.text;
      final String description = _descriptionController.text;

      print('Achievement Name: $achievementName');
      print('Description: $description');
      print('Category: $_selectedCategory');

      // Close the dialog and pass back data (optional)
      Navigator.of(context).pop(true); // Pop with a success flag
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Achievement'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make the dialog content shrink-wrap
          children: [
            // Field 1: Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Achievement Name',
                icon: Icon(Icons.emoji_events),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Field 2: Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Displaying Achievment Title',
                icon: Icon(Icons.description),
              ),
              maxLines: 2, // Optional: for a larger text field
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Achievement Description',
                icon: Icon(Icons.description),
              ),
              maxLines: 2, // Optional: for a larger text field
            ),
            const SizedBox(height: 16),

            // Field 3: Description
            // Inside your Column:

            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Aligns icon with the top
              children: [
                // 1. The icon
                Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Adjust to vertically align
                  child: const Icon(Icons.category),
                ),

                // 2. The space
                const SizedBox(width: 16),

                // 3. The DropdownMenu
                Expanded(
                  child: DropdownMenu<String>(
                    width: MediaQuery.of(context).size.width * 0.2,
                    label: const Text('Category'),
                    onSelected: (String? value) {
                      // ...
                    },
                    dropdownMenuEntries: const <DropdownMenuEntry<String>>[
                      DropdownMenuEntry(value: 'html', label: 'HTML'),
                      DropdownMenuEntry(value: 'css', label: 'CSS'),
                      DropdownMenuEntry(value: 'js', label: 'JS'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligns icon with the top
              children: [
                // 1. The icon
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                  ), // Adjust to vertically align
                  child: const Icon(Icons.category),
                ),

                // 2. The space
                const SizedBox(width: 16),

                // 3. The DropdownMenu
                Expanded(
                  child: DropdownMenu<String>(
                    width: MediaQuery.of(context).size.width * 0.2,
                    label: const Text('Level Name'),
                    onSelected: (String? value) {
                      setState(() {
                        _selectedLevel = value;
                      });
                    },
                    dropdownMenuEntries: const <DropdownMenuEntry<String>>[
                      DropdownMenuEntry(
                        value: 'html',
                        label: 'Placeholder Level 1',
                      ),
                      DropdownMenuEntry(
                        value: 'css',
                        label: 'Placeholder Level 2',
                      ),
                      DropdownMenuEntry(
                        value: 'js',
                        label: 'Placeholder Level 3',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Field 4: Category
            const SizedBox(height: 16),

            const SizedBox(height: 16),
            AchievementTypeRadio(
              initialValue: _selectedAchievementType,
              onTypeSelected: (AchievementType? newType) {
                // Save the new type to your state variable
                setState(() {
                  _selectedAchievementType = newType;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        // Cancel Button
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Just close the dialog
          },
        ),
        // Save Button
        FilledButton(
          onPressed: _submitForm, // Call the submit logic
          child: const Text('Save'),
        ),
      ],
    );
  }
}