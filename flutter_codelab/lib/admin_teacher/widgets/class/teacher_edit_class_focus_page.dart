import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/constants/class_constants.dart';
import 'package:code_play/admin_teacher/widgets/class/class_theme_extensions.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class TeacherEditClassFocusPage extends StatefulWidget {
  final String classId;
  final String? currentFocus;
  final String className;

  const TeacherEditClassFocusPage({
    Key? key,
    required this.classId,
    this.currentFocus,
    required this.className,
  }) : super(key: key);

  @override
  State<TeacherEditClassFocusPage> createState() =>
      _TeacherEditClassFocusPageState();
}

class _TeacherEditClassFocusPageState extends State<TeacherEditClassFocusPage> {
  String? _selectedFocus;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedFocus = widget.currentFocus;
  }

  Future<void> _saveFocus() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    final result = await ClassApi.updateClassFocus(
      widget.classId,
      _selectedFocus,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.classFocusUpdatedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate change
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? l10n.failedToUpdateClassFocus),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.editClassFocus),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ClassConstants.cardPadding),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: ClassConstants.formMaxWidth),
            decoration: ClassTheme.cardDecoration(context),
            padding: EdgeInsets.all(ClassConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.editFocusFor(widget.className),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.youCanOnlyEditFocus,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: ClassConstants.sectionSpacing),

                // Focus Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFocus,
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: ClassTheme.inputDecoration(
                    context: context,
                    labelText: l10n.focusOptional,
                    icon: Icons.category,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.noneOptional),
                    ),
                    const DropdownMenuItem(value: 'HTML', child: Text('HTML')),
                    const DropdownMenuItem(value: 'CSS', child: Text('CSS')),
                    const DropdownMenuItem(
                      value: 'JavaScript',
                      child: Text('JavaScript'),
                    ),
                    const DropdownMenuItem(value: 'PHP', child: Text('PHP')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFocus = value);
                  },
                ),

                SizedBox(height: ClassConstants.sectionSpacing),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _saveFocus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ClassConstants.inputBorderRadius,
                          ),
                        ),
                      ),
                      child: _loading
                          ? CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                            )
                          : Text(l10n.saveChanges),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
