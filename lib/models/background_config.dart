import 'package:flutter/material.dart';

enum BackgroundType { solid, gradient, image }

class BackgroundConfig {
  const BackgroundConfig({
    required this.type,
    this.primaryColor = _defaultPrimary,
    this.secondaryColor = _defaultSecondary,
    this.imagePath,
  });

  final BackgroundType type;
  final int primaryColor;
  final int? secondaryColor;
  final String? imagePath;

  static const int _defaultPrimary = 0xFFEEF2FF;
  static const int _defaultSecondary = 0xFFDDE7FF;
  static const String _defaultImage = 'assets/images/fondo_splash_nuevo.jpg';

  static const BackgroundConfig defaults = BackgroundConfig(
    type: BackgroundType.gradient,
  );

  BackgroundConfig copyWith({
    BackgroundType? type,
    int? primaryColor,
    int? secondaryColor,
    String? imagePath,
  }) {
    return BackgroundConfig(
      type: type ?? this.type,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  BoxDecoration toDecoration() {
    switch (type) {
      case BackgroundType.solid:
        return BoxDecoration(color: Color(primaryColor));
      case BackgroundType.gradient:
        final secondary = secondaryColor ?? _defaultSecondary;
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(primaryColor), Color(secondary)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case BackgroundType.image:
        final path = imagePath ?? _defaultImage;
        return BoxDecoration(
          color: Color(primaryColor),
          image: DecorationImage(
            image: AssetImage(path),
            fit: BoxFit.cover,
            colorFilter: secondaryColor != null
                ? ColorFilter.mode(
                    Color(secondaryColor!).withOpacity(0.35),
                    BlendMode.srcATop,
                  )
                : null,
          ),
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'imagePath': imagePath,
    };
  }

  factory BackgroundConfig.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return defaults;
    final typeName = map['type'] as String?;
    final resolvedType = BackgroundType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => BackgroundType.gradient,
    );
    return BackgroundConfig(
      type: resolvedType,
      primaryColor: (map['primaryColor'] as int?) ?? _defaultPrimary,
      secondaryColor: map['secondaryColor'] as int?,
      imagePath: map['imagePath'] as String?,
    );
  }
}
