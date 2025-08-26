// lib/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymrvt/services/appearance_prefs.dart';
import 'package:gymrvt/services/weight_history.dart';
import 'package:gymrvt/widgets/app_background.dart';
import 'package:gymrvt/pages/profile_overview_page.dart';
import 'package:gymrvt/services/health_service.dart'; // NEW

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchesController = TextEditingController();

  String _gender = 'Male';
  File? _profileImage;

  bool _healthConnected = false;

  final AppearancePrefs _appearance = AppearancePrefs();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _ageController.text = prefs.getString('age') ?? '';
      _weightController.text = prefs.getString('weight') ?? '';
      _heightFeetController.text = prefs.getString('height_feet') ?? '';
      _heightInchesController.text = prefs.getString('height_inches') ?? '';
      _gender = prefs.getString('gender') ?? 'Male';
      _healthConnected = prefs.getBool('health_connected') ?? false;

      final imagePath = prefs.getString('profileImage');
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _saveProfile(BuildContext bc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text.trim());
    await prefs.setString('age', _ageController.text.trim());
    await prefs.setString('weight', _weightController.text.trim());
    await prefs.setString('height_feet', _heightFeetController.text.trim());
    await prefs.setString('height_inches', _heightInchesController.text.trim());
    await prefs.setString('gender', _gender);
    await prefs.setBool('profile_complete', true);

    if (_profileImage != null) {
      await prefs.setString('profileImage', _profileImage!.path);
    }

    final w = double.tryParse(_weightController.text.trim());
    if (w != null && w > 0) {
      await WeightHistory().upsertToday(w);
    }

    if (!mounted) return;
    Navigator.of(bc).pushReplacement(
      MaterialPageRoute(builder: (BuildContext _) => const ProfileOverviewPage()),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = basename(picked.path);
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    if (!mounted) return;
    setState(() => _profileImage = savedImage);
  }

  Future<void> _pickBgColor(BuildContext bc) async {
    Color tmp = _appearance.state.color;
    final selected = await showDialog<Color?>(
      context: bc,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Background color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: tmp,
            onColorChanged: (c) => tmp = c,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, tmp), child: const Text('Use color')),
        ],
      ),
    );
    if (selected != null) {
      await _appearance.setColor(selected);
    }
  }

  Future<void> _pickBgImage(BuildContext bc) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final fname = 'bg_${DateTime.now().millisecondsSinceEpoch}${extension(picked.path)}';
    final saved = await File(picked.path).copy('${dir.path}/$fname');

    await _appearance.setImage(saved.path);
  }

  //  Real HealthKit / Google Fit integration
  Future<void> _connectToHealthApps(BuildContext bc) async {
    final ok = await HealthService.instance.requestAuthorization();
    if (!mounted) return;

    if (!ok) {
      setState(() => _healthConnected = false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_connected', false);
      ScaffoldMessenger.of(bc).showSnackBar(
        const SnackBar(content: Text('Health permission denied. Enable it in Settings.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_connected', true);

    final latestLb = await HealthService.instance.latestBodyMassLb();
    if (latestLb != null) {
      await WeightHistory().upsertToday(latestLb);
      _weightController.text = latestLb.toStringAsFixed(1);
    }

    if (!mounted) return;
    setState(() => _healthConnected = true);
    ScaffoldMessenger.of(bc).showSnackBar(
      const SnackBar(content: Text('Connected to Health.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Builder(
          builder: (BuildContext bc) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null ? const Icon(Icons.person, size: 48) : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _field('Name', _nameController),
                  _field('Age', _ageController, isNumber: true),
                  _field('Weight (lbs)', _weightController, isNumber: true),
                  _heightRow(),
                  _genderDropdown(),

                  const SizedBox(height: 16),

                  AnimatedBuilder(
                    animation: _appearance,
                    builder: (BuildContext _, __) {
                      final s = _appearance.state;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Appearance',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.type == BgType.color
                                          ? 'Using background color'
                                          : (s.imagePath != null
                                              ?''
                                              : 'No image set'),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _pickBgColor(bc),
                                    icon: const Icon(Icons.palette),
                                    label: const Text('Color'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _pickBgImage(bc),
                                    icon: const Icon(Icons.image),
                                    label: const Text('Image'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (s.type == BgType.image)
                                    TextButton(
                                      onPressed: _appearance.useColorMode,
                                      child: const Text('Use color'),
                                    ),
                                ],
                              ),
                              if (s.type == BgType.image && s.imagePath != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(s.imagePath!),
                                      height: 80,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveProfile(bc),
                          child: const Text('Save Profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _connectToHealthApps(bc),
                          icon: Icon(_healthConnected
                              ? Icons.health_and_safety
                              : Icons.health_and_safety_outlined),
                          label: Text(_healthConnected
                              ? 'Connected'
                              : 'Connect to Health'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---- helpers ----
  Widget _field(String label, TextEditingController c, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _heightRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: _field('Height (ft)', _heightFeetController, isNumber: true)),
          const SizedBox(width: 12),
          Expanded(child: _field('Height (in)', _heightInchesController, isNumber: true)),
        ],
      ),
    );
  }

  Widget _genderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _gender,
        items: const ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _gender = v ?? 'Male'),
        decoration: InputDecoration(
          labelText: 'Gender',
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
