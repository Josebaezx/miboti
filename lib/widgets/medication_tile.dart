
import 'package:flutter/material.dart';
import 'package:mi_boti/models/med_model.dart';

class MedicationTile extends StatelessWidget {
  const MedicationTile({super.key, required this.med});

  final Medication med;

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(med.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 8, backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (med.dose.isNotEmpty)
                  Text(med.dose, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ),
          Text(_formatTime(med.timeOfDay), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
