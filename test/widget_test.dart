import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gestor_tareas_local/data/base_tareas.dart';
import 'package:gestor_tareas_local/screens/tareas_page.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    final base = BaseTareas(NativeDatabase.memory());
    addTearDown(base.close);
    await tester.pumpWidget(MaterialApp(home: TareasPage(base: base)));
    await tester.pumpAndSettle();
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
