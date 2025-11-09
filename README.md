# Infractions Inspector

## Instrucciones de Build y Run

Sigue estos pasos para configurar y ejecutar el proyecto en tu máquina local.

### 1. Prerrequisitos

Asegúrate de tener el [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado y configurado en tu sistema.

### 2. Configuración del `pubspec.yaml`

Para que el proyecto funcione, tu archivo `pubspec.yaml` debe incluir las dependencias que se importan en el código y, muy importante, debe registrar los archivos de `assets`.

#### A. Dependencias

Asegúrate de que tu sección `dependencies` contenga todos los paquetes utilizados:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Para la base de datos
  sqflite_common_ffi: ^[VERSIÓN] 
  path_provider: ^[VERSIÓN]
  path: ^[VERSIÓN]

  # Para la sesión de usuario
  shared_preferences: ^[VERSIÓN]

  # Para la generación de PDF
  pdf: ^[VERSIÓN]
  printing: ^[VERSIÓN]

  # Iconos (si los usas, ej. cupertino_icons)
  cupertino_icons: ^1.0.2