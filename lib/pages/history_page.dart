import 'package:flutter/material.dart';
import 'package:mi_boti/models/med_model.dart';
import 'package:mi_boti/repository/med_repository.dart';

class HistoryPage extends StatefulWidget {
  static const route = '/history';
  const HistoryPage({super.key, required this.repo});
  final MedRepository repo;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _filterMedName;
  DateTime? _filterDate; // filtra por día

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
    // Construye lista de nombres de medicamento para el filtro
    final medNames = <String>{for (final h in widget.repo.history) h.medName}
      ..removeWhere((e) => e.trim().isEmpty);

    // Aplica filtros
    final entries = List.of(widget.repo.history)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final filtered = entries.where((e) {
      final okMed = _filterMedName == null || e.medName == _filterMedName;
      final okDate =
          _filterDate == null ||
          (e.dateTime.year == _filterDate!.year &&
              e.dateTime.month == _filterDate!.month &&
              e.dateTime.day == _filterDate!.day);
      return okMed && okDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          // Limpiar filtros
          if (_filterMedName != null || _filterDate != null)
            IconButton(
              tooltip: 'Limpiar filtros',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  _filterMedName = null;
                  _filterDate = null;
                });
              },
            ),
          if (widget.repo.history.isNotEmpty)
            IconButton(
              tooltip: 'Borrar todo',
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar todo el historial'),
                    content: const Text(
                      'Esta acción eliminará todas las entradas del historial. ¿Deseas continuar?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Borrar todo'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  // Respalda como objetos nuevos para evitar conflictos con HiveObject
                  final previous = widget.repo.history
                      .map(
                        (e) => HistoryEntry(
                          dateTime: e.dateTime,
                          medName: e.medName,
                          taken: e.taken,
                        ),
                      )
                      .toList();
                  await widget.repo.clearHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Historial eliminado'),
                      action: SnackBarAction(
                        label: 'Deshacer',
                        onPressed: () async {
                          // Restaurar todas las entradas
                          for (final e in previous) {
                            await widget.repo.addHistory(e);
                          }
                        },
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Filtro por medicamento
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _filterMedName,
                    decoration: const InputDecoration(
                      labelText: 'Medicamento',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...medNames.map(
                        (name) => DropdownMenuItem<String?>(
                          value: name,
                          child: Text(name),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _filterMedName = val),
                  ),
                ),
                const SizedBox(width: 12),
                // Filtro por fecha (día)
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _filterDate ?? now,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setState(() => _filterDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _filterDate == null
                                ? 'Todas'
                                : '${_two(_filterDate!.day)}/${_two(_filterDate!.month)}/${_filterDate!.year}',
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_filterDate != null)
                                IconButton(
                                  tooltip: 'Quitar fecha',
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(() => _filterDate = null),
                                ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = filtered[i];
                // Respaldo como objeto nuevo para deshacer de forma segura
                final backup = HistoryEntry(
                  dateTime: e.dateTime,
                  medName: e.medName,
                  taken: e.taken,
                );
                return Dismissible(
                  key: ValueKey(
                    'hist_${e.key}_${e.dateTime.millisecondsSinceEpoch}',
                  ),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) async {
                    await widget.repo.deleteHistory(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Entrada eliminada'),
                        action: SnackBarAction(
                          label: 'Deshacer',
                          onPressed: () async {
                            await widget.repo.addHistory(backup);
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      leading: Icon(
                        e.taken ? Icons.check_circle : Icons.cancel,
                        color: e.taken ? Colors.green : Colors.red,
                      ),
                      title: Text('${_fmt(e.dateTime)}  •  ${e.medName}'),
                      subtitle: Text(e.taken ? 'Tomado' : 'Omitido'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => widget.repo.markHistory(e, true),
                            child: const Text('Tomado'),
                          ),
                          TextButton(
                            onPressed: () => widget.repo.markHistory(e, false),
                            child: const Text('Omitido'),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar entrada'),
                                  content: const Text(
                                    '¿Deseas eliminar esta entrada del historial?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await widget.repo.deleteHistory(e);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Entrada eliminada'),
                                    action: SnackBarAction(
                                      label: 'Deshacer',
                                      onPressed: () async {
                                        await widget.repo.addHistory(backup);
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = (dt.hour % 12 == 0) ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '${_two(dt.day)}/${_two(dt.month)}/${dt.year} $h:$m $suffix';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
