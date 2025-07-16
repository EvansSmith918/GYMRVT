// lib/pages/workout_page.dart
import 'package:flutter/material.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        backgroundColor: const Color(0xFF101010),
      ),
      backgroundColor: const Color(0xFF101010),
      body: const Center(
        child: Text(
          'Workout Page',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
