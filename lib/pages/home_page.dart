import 'package:flutter/material.dart';
import 'package:mi_boti/models/med_model.dart';
import 'package:mi_boti/pages/add_med_page.dart';
import 'package:mi_boti/pages/history_page.dart';
import 'package:mi_boti/pages/settings_page.dart';
import 'package:mi_boti/widgets/medication_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repo});
  final MedRepository repo;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    widget.repo.addListener(_onRepo);
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    super.dispose();
  }

  void _onRepo() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text('MIBOTIQUIN', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.bold)),
            Text('Recordatorio de medicamentos', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, SettingsPage.route),
          icon: const Icon(Icons.settings),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, HistoryPage.route),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoy', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: widget.repo.meds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => MedicationTile(med: widget.repo.meds[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'history',
            onPressed: () => Navigator.pushNamed(context, HistoryPage.route),
            child: const Icon(Icons.history),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => Navigator.pushNamed(context, AddMedPage.route),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
