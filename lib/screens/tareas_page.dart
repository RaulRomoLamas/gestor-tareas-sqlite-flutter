import 'package:flutter/material.dart';

import '../models/tarea.dart';

import '../data/base_tareas.dart';

class TareasPage extends StatefulWidget {
  final BaseTareas? base;
  const TareasPage({super.key, this.base});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  List<Tarea> _tareas = [];

  late final BaseTareas _base;
  bool _ocupada = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _base = widget.base ?? BaseTareas.local();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final tareas = await _base.listar();
      if (mounted)
        setState(() {
          _tareas = tareas;
          _error = null;
        });
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'No se pudieron cargar las tareas. Revisa el almacenamiento local.',
        );
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  Future<void> _guardar(
    Future<int> Function() operacion, {
    bool limpiar = false,
  }) async {
    if (_ocupada) return;
    setState(() => _ocupada = true);
    try {
      await operacion();
      if (!mounted) return;
      if (limpiar) _tituloController.clear();
      await _cargar();
    } on FormatException catch (e) {
      _avisar(e.message);
    } catch (_) {
      _avisar(
        'No se guardó el cambio. Revisa el almacenamiento e intenta otra vez.',
      );
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  void _avisar(String texto) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _editarTarea(Tarea tarea) async {
    var texto = tarea.titulo;
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) => AlertDialog(
          title: const Text('Editar tarea'),
          content: TextFormField(
            initialValue: texto,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Título'),
            onChanged: (valor) => actualizar(() => texto = valor),
            onFieldSubmitted: (valor) {
              if (valor.trim().isNotEmpty) Navigator.pop(context, valor);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: texto.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, texto),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (nuevo != null && mounted)
      await _guardar(() => _base.renombrar(tarea.id, nuevo));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    if (widget.base == null) _base.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              readOnly: _ocupada,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _ocupada || _error != null
                  ? null
                  : () => _guardar(
                      () => _base.agregar(_tituloController.text),
                      limpiar: true,
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          TextButton(
                            onPressed: _ocupada
                                ? null
                                : () {
                                    setState(() => _ocupada = true);
                                    _cargar();
                                  },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _ocupada && _tareas.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _tareas.isEmpty
                  ? const Center(child: Text('Todavía no hay tareas guardadas'))
                  : ListView.builder(
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: tarea.completada,
                              onChanged: _ocupada
                                  ? null
                                  : (valor) {
                                      if (valor != null) {
                                        _guardar(
                                          () => _base.marcar(tarea.id, valor),
                                        );
                                      }
                                    },
                            ),
                            title: Text(tarea.titulo),
                            subtitle: Text(
                              tarea.completada ? 'Completada' : 'Pendiente',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: _ocupada
                                      ? null
                                      : () => _editarTarea(tarea),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _ocupada
                                      ? null
                                      : () => _guardar(
                                          () => _base.eliminar(tarea.id),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
