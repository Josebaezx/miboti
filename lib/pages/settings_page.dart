import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mi_boti/models/background_config.dart';
import 'package:mi_boti/repository/med_repository.dart';
import 'package:mi_boti/widgets/app_background.dart';

class SettingsPage extends StatefulWidget {
  static const route = '/settings';

  const SettingsPage({super.key, required this.repo});

  final MedRepository repo;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool sound = true;
  bool vibration = true;

  late BackgroundConfig _background;

  static const List<String> _availableImages = [
    'assets/images/fondo_splash_nuevo.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _background = widget.repo.backgroundConfig;
    widget.repo.addListener(_onRepo);
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    super.dispose();
  }

  void _onRepo() {
    setState(() => _background = widget.repo.backgroundConfig);
  }

  Future<void> _applyConfig(BackgroundConfig config) async {
    if (!mounted) return;
    setState(() => _background = config);
    await widget.repo.updateBackground(config);
  }

  Future<void> _pickColor({
    required bool isPrimary,
    required String title,
  }) async {
    final current = Color(
      isPrimary
          ? _background.primaryColor
          : (_background.secondaryColor ??
                BackgroundConfig.defaults.secondaryColor!),
    );
    final Color? picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: BlockPicker(
          pickerColor: current,
          onColorChanged: (color) => Navigator.of(ctx).pop(color),
        ),
      ),
    );
    if (picked == null) return;
    if (isPrimary) {
      await _applyConfig(_background.copyWith(primaryColor: picked.value));
    } else {
      await _applyConfig(_background.copyWith(secondaryColor: picked.value));
    }
  }

  void _updateType(BackgroundType type) {
    BackgroundConfig config = _background.copyWith(type: type);
    if (type == BackgroundType.gradient && config.secondaryColor == null) {
      config = config.copyWith(
        secondaryColor: BackgroundConfig.defaults.secondaryColor,
      );
    }
    if (type == BackgroundType.image && config.imagePath == null) {
      config = config.copyWith(
        imagePath: _availableImages.first,
        secondaryColor: config.secondaryColor ?? const Color(0x88000000).value,
      );
    }
    if (type == BackgroundType.solid) {
      config = config.copyWith(secondaryColor: null, imagePath: null);
    }
    _applyConfig(config);
  }

  Widget _buildColorSwatch({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaperControls() {
    final theme = Theme.of(context);
    switch (_background.type) {
      case BackgroundType.solid:
        return Row(
          children: [
            _buildColorSwatch(
              label: 'Color',
              color: Color(_background.primaryColor),
              onTap: () => _pickColor(
                isPrimary: true,
                title: 'Seleccionar color de fondo',
              ),
            ),
          ],
        );
      case BackgroundType.gradient:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildColorSwatch(
                  label: 'Inicio',
                  color: Color(_background.primaryColor),
                  onTap: () =>
                      _pickColor(isPrimary: true, title: 'Color inicial'),
                ),
                const SizedBox(width: 16),
                _buildColorSwatch(
                  label: 'Fin',
                  color: Color(
                    (_background.secondaryColor ??
                        BackgroundConfig.defaults.secondaryColor!),
                  ),
                  onTap: () =>
                      _pickColor(isPrimary: false, title: 'Color final'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 120,
                decoration: _background.toDecoration(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'El degradado se aplica a todas las pantallas.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      case BackgroundType.image:
        final selected = _background.imagePath ?? _availableImages.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(
                labelText: 'Imagen',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _availableImages
                  .map(
                    (path) => DropdownMenuItem(
                      value: path,
                      child: Text(path.split('/').last),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _applyConfig(_background.copyWith(imagePath: value));
                }
              },
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                decoration: _background.toDecoration(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildColorSwatch(
                  label: 'Filtro',
                  color: Color(
                    (_background.secondaryColor ??
                        const Color(0x55000000).value),
                  ),
                  onTap: () =>
                      _pickColor(isPrimary: false, title: 'Color del filtro'),
                ),
                TextButton(
                  onPressed: () =>
                      _applyConfig(_background.copyWith(secondaryColor: null)),
                  child: const Text('Quitar filtro'),
                ),
              ],
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBackground(
      repo: widget.repo,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Configuracion'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
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
              final maxContentWidth = width >= 720 ? 560.0 : double.infinity;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fondo de pantalla',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<BackgroundType>(
                                  value: _background.type,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de fondo',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: BackgroundType.values
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(switch (type) {
                                            BackgroundType.solid =>
                                              'Color solido',
                                            BackgroundType.gradient =>
                                              'Degradado',
                                            BackgroundType.image => 'Imagen',
                                          }),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (type) {
                                    if (type != null) _updateType(type);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildWallpaperControls(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Sonido'),
                                value: sound,
                                onChanged: (v) => setState(() => sound = v),
                              ),
                              SwitchListTile(
                                title: const Text('Vibracion'),
                                value: vibration,
                                onChanged: (v) => setState(() => vibration = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Nota: Esta app es una demo de UI, sin notificaciones reales.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
