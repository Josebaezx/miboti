import 'package:flutter_test/flutter_test.dart';
import 'package:mi_boti/main.dart';
import 'package:mi_boti/repository/med_repository.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Crear un repo falso o inicializado para pruebas
    final repo = MedRepository();
    await repo.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MiBotiquinApp(repo: repo));

    // Verificar que se carga algo básico de la app
    expect(find.byType(MiBotiquinApp), findsOneWidget);
  });
}
