# Gestor de tareas con SQLite

Práctica de Programación de Dispositivos Móviles, UAA. Una misma aplicación Flutter permite agregar, consultar, renombrar, marcar y eliminar tareas en web, móvil y escritorio. La interfaz inicial y el modelo provienen del [material de la práctica](https://github.com/Irving2355/Dispositivos-Moviles-2026/tree/main/tareas/Practica_SQLite).

## Ejecutar

Se utilizó Flutter estable 3.47.2. Instala las herramientas de la plataforma que vayas a usar. Desde una terminal:

```sh
git clone https://github.com/RaulRomoLamas/gestor-tareas-sqlite-flutter.git
cd gestor-tareas-sqlite-flutter
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter devices
```

- **Web**. Ejecuta `flutter run -d web-server --web-port 8080` y abre http://localhost:8080 en Chrome. Mantén el mismo puerto y perfil al repetir las pruebas. Para generar el sitio con el motor gráfico incluido usa `flutter build web --no-web-resources-cdn`.
- **Windows**. Ejecuta `flutter run -d windows`. Para abrir de nuevo el mismo ejecutable puedes usar `flutter build windows` y abrir `build/windows/x64/runner/Release/gestor_tareas_local.exe`.
- **Android**. Conecta un teléfono con depuración USB o inicia un emulador. Usa `flutter run -d ID` con el identificador mostrado por `flutter devices`. Para generar el instalador ejecuta `flutter build apk --debug`.

## Almacenamiento

`lib/data/base_tareas.dart` centraliza la conexión, la migración inicial y el SQL parametrizado. La tabla `tareas` contiene `id INTEGER PRIMARY KEY AUTOINCREMENT`, `titulo TEXT NOT NULL` y `completada INTEGER NOT NULL DEFAULT 0` con valores permitidos 0 y 1. Se recortan los espacios antes de guardar. Dos filas pueden compartir título y se modifican por ID.

Drift ejecuta las consultas asíncronas y drift_flutter selecciona el almacenamiento. Se usa SQL explícito, por lo que el proyecto no requiere build_runner. La pantalla carga la lista al iniciar y vuelve a consultarla tras cada escritura. Esta estrategia permite recuperar el orden y los valores guardados con una única lectura de una tabla pequeña. La interfaz muestra problemas de lectura o escritura y libera la conexión al desmontarse.

En móvil y escritorio se crea `gestor_tareas_local.sqlite` en el directorio de documentos que el sistema asigna a la aplicación. En web, el módulo WebAssembly ejecuta SQLite y el worker gestiona el acceso al almacenamiento del origen (OPFS o IndexedDB según el navegador). Ambos archivos en `web/` proceden de la [versión 2.35.4 de Drift](https://github.com/simolus3/drift/releases/tag/drift-2.35.4). El CRUD se ejecuta localmente. Borrar los datos del sitio o usar navegación privada puede impedir que se conserven entre sesiones.

## Repetir la comprobación

Usa una instalación o perfil de prueba. En Windows, «reabrir» significa cerrar la ventana y lanzar el mismo ejecutable. En Chrome, cierra la pestaña y abre de nuevo la misma URL en el mismo perfil.

| Caso | Acción | Resultado observado |
|---|---|---|
| P1 | Agregar Leer consigna, Probar SQLite y Entregar reporte. Reabrir. | Aparecen las tres en orden de alta. |
| P2 | Marcar Leer consigna y reabrir. | Conserva la casilla marcada y el estado Completada. |
| P3 | Renombrar Probar SQLite como Revisar SQLite y reabrir. | Permanece el nuevo título. |
| P4 | Eliminar Entregar reporte y reabrir. | Quedan únicamente las otras dos. |
| P5 | Intentar agregar tres espacios. | Aparece «Escribe un título.» y siguen las dos filas. |
| P6 | En Chrome, recargar y después cerrar y reabrir la pestaña. | Se mantienen las tareas, el título editado y el estado. |

P1–P5 se probaron sobre la interfaz en Windows y Chrome. P6 se probó en Chrome. Android compiló un APK de depuración. La ejecución en un teléfono o emulador queda pendiente. iOS, Linux y macOS tienen carpetas de plataforma generadas y comparten la capa de datos, sin pruebas de ejecución en este equipo.

`flutter test` comprueba el arranque de la pantalla, el rechazo de altas y ediciones vacías y el CRUD sobre un archivo SQLite temporal que se cierra y vuelve a abrir tras los cambios. La última prueba usa títulos duplicados para comprobar que la eliminación afecta al ID elegido.

## Fuentes

- [Drift en web](https://drift.simonbinder.eu/platforms/web/). Configuración de WebAssembly, worker y almacenamiento del navegador.
- [drift_flutter](https://pub.dev/packages/drift_flutter). Apertura de una conexión adecuada al dispositivo y ubicación del archivo nativo.

Codex participó en la implementación, la ejecución de pruebas y la documentación.
