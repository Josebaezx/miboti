import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mi_boti/models/med_model.dart';
import 'package:mi_boti/repository/med_repository.dart';
import 'package:mi_boti/services/notification_service.dart';
import 'package:mi_boti/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive
  await Hive.initFlutter();
  Hive.registerAdapter(MedicationAdapter());
  Hive.registerAdapter(HistoryEntryAdapter());

  // Inicializa repositorio
  final repo = MedRepository();
  await repo.init();

  // ✅ Inicializa servicio de notificaciones
  await NotificationService.init();

  // ✅ Solicita permisos en tiempo de ejecución (Android 13+)
  await NotificationService.ensureNotificationPermissions();

  runApp(MiBotiquinApp(repo: repo));
}


class MiBotiquinApp extends StatelessWidget {
  final MedRepository repo;
  const MiBotiquinApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiBotiquín',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: HomePage(repo: repo),
    );
  }
}
