import 'package:flutter/material.dart';

class QuizWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizWidget({
    Key? key,
    required this.question,
    required this.options,
    required this.correctIndex,
  }) : super(key: key);

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int? _selectedIndex;
  bool _isAnswered = false;

  void _handleOptionTap(int index) {
    if (_isAnswered) return; // Prevent changing answer after selection

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
    });
  }

  Color _getOptionColor(int index) {
    if (!_isAnswered) {
      return Colors.white; // Default background before answering
    }

    if (index == widget.correctIndex) {
      return Colors.green.shade100; // Correct answer shows green
    }

    if (index == _selectedIndex && index != widget.correctIndex) {
      return Colors.red.shade100; // Selected wrong answer shows red
    }

    return Colors.grey.shade200; // Other options grey out
  }

  Color _getBorderColor(int index) {
    if (!_isAnswered) {
      return Colors.grey.shade300;
    }
    if (index == widget.correctIndex) {
      return Colors.green;
    }
    if (index == _selectedIndex && index != widget.correctIndex) {
      return Colors.red;
    }
    return Colors.grey.shade300;
  }

  IconData? _getOptionIcon(int index) {
    if (!_isAnswered) return Icons.radio_button_unchecked;

    if (index == widget.correctIndex) {
      return Icons.check_circle;
    }

    if (index == _selectedIndex && index != widget.correctIndex) {
      return Icons.cancel;
    }

    return Icons.radio_button_unchecked;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(widget.question, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ...List.generate(widget.options.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: () => _handleOptionTap(index),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: _getOptionColor(index),
                      border: Border.all(color: _getBorderColor(index)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getOptionIcon(index),
                          color: _getBorderColor(index) == Colors.grey.shade300
                              ? Colors.grey
                              : _getBorderColor(index),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.options[index],
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  _isAnswered &&
                                      index != widget.correctIndex &&
                                      index != _selectedIndex
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_isAnswered)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _selectedIndex == widget.correctIndex
                      ? "Betul! Tahniah."
                      : "Salah. Jawapan betul ialah: ${widget.options[widget.correctIndex]}",
                  style: TextStyle(
                    color: _selectedIndex == widget.correctIndex
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
