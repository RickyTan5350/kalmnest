import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue; // Or yellow/light green depending on preference
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final color = _getStrengthColor(strength);
    final label = _getStrengthLabel(strength);

    if (password.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Visual bars
              Expanded(
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4.0),
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: index < strength
                              ? color
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Use 8+ characters, with uppercase, numbers, and symbols.',
            style: TextStyle(color: Colors.grey, fontSize: 11.0),
          ),
        ],
      ),
    );
  }
}
