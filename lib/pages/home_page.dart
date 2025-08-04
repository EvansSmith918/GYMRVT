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

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('name');
    String? imagePath = prefs.getString('profileImage');

    setState(() {
      _userName = name;
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      }
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
                    'Welcome Back, $_userName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (_userName != null) const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We have a new challenge!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '200 Steps',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.directions_walk, color: Colors.white, size: 36),
                ],
              ),
            ),
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
