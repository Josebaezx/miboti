import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:mi_boti/models/med_model.dart';
import 'package:mi_boti/repository/med_repository.dart';

class AddMedPage extends StatefulWidget {
  const AddMedPage({super.key, required this.repo, this.existing, this.medKey});

  final MedRepository repo;
  final Medication? existing;
  final int? medKey; // Hive key cuando se edita

  static const route = '/add';

  @override
  State<AddMedPage> createState() => _AddMedPageState();
}

class _AddMedPageState extends State<AddMedPage> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  Color _color = const Color(0xFF2563EB);
  int _frequencyHours = 8; // 2,4,6,8

  bool get _isEditing => widget.existing != null && widget.medKey != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _doseCtrl.text = existing.dose;
      _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
      _color = Color(existing.colorValue);
      _frequencyHours = existing.frequencyHours;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  Future<void> _openColorPicker() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar color'),
        content: BlockPicker(
          pickerColor: _color,
          onColorChanged: (c) {
            setState(() => _color = c);
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() async {
    if (_form.currentState?.validate() != true) return;

    final med = Medication(
      name: _nameCtrl.text.trim(),
      dose: _doseCtrl.text.trim(),
      strength: '',
      hour: _time.hour,
      minute: _time.minute,
      colorValue: _color.toARGB32(),
      frequencyHours: _frequencyHours,
    );
    print(
      '[AddMedPage] ${_isEditing ? 'Actualizando' : 'Guardando'} medicamento: ${med.name} a las ${_time.format(context)}',
    );
    if (_isEditing) {
      await widget.repo.updateMedication(widget.medKey!, med);
    } else {
      await widget.repo.addMedication(med);
    }

    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    final horaFormateada = DateFormat('HH:mm').format(dateTime);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarma programada para las $horaFormateada'),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar medicamento' : 'Agregar medicamento'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 900
                ? 48.0
                : width >= 600
                ? 32.0
                : 16.0;
            final maxContentWidth = width >= 600 ? 520.0 : double.infinity;

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
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del medicamento',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _doseCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dosis (ej: 400 mg)',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  isEmpty: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Hora de inicio',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(_time.format(context)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time),
                              tooltip: 'Seleccionar hora',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _frequencyHours,
                          decoration: const InputDecoration(
                            labelText: 'Frecuencia (cada cuantas horas)',
                          ),
                          items: const [2, 4, 6, 8]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('Cada $v horas'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _frequencyHours = v ?? 8),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Color:'),
                            InkWell(
                              onTap: _openColorPicker,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black26),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _save,
                            child: Text(
                              _isEditing ? 'Guardar cambios' : 'Guardar',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
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
