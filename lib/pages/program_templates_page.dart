import 'package:flutter/material.dart';
import 'package:gymrvt/services/program_templates.dart';

class ProgramTemplatesPage extends StatelessWidget {
  const ProgramTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Program Templates'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView.builder(
        itemCount: ProgramTemplates.all.length,
        itemBuilder: (_, i) {
          final t = ProgramTemplates.all[i];
          return Card(
            child: ExpansionTile(
              title: Text(t.name),
              children: [
                ...t.days.map((d) => ListTile(
                      title: Text(d.title),
                      subtitle: Text(d.items.map((e) => e.name).join(', ')),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await ProgramTemplates.applyDayToToday(d);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Applied ${t.name} • ${d.title} to Today')),
                            );
                          }
                        },
                        child: const Text('Apply to Today'),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
