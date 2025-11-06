import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBController {
  static const databaseName = "infractions_inspector.db";
  static const databaseVersion = 1;

  DBController._privateConstructor();
  static final DBController instance = DBController._privateConstructor();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // --- Inicialización de la BD ---
  initDatabase() async {
    // Obtiene la ruta de almacenamiento de documentos específica de la app
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    // Creacion de tablas

    await db.execute('''
      CREATE TABLE Departments (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Agents (
        id INTEGER PRIMARY KEY,
        clave INTEGER NOT NULL,
        name TEXT NOT NULL,
        jefatura_id INTEGER,
        password TEXT NOT NULL,
        FOREIGN KEY (jefatura_id) REFERENCES Departments(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Concepts (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        legal_basis TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Infractions (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        identification TEXT NOT NULL,
        establishment_name TEXT NOT NULL,
        establishment_business TEXT NOT NULL,
        establishment_address TEXT NOT NULL,
        reglamento TEXT NOT NULL,
        concept_id INTEGER NOT NULL,
        testigo1 TEXT NOT NULL,
        testigo2 TEXT NOT NULL,
        FOREIGN KEY (concept_id) REFERENCES Concepts(id) ON DELETE CASCADE
      )
    ''');

    //establishment_address: {calle: a, ext_num: a, interior_num: a, colonia: a, entrecalle1: a, entrecalle2: a}

    // Relleno de datos

    String jsonString = await rootBundle.loadString('assets/jefaturas.json');
    List<dynamic> jefaturas = json.decode(jsonString);
    for (var jefatura in jefaturas) {
      await db.insert('Departments', jefatura);
    }

    jsonString = await rootBundle.loadString('assets/agentes.json');
    List<dynamic> agentes = json.decode(jsonString);
    for (var agente in agentes) {
      await db.insert('Agents', agente);
    }

    jsonString = await rootBundle.loadString('assets/conceptos.json');
    List<dynamic> conceptos = json.decode(jsonString);
    for (var concepto in conceptos) {
      await db.insert('Concepts', concepto);
    }

    // Insert a sample Infraction using parameterized insert and valid JSON for the address
    final sampleAddress = {
      'calle': 'Paraiso',
      'ext_num': 95,
      'interior_num': 5,
      'colonia': 'Santa Cruz',
      'entrecalle1': 'Napoles',
      'entrecalle2': 'Bucalemu',
    };

    await db.insert('Infractions', {
      'name': 'José Sánchez',
      'identification': '12345678A',
      'establishment_name': 'SuSuper',
      'establishment_business': 'Venta de Abarrotes',
      'establishment_address': jsonEncode(sampleAddress),
      'reglamento': jsonEncode(["12", "15"]),
      'concept_id': 1,
      'testigo1': 'Juan Pérez',
      'testigo2': 'María García',
    });
  }

  /// Verifica si una jefatura existe con ese id.
  /// Retorna un Map de la jefatura si lo encuentra, o null si falla.
  Future<Map<String, dynamic>?> getJefatura(int id) async {
    final db = await instance.database;
    final res = await db.query('Departments', where: 'id = ?', whereArgs: [id]);

    if (res.isNotEmpty) {
      // Si hay resultado, retorna el primer usuario (debería ser único)
      return res.first;
    } else {
      // Si no hay resultado, retorna null
      return null;
    }
  }

  /// Verifica si un usuario existe con esa clave.
  /// Retorna un Map de la clave si lo encuentra, o null si falla.
  Future<Map<String, dynamic>?> getAgentByClave(String clave) async {
    final db = await instance.database;
    final res = await db.query(
      "Agents",
      where: 'clave = ?',
      whereArgs: [clave],
    );

    //final res = await db.rawQuery("SELECT * FROM Agents WHERE clave = $clave");

    if (res.isNotEmpty) {
      // Si hay resultado, retorna el primer usuario (debería ser único)
      return res.first;
    } else {
      // Si no hay resultado, retorna null
      return null;
    }
  }

  Future<List<String>> listTables() async {
    final db = await instance.database;
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    return res.map((r) => r.values.first.toString()).toList();
  }

  Future<Map<String, dynamic>?> testJson() async {
    try {
      final db = await instance.database;
      final res = await db.query('Infractions');
      return (res.first);
    } catch (e) {
      print('JSON1 not available: $e');
      return null;
    }
  }

}
