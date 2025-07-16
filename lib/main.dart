import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/workout_page.dart';
import 'pages/camera_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const GymRVTApp());
}

class GymRVTApp extends StatelessWidget {
  const GymRVTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GYMRVT',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF101010),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const NavigationRoot(),
    );
  }
}

class NavigationRoot extends StatefulWidget {
  const NavigationRoot({super.key});

  @override
  State<NavigationRoot> createState() => _NavigationRootState();
}

class _NavigationRootState extends State<NavigationRoot> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    WorkoutPage(),
    CameraPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF101010),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
