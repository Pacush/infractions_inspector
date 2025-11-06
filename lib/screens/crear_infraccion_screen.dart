import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infractions_inspector/components/db_controller.dart';

class CrearInfraccionScreen extends StatefulWidget {
  const CrearInfraccionScreen({super.key});

  @override
  State<CrearInfraccionScreen> createState() => _CrearInfraccionScreenState();
}

class _CrearInfraccionScreenState extends State<CrearInfraccionScreen> {
  final formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();
  bool isSaving = false;

  // Form controllers
  final nombreVisitadoController = TextEditingController();
  final numIdentificacionController = TextEditingController();
  final nombreEstablecimientoController = TextEditingController();
  final calleController = TextEditingController();
  final numExtController = TextEditingController();
  final numIntController = TextEditingController();
  final coloniaController = TextEditingController();
  final entrecalle1Controller = TextEditingController();
  final entrecalle2Controller = TextEditingController();
  final testigo1Controller = TextEditingController();
  final testigo2Controller = TextEditingController();

  // Form values
  String tipoIdentificacion = 'INE';
  String giroSeleccionado = '';
  List<String> reglamentosSeleccionados = [];
  List<int> conceptosSeleccionados = [];

  // Data lists
  final List<String> tiposIdentificacion = ['INE', 'Pasaporte'];
  final List<String> giros = [
    'Tienda',
    'Restaurante',
    'Cafetería',
    'Otro',
  ]; //TODO: Make
  List<String> reglamentos = [];
  List<Map<String, dynamic>> conceptos = [];
  List<Map<String, dynamic>> agentes = [];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      // Load reglamentos from text file
      final String reglamentosContent = await rootBundle.loadString(
        'assets/reglamento.txt',
      );
      final List<String> loadedReglamentos = List<String>.from(
        json.decode(reglamentosContent.replaceAll("'", '"')),
      );

      // Load conceptos and agentes from DB
      final db = await DBController.instance.database;
      final List<Map<String, dynamic>> loadedConceptos = await db.query(
        'Concepts',
      );
      final List<Map<String, dynamic>> loadedAgentes = await db.query('Agents');

      setState(() {
        reglamentos = loadedReglamentos;
        conceptos = loadedConceptos;
        agentes = loadedAgentes;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando datos: $e')));
    }
  }

  Future<void> guardarInfraccion() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final addressData = {
        'calle': calleController.text,
        'ext_num': numExtController.text,
        'interior_num': numIntController.text,
        'colonia': coloniaController.text,
        'entrecalle1': entrecalle1Controller.text,
        'entrecalle2': entrecalle2Controller.text,
      };

      // TODO: Get logged in agent ID
      final infraccionData = {
        'name': nombreVisitadoController.text,
        'identification_type': tipoIdentificacion,
        'identification': numIdentificacionController.text,
        'establishment_name': nombreEstablecimientoController.text,
        'establishment_business': giroSeleccionado,
        'establishment_address': jsonEncode(addressData),
        'reglamento': jsonEncode(reglamentosSeleccionados),
        'concept_id':
            conceptosSeleccionados.isNotEmpty
                ? conceptosSeleccionados[0]
                : null,
        'testigo1': testigo1Controller.text,
        'testigo2': testigo2Controller.text,
        'agent_id': 1, // TODO: Get from session
        'timestamp': DateTime.now().toIso8601String(),
      };

      final db = await DBController.instance.database;
      final id = await db.insert('Infractions', infraccionData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Infracción guardada con ID: $id')),
      );

      // TODO: Show generate PDF button
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> mostrarVistaPrevia() async {
    // TODO: Generate and show PDF preview
  }

  @override
  void dispose() {
    nombreVisitadoController.dispose();
    numIdentificacionController.dispose();
    nombreEstablecimientoController.dispose();
    calleController.dispose();
    numExtController.dispose();
    numIntController.dispose();
    coloniaController.dispose();
    entrecalle1Controller.dispose();
    entrecalle2Controller.dispose();
    testigo1Controller.dispose();
    testigo2Controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crear Infracción',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 87, 34),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Datos del visitado
              buildSectionTitle('Datos del visitado'),
              TextFormField(
                controller: nombreVisitadoController,
                decoration: InputDecoration(labelText: 'Nombre del visitado'),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tipoIdentificacion,
                decoration: InputDecoration(
                  labelText: 'Tipo de identificación',
                ),
                items:
                    tiposIdentificacion.map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    tipoIdentificacion = value!;
                  });
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: numIdentificacionController,
                decoration: InputDecoration(
                  labelText: 'Número de identificación',
                ),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),

              // 2. Datos del establecimiento
              SizedBox(height: 24),
              buildSectionTitle('Datos del establecimiento'),
              TextFormField(
                controller: nombreEstablecimientoController,
                decoration: InputDecoration(
                  labelText: 'Nombre del establecimiento',
                ),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: giroSeleccionado.isEmpty ? null : giroSeleccionado,
                decoration: InputDecoration(labelText: 'Giro'),
                items:
                    giros.map((giro) {
                      return DropdownMenuItem(value: giro, child: Text(giro));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    giroSeleccionado = value!;
                  });
                },
                validator:
                    (value) =>
                        value?.isEmpty == true ? 'Seleccione un giro' : null,
              ),

              // 3. Domicilio del establecimiento
              SizedBox(height: 24),
              buildSectionTitle('Domicilio del establecimiento'),
              TextFormField(
                controller: calleController,
                decoration: InputDecoration(labelText: 'Calle'),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: numExtController,
                      decoration: InputDecoration(labelText: 'Número exterior'),
                      validator:
                          (value) =>
                              value?.isEmpty == true ? 'Requerido' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: numIntController,
                      decoration: InputDecoration(labelText: 'Número interior'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: coloniaController,
                decoration: InputDecoration(labelText: 'Colonia'),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: entrecalle1Controller,
                decoration: InputDecoration(labelText: 'Entre calle 1'),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: entrecalle2Controller,
                decoration: InputDecoration(labelText: 'Entre calle 2'),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),

              // 4. Datos de la infracción
              SizedBox(height: 24),
              buildSectionTitle('Datos de la infracción'),
              // Reglamentos (Wrap with chips for multiple selection)
              Wrap(
                spacing: 8.0,
                children:
                    reglamentos.map((reglamento) {
                      final isSelected = reglamentosSeleccionados.contains(
                        reglamento,
                      );
                      return FilterChip(
                        label: Text(reglamento),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              reglamentosSeleccionados.add(reglamento);
                            } else {
                              reglamentosSeleccionados.remove(reglamento);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),
              // TODO: Add conceptos selection based on selected reglamentos

              // Testigos
              SizedBox(height: 16),
              TextFormField(
                controller: testigo1Controller,
                decoration: InputDecoration(
                  labelText: 'Testigo 1',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.person_search),
                    onPressed: () {
                      // TODO: Show agent selection dialog
                    },
                  ),
                ),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: testigo2Controller,
                decoration: InputDecoration(
                  labelText: 'Testigo 2',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.person_search),
                    onPressed: () {
                      // TODO: Show agent selection dialog
                    },
                  ),
                ),
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Este campo es requerido'
                            : null,
              ),

              // 5. Acciones
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.preview),
                      label: Text('Vista Previa'),
                      onPressed: isSaving ? null : mostrarVistaPrevia,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                      onPressed: isSaving ? null : guardarInfraccion,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 255, 87, 34),
        ),
      ),
    );
  }
}
