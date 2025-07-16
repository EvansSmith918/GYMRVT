// lib/pages/profile_page.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF101010),
      ),
      backgroundColor: const Color(0xFF101010),
      body: const Center(
        child: Text(
          'Profile Page',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
