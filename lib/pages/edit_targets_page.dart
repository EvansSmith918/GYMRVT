import 'package:flutter/material.dart';
import 'package:gymrvt/services/nutrition_store.dart';

class EditTargetsPage extends StatefulWidget {
  const EditTargetsPage({super.key});

  @override
  State<EditTargetsPage> createState() => _EditTargetsPageState();
}

class _EditTargetsPageState extends State<EditTargetsPage> {
  final _calC = TextEditingController();
  final _pC = TextEditingController();
  final _cC = TextEditingController();
  final _fC = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // NutritionStore.getTargets() returns a map: { cals, protein, carbs, fat }
    final t = await NutritionStore().getTargets();
    setState(() {
      _calC.text = (t['cals'] as num).toStringAsFixed(0);
      _pC.text = (t['protein'] as num).toStringAsFixed(0);
      _cC.text = (t['carbs'] as num).toStringAsFixed(0);
      _fC.text = (t['fat'] as num).toStringAsFixed(0);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final cals = int.tryParse(_calC.text) ?? 2000;
    final p = double.tryParse(_pC.text) ?? 150;
    final c = double.tryParse(_cC.text) ?? 200;
    final f = double.tryParse(_fC.text) ?? 70;

    await NutritionStore().setTargets(
      cals: cals,
      protein: p,
      carbs: c,
      fat: f,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, true); // tell caller that something changed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit nutrition goals")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _calC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Calories (kcal)",
              prefixIcon: Icon(Icons.local_fire_department),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Protein (g)",
              prefixIcon: Icon(Icons.egg_alt),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Carbs (g)",
              prefixIcon: Icon(Icons.rice_bowl),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Fat (g)",
              prefixIcon: Icon(Icons.bakery_dining),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? "Saving…" : "Save goals"),
          ),
        ],
      ),
    );
  }
}
