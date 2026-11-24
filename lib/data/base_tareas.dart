import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/tarea.dart';

class BaseTareas extends GeneratedDatabase {
  BaseTareas(QueryExecutor conexion) : super(conexion);

  factory BaseTareas.local() => BaseTareas(
    driftDatabase(
      name: 'gestor_tareas_local',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => customStatement('''CREATE TABLE tareas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL CHECK(length(trim(titulo)) > 0),
      completada INTEGER NOT NULL DEFAULT 0 CHECK(completada IN (0,1))
    )'''),
  );

  String validar(String texto) {
    final titulo = texto.trim();
    if (titulo.isEmpty) throw const FormatException('Escribe un título.');
    return titulo;
  }

  Future<int> agregar(String titulo) async => customInsert(
    'INSERT INTO tareas (titulo) VALUES (?)',
    variables: [Variable(validar(titulo))],
  );

  Future<List<Tarea>> listar() async {
    final filas = await customSelect(
      'SELECT id, titulo, completada FROM tareas ORDER BY id',
    ).get();
    return filas
        .map(
          (f) => Tarea(
            id: f.read<int>('id'),
            titulo: f.read<String>('titulo'),
            completada: f.read<int>('completada') == 1,
          ),
        )
        .toList();
  }

  Future<int> renombrar(int id, String titulo) async => customUpdate(
    'UPDATE tareas SET titulo = ? WHERE id = ?',
    variables: [Variable(validar(titulo)), Variable(id)],
  );

  Future<int> marcar(int id, bool completada) => customUpdate(
    'UPDATE tareas SET completada = ? WHERE id = ?',
    variables: [Variable(completada ? 1 : 0), Variable(id)],
  );

  Future<int> eliminar(int id) => customUpdate(
    'DELETE FROM tareas WHERE id = ?',
    variables: [Variable(id)],
  );
}
