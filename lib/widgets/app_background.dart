import 'package:flutter/material.dart';
import 'package:mi_boti/repository/med_repository.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.repo, required this.child});

  final MedRepository repo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final config = repo.backgroundConfig;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: config.toDecoration(),
      child: child,
    );
  }
}
