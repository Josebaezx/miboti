import 'package:flutter/material.dart';
import 'package:mi_boti/models/med_model.dart';
import 'package:mi_boti/pages/add_med_page.dart';
import 'package:mi_boti/pages/history_page.dart';
import 'package:mi_boti/pages/home_page.dart';
import 'package:mi_boti/pages/settings_page.dart';

void main() {
  runApp(const MiBotiquinApp());
}

class MiBotiquinApp extends StatefulWidget {
  const MiBotiquinApp({super.key});

  @override
  State<MiBotiquinApp> createState() => _MiBotiquinAppState();
}

class _MiBotiquinAppState extends State<MiBotiquinApp> {
  final MedRepository repo = MedRepository(seed: true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiBotiquín',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routes: {
        '/': (_) => HomePage(repo: repo),
        AddMedPage.route: (_) => AddMedPage(repo: repo),
        HistoryPage.route: (_) => HistoryPage(repo: repo),
        SettingsPage.route: (_) => SettingsPage(repo: repo),
      },
    );
  }
}
