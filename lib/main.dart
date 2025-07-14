import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/workout_page.dart';
import 'pages/camera_page.dart';
import 'pages/profile_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GYMRVT',
      theme: ThemeData.dark(),
      home: const HomePage(),
      routes: {
        '/workout': (context) => const WorkoutPage(),
        '/camera': (context) => const CameraPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
