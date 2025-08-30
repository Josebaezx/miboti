import 'package:flutter/material.dart';
import 'package:mi_boti/models/med_model.dart';

class AddMedPage extends StatefulWidget {
  static const route = '/add';
  const AddMedPage({super.key, required this.repo});
  final MedRepository repo;

  @override
  State<AddMedPage> createState() => _AddMedPageState();
}

class _AddMedPageState extends State<AddMedPage> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '10');
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _everyHours = 8;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  void _save() {
    if (_form.currentState?.validate() != true) return;
    widget.repo.addMedication(Medication(
      name: _nameCtrl.text.trim(),
      dose: '${_doseCtrl.text.trim()}',
      strength: 'Cada $_everyHours horas',
      timeOfDay: _time,
    ), days: int.tryParse(_durationCtrl.text) ?? 10);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar medicamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del medicamento'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _doseCtrl,
                decoration: const InputDecoration(labelText: 'Dosis (ej: 400 mg)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _everyHours,
                decoration: const InputDecoration(labelText: 'Frecuencia (cada N horas)'),
                items: const [4, 6, 8, 12].map((n) => DropdownMenuItem(value: n, child: Text('Cada $n horas'))).toList(),
                onChanged: (v) => setState(() => _everyHours = v ?? 8),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: TextEditingController(text: _formatTime(_time)),
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Hora de inicio'),
                      onTap: _pickTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(onPressed: _pickTime, icon: const Icon(Icons.access_time)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duración del tratamiento (días)'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ],
          ),
        ),
      ),
    );
  }
}
