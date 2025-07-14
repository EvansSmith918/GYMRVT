import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 121, 6, 6),
        elevation: 0,
        title: const Text('Welcome Back, Jobby', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChallengeCard(),
            const SizedBox(height: 20),
            const Text('Recommended Workout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _WorkoutTile(title: "Legs", subtitle: "12 Tutorials • 60 min"),
            _WorkoutTile(title: "Core", subtitle: "8 Tutorials • 30 min"),
            _WorkoutTile(title: "Back", subtitle: "10 Tutorials • 45 min"),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF101010),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("We have a new Challenge!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text("200 Steps", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(Icons.directions_run, color: Colors.white, size: 40),
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final String title, subtitle;
  const _WorkoutTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: const CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white12,
        child: Icon(Icons.play_arrow, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
    );
  }
}
