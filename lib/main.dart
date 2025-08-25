// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/workout_page.dart';
import 'pages/photo_advisor_page.dart'; // <-- use photo upload analysis page
import 'pages/profile_root_page.dart'; // <-- root for profile flow
import 'widgets/app_background.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gymrvt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // Clamp extreme text scaling and ensure SafeArea for every page
      builder: (context, child) {
        final clamped = MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clamped),
          child: SafeArea(top: true, bottom: true, child: child!),
        );
      },
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    HomePage(),
    WorkoutPage(),
    PhotoAdvisorPage(), // <-- swapped in here
    ProfileRoot(),      // <-- instead of ProfilePage
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        (widget.initialIndex >= 0 && widget.initialIndex < _pages.length)
            ? widget.initialIndex
            : 0;
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[400],
        backgroundColor: const Color(0xFF181818),
        type: BottomNavigationBarType.fixed,
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
