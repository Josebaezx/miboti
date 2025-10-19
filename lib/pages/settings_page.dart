import 'package:flutter/material.dart';
import 'package:mi_boti/repository/med_repository.dart';

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
      appBar: AppBar(title: const Text('Configuracion')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 900
                ? 48.0
                : width >= 600
                ? 32.0
                : 16.0;
            final maxContentWidth = width >= 720 ? 560.0 : double.infinity;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('Sonido'),
                        value: sound,
                        onChanged: (v) => setState(() => sound = v),
                      ),
                      SwitchListTile(
                        title: const Text('Vibracion'),
                        value: vibration,
                        onChanged: (v) => setState(() => vibration = v),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.notifications, size: 30),
                                  SizedBox(width: 12),
                                  Text(
                                    'Hora de tomar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('Ibuprofeno 400 mg'),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, buttonConstraints) {
                                  final stackButtons =
                                      buttonConstraints.maxWidth < 360;
                                  if (stackButtons) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        FilledButton(
                                          onPressed: () {},
                                          child: const Text('Tomar ahora'),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                          onPressed: () {},
                                          child: const Text('Posponer 10 min'),
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () {},
                                          child: const Text('Tomar ahora'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () {},
                                        child: const Text('Posponer 10 min'),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Nota: Esta app es una demo de UI, sin notificaciones reales.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
