import 'dart:convert';

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

  // --- DB initalization ---
  initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Creation of DB tables (Departments, Agents, Concepts, Infractions)
  Future _onCreate(Database db, int version) async {
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
        visitado_name TEXT NOT NULL,
        visitado_identification TEXT NOT NULL,
        num_identificacion TEXT NOT NULL,
        establishment_name TEXT NOT NULL,
        establishment_business TEXT NOT NULL,
        establishment_address TEXT NOT NULL,
        reglamento TEXT NOT NULL,
        concept_ids TEXT NOT NULL,
        testigo1 TEXT NOT NULL,
        testigo2 TEXT NOT NULL,
        agent_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        folio INT NOT NULL,

        FOREIGN KEY (agent_id) REFERENCES Agents(id) ON DELETE CASCADE
      )
    ''');
    // establishment_address format used along the project:
    //{calle: a, ext_num: a, interior_num: a, colonia: a, entrecalle1: a, entrecalle2: a}

    // Data filling
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
  }

  /// Looks up for a Jefatura based on ID
  Future<Map<String, dynamic>?> getJefatura(int id) async {
    final db = await instance.database;
    final res = await db.query('Departments', where: 'id = ?', whereArgs: [id]);

    if (res.isNotEmpty) {
      return res.first;
    } else {
      return null;
    }
  }

  /// Looks up for an Agente based on ID
  Future<Map<String, dynamic>?> getAgentByClave(String clave) async {
    final db = await instance.database;
    final res = await db.query(
      "Agents",
      where: 'clave = ?',
      whereArgs: [clave],
    );
    if (res.isNotEmpty) {
      return res.first;
    } else {
      return null;
    }
  }

  /// Looks up for the highest folio created by the agent ([agentId]) and returns it increased by +1
  static Future<dynamic> nextFolioForAgent(int agentId) async {
    final db = await DBController.instance.database;
    final exiting2 = await db.rawQuery(
      "SELECT MAX(folio) FROM Infractions WHERE agent_id = $agentId",
    );
    dynamic c = exiting2[0]['MAX(folio)'];
    if (c == null) {
      return 1;
    } else {
      return c + 1;
    }
  }
}
