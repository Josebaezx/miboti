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
  DateTime? _filterDate;

  bool get _hasFilters => _filterMedName != null || _filterDate != null;

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
    final medNames = <String>{for (final h in widget.repo.history) h.medName}
      ..removeWhere((e) => e.trim().isEmpty);

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
          if (_hasFilters)
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
                      'Esta accion eliminara todas las entradas del historial. Deseas continuar?',
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
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Historial eliminado'),
                      action: SnackBarAction(
                        label: 'Deshacer',
                        onPressed: () async {
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 1100
                ? 48.0
                : width >= 720
                ? 32.0
                : 16.0;
            final maxContentWidth = width >= 1000
                ? 840.0
                : width >= 720
                ? 640.0
                : double.infinity;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                16,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: _buildFilters(context, maxContentWidth, medNames),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 0),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: filtered.isEmpty
                            ? _EmptyHistoryState(hasFilters: _hasFilters)
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) {
                                  final entry = filtered[i];
                                  final backup = HistoryEntry(
                                    dateTime: entry.dateTime,
                                    medName: entry.medName,
                                    taken: entry.taken,
                                  );
                                  return Dismissible(
                                    key: ValueKey(
                                      'hist_${entry.key}_${entry.dateTime.millisecondsSinceEpoch}',
                                    ),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                    ),
                                    onDismissed: (_) async {
                                      await widget.repo.deleteHistory(entry);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Entrada eliminada',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Deshacer',
                                            onPressed: () async {
                                              await widget.repo.addHistory(
                                                backup,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: _HistoryEntryCard(
                                        entry: entry,
                                        formattedDate: _fmt(entry.dateTime),
                                        onMarkTaken: () => widget.repo
                                            .markHistory(entry, true),
                                        onMarkSkipped: () => widget.repo
                                            .markHistory(entry, false),
                                        onDelete: () =>
                                            _confirmDeleteEntry(entry, backup),
                                      ),
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
    );
  }

  Widget _buildFilters(
    BuildContext context,
    double maxWidth,
    Set<String> medNames,
  ) {
    final isStacked = maxWidth < 520;
    final double fieldWidth = isStacked ? maxWidth : (maxWidth - 12) / 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<String?>(
            value: _filterMedName,
            isExpanded: true,
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
                (name) =>
                    DropdownMenuItem<String?>(value: name, child: Text(name)),
              ),
            ],
            onChanged: (val) => setState(() => _filterMedName = val),
          ),
        ),
        SizedBox(
          width: fieldWidth,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
                          onPressed: () => setState(() => _filterDate = null),
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
    );
  }

  Future<void> _confirmDeleteEntry(
    HistoryEntry entry,
    HistoryEntry backup,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('Deseas eliminar esta entrada del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.repo.deleteHistory(entry);
      if (!mounted) return;
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
  }

  String _fmt(DateTime dt) {
    final h = (dt.hour % 12 == 0) ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '${_two(dt.day)}/${_two(dt.month)}/${dt.year} $h:$m $suffix';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.formattedDate,
    required this.onMarkTaken,
    required this.onMarkSkipped,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final String formattedDate;
  final VoidCallback onMarkTaken;
  final VoidCallback onMarkSkipped;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusText = entry.taken ? 'Tomado' : 'Omitido';
    final statusColor = entry.taken ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              entry.taken ? Icons.check_circle : Icons.cancel,
              color: statusColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$formattedDate  �?�  ${entry.medName}'),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: [
            TextButton(onPressed: onMarkTaken, child: const Text('Tomado')),
            TextButton(onPressed: onMarkSkipped, child: const Text('Omitido')),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final message = hasFilters
        ? 'No hay registros que coincidan con los filtros seleccionados.'
        : 'Cuando registres tus tomas apareceran aqui.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 12),
              Text(
                'Prueba limpiar los filtros para ver todo el historial.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
