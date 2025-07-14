import 'package:flutter/material.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(title: const Text('Workouts')),
      body: const Center(child: Text('Workout Page', style: TextStyle(color: Colors.white))),
    );
  }
}
