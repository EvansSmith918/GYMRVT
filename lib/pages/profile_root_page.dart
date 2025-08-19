// lib/pages/profile_root_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymrvt/pages/profile_page.dart';
import 'package:gymrvt/pages/profile_overview_page.dart';
import 'package:gymrvt/widgets/app_background.dart';

class ProfileRoot extends StatefulWidget {
  const ProfileRoot({super.key});

  @override
  State<ProfileRoot> createState() => _ProfileRootState();
}

class _ProfileRootState extends State<ProfileRoot> {
  bool? _complete;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Explicit flag, or treat as complete if a name exists.
    final done = prefs.getBool('profile_complete') ??
        ((prefs.getString('name') ?? '').trim().isNotEmpty);
    if (!mounted) return;
    setState(() => _complete = done);
  }

  @override
  Widget build(BuildContext context) {
    // Use the same global background for consistency
    return AppBackground(
      child: (_complete == null)
          ? const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: CircularProgressIndicator()),
            )
          : (_complete! ? const ProfileOverviewPage() : const ProfilePage()),
    );
  }
}
