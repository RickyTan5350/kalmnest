import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(1, 201, 52, 52),
                Color.fromARGB(1, 201, 98, 98),
              ],
            ),
          ),
          child: const Center(child: Text('Hello world')),
        ),
      ),
    ),
  );
}
