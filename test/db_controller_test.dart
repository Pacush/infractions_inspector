import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infractions_inspector/components/db_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize bindings for platform channels and asset loading in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Use the ffi implementation so sqflite works on the Dart VM during tests.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    // Mock path_provider to return a temporary directory path.
    pathProviderChannel.setMockMethodCallHandler((call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        final dir = Directory.systemTemp.createTempSync('infractions_test_');
        return dir.path;
      }
      return null;
    });
  });

  tearDown(() {
    // Clear mock handlers to avoid cross-test interference.
    pathProviderChannel.setMockMethodCallHandler(null);
  });

  test('hola', () async {
    final dbcontroller = DBController.instance;
    final res = await dbcontroller.listTables();
    print(res);
  });
}
