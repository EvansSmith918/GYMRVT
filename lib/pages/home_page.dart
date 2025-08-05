// lib/pages/home_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;
  File? _profileImage;
  int _todayReps = 0;
  bool _isHealthConnected = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name');
      _isHealthConnected = prefs.getBool('health_connected') ?? false;

      String? imagePath = prefs.getString('profileImage');
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      }

      // You can later replace this with actual logic to pull from SQLite or Health
      _todayReps = prefs.getInt('reps_today') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userName != null)
              Row(
                children: [
                  if (_profileImage != null)
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: FileImage(_profileImage!),
                    )
                  else
                    const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    'Welcome Back, $_userName 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (_userName != null) const SizedBox(height: 20),

            _buildRepsCard(_todayReps, healthConnected: _isHealthConnected),
            const SizedBox(height: 24),

            const Text(
              'Recommended Workouts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildWorkoutItem('Legs', '12 Tutorials • 60 min'),
            _buildWorkoutItem('Core', '8 Tutorials • 30 min'),
            _buildWorkoutItem('Back', '10 Tutorials • 45 min'),
          ],
        ),
      ),
    );
  }

  Widget _buildRepsCard(int reps, {bool healthConnected = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                healthConnected ? 'Synced from Health App' : 'Tracked Locally',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Reps Today',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$reps Reps',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Icon(
            healthConnected ? Icons.verified_user : Icons.fitness_center,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white12,
            child: Icon(Icons.play_arrow, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
