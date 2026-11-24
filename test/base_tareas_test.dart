import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/base_tareas.dart';

void main() {
  test(
    'Alta y edición rechazan títulos en blanco sin cambiar los datos',
    () async {
      final db = BaseTareas(NativeDatabase.memory());
      addTearDown(db.close);
      for (final texto in ['', '   ', '\t\n']) {
        await expectLater(db.agregar(texto), throwsFormatException);
      }
      final id = await db.agregar("  Leer 'SQLite'  ");
      await expectLater(db.renombrar(id, '   '), throwsFormatException);
      expect((await db.listar()).single.titulo, "Leer 'SQLite'");
    },
  );

  test(
    'El archivo conserva altas, estado, edición y baja por ID al reabrirse',
    () async {
      final carpeta = await Directory.systemTemp.createTemp('prueba_tareas');
      final archivo = File('${carpeta.path}/tareas.sqlite');
      BaseTareas abrir() => BaseTareas(NativeDatabase(archivo));
      var db = abrir();
      addTearDown(() async {
        await db.close();
        await carpeta.delete(recursive: true);
      });
      Future<void> reabrir() async {
        await db.close();
        db = abrir();
      }

      final a = await db.agregar('Leer');
      final b = await db.agregar('Leer');
      final c = await db.agregar('Entregar');
      await reabrir();
      expect((await db.listar()).map((t) => t.id), [a, b, c]);
      await db.marcar(a, true);
      await reabrir();
      expect((await db.listar()).map((t) => t.completada), [
        true,
        false,
        false,
      ]);
      await db.renombrar(b, 'Revisar');
      await reabrir();
      expect((await db.listar())[1].titulo, 'Revisar');
      await db.eliminar(a);
      await reabrir();
      expect((await db.listar()).map((t) => t.id), [b, c]);
      await db.marcar(b, true);
      await db.marcar(b, false);
      await reabrir();
      expect((await db.listar()).first.completada, false);
    },
  );
}
