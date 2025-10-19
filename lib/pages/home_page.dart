import 'package:flutter/material.dart';
import 'package:mi_boti/pages/add_med_page.dart';
import 'package:mi_boti/pages/history_page.dart';
import 'package:mi_boti/pages/settings_page.dart';
import 'package:mi_boti/repository/med_repository.dart';
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
    final meds = widget.repo.meds;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Mi BotiquA-n',
              style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.bold),
            ),
            Text(
              'Recordatorio de medicamentos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsPage(repo: widget.repo)),
          ),
          icon: const Icon(Icons.settings),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 1100
                ? 48.0
                : width >= 720
                ? 32.0
                : 16.0;
            final maxContentWidth = width >= 900
                ? 720.0
                : width >= 640
                ? 560.0
                : double.infinity;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hoy', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Expanded(
                    child: meds.isEmpty
                        ? const _EmptyMedicationState()
                        : Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxContentWidth,
                              ),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: meds.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) {
                                  final med = meds[i];
                                  return Dismissible(
                                    key: ValueKey(med.key ?? '${med.name}-$i'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      color: Colors.red,
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Eliminar'),
                                              content: Text(
                                                'Eliminar "${med.name}" y su alarma?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('Eliminar'),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                    },
                                    onDismissed: (_) async {
                                      await widget.repo.removeMedication(med);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${med.name} eliminado',
                                          ),
                                        ),
                                      );
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        final int? medKey = med.key as int?;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddMedPage(
                                              repo: widget.repo,
                                              existing: med,
                                              medKey: medKey,
                                            ),
                                          ),
                                        );
                                      },
                                      child: MedicationTile(med: med),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'history',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryPage(repo: widget.repo)),
            ),
            child: const Icon(Icons.history),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddMedPage(repo: widget.repo)),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _EmptyMedicationState extends StatelessWidget {
  const _EmptyMedicationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay medicamentos programados para hoy.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa el boton + para agregar tu primera alarma.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
