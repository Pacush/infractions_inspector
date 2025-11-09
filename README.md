# Infractions Inspector

## Instrucciones de Build y Run

Sigue estos pasos para configurar y ejecutar el proyecto en tu máquina local.

### 1. Prerrequisitos

Asegurarse de tener el [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado y configurado en el sistema.

### 2. Configuración del `pubspec.yaml`

Para que el proyecto funcione, el archivo `pubspec.yaml` debe incluir las dependencias que se importan en el código y registrar los archivos de `assets`.

#### A. Dependencias

Asegurarse de que `dependencies` contenga todos los paquetes utilizados:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.5.3
  path_provider: ^2.1.5
  intl: ^0.20.2
  flutter_form_builder: ^10.0.1
  dropdown_search: ^6.0.2
  pdf: ^3.11.3
  printing: ^5.14.2
  sqflite: ^2.4.2
  path: ^1.9.1
  sqflite_common_ffi: ^2.3.6
```

#### B. Assets

La aplicación carga varios archivos JSON y un logo. El pubspec.yaml debe incluirlos para que la app no falle al iniciar o al crear la base de datos.

Asegúrate de que la sección flutter de tu pubspec.yaml se vea así:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/logo.png
    - assets/agentes.json
    - assets/conceptos.json
    - assets/jefaturas.json
    - assets/reglamento.txt
```

### 4. Instalar y Ejecutar

Una vez completados los pasos anteriores, ya puedes ejecutar la aplicación:

1.  **Instala las dependencias** (después de guardar los cambios en `pubspec.yaml`):

```bash
    flutter pub get
```

2.  **Ejecuta la aplicación**:
```bash
    flutter run
```

La aplicación debería iniciarse, crear la base de datos `infractions_inspector.db`, poblarla con los datos de los archivos JSON y mostrar la pantalla de login.

