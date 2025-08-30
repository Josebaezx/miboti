import 'package:flutter/material.dart';
import 'package:mi_boti/models/med_model.dart';

class SettingsPage extends StatefulWidget {
  static const route = '/settings';
  const SettingsPage({super.key, required this.repo});
  final MedRepository repo;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool sound = true;
  bool vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Sonido'),
              value: sound,
              onChanged: (v) => setState(() => sound = v),
            ),
            SwitchListTile(
              title: const Text('Vibración'),
              value: vibration,
              onChanged: (v) => setState(() => vibration = v),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.notifications, size: 30),
                        SizedBox(width: 12),
                        Text('Hora de tomar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Ibuprofeno 400 mg'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: FilledButton(onPressed: () {}, child: const Text('Tomar ahora'))),
                        const SizedBox(width: 12),
                        OutlinedButton(onPressed: () {}, child: const Text('Posponer 10 min')),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text('Nota: Esta app es una demo de UI, sin notificaciones reales.', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
