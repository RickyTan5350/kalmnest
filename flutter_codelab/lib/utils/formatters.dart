import 'package:flutter/services.dart';

class MalaysianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Remove any non-digits
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 2. Limit the length if necessary (max 10-11 digits is typical malaysia standard, but we'll just format prefixes)

    // 3. Logic to insert dash
    // Typical format: 01x-xxxxxxx or 011-xxxxxxxx
    // We insert dash after index 2 (3rd char) if length > 3

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;

      // Auto-insert dash after 3rd digit (e.g. 012 -> 012-)
      if (nonZeroIndex == 3 && text.length > 3) {
        buffer.write('-');
      }
    }

    // 4. Return new value
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
