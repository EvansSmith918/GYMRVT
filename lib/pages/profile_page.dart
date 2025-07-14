import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page', style: TextStyle(color: Colors.white))),
    );
  }
}
