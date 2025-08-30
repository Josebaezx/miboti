import 'package:flutter/material.dart';
import 'package:mi_boti/models/med_model.dart';

class HistoryPage extends StatefulWidget {
  static const route = '/history';
  const HistoryPage({super.key, required this.repo});
  final MedRepository repo;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
    // 🔹 Hacemos una copia mutable para poder ordenar
    final entries = List.of(widget.repo.history)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final e = entries[i];
          return Container(
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
                ],
              ),
            ),
          );
        },
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
