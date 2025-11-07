import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infractions_inspector/components/db_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  ]; //TODO: Make dynamic
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

  Future<void> updateAllowedReglamentos(List conceptos) async {
    reglamentos.clear();
    int i = conceptos.length;
    List<String> newReglamentos = [];
    while (i > 0) {
      String reglamento = conceptos[i]['legal_basis'].toString();
      List<String> parts = reglamento.split(RegExp(r'\s+'));
      String articulo = parts.take(2).join(' ');
      newReglamentos.add(articulo);
    }
    setState(() {
      reglamentos = newReglamentos;
    });
  }

  Future<void> _showReglamentosDialog() async {
    final List<String> tempSelected = List<String>.from(
      reglamentosSeleccionados,
    );

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar reglamentos'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: reglamentos.length,
                    itemBuilder: (context, index) {
                      final r = reglamentos[index];
                      final checked = tempSelected.contains(r);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(r),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? v) {
                          setState(() {
                            if (v == true) {
                              if (!tempSelected.contains(r)) {
                                tempSelected.add(r);
                              }
                            } else {
                              // allow unselecting
                              tempSelected.remove(r);
                            }
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempSelected),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        reglamentosSeleccionados = result;
      });
    }
  }

  Future<void> _showConceptosDialog() async {
    int? tempSelected =
        conceptosSeleccionados.isNotEmpty ? conceptosSeleccionados.first : null;

    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar concepto principal'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: conceptos.length,
                    itemBuilder: (context, index) {
                      final c = conceptos[index];
                      final id = c['id'] as int?;
                      final name = c['name']?.toString() ?? 'Concepto $index';
                      final subtitle = c['legal_basis']?.toString();
                      return RadioListTile<int>(
                        value: id ?? index,
                        groupValue: tempSelected,
                        title: Text(name),
                        subtitle: subtitle != null ? Text(subtitle) : null,
                        onChanged: (int? v) {
                          setState(() {
                            tempSelected = v;
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempSelected),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        conceptosSeleccionados = [result];
      });
    }
  }

  Future<void> guardarInfraccion() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

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

      final infraccionData = {
        'visitado_name': nombreVisitadoController.text,
        'visitado_identification': tipoIdentificacion,
        'num_identificacion': numIdentificacionController.text,
        'establishment_name': nombreEstablecimientoController.text,
        'establishment_business': giroSeleccionado,
        'establishment_address': jsonEncode(addressData),
        'reglamento': jsonEncode(reglamentosSeleccionados),
        // Save the primary concept id (first selected) to match DB schema (INTEGER FK)
        'concept_id':
            conceptosSeleccionados.isNotEmpty
                ? conceptosSeleccionados.first
                : null,
        'testigo1': testigo1Controller.text,
        'testigo2': testigo2Controller.text,
        'agent_id': prefs.getString('loggedUserId'),
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
      print(e);
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
              // Reglamentos (opens a dialog to select multiple reglamentos)
              GestureDetector(
                onTap: _showReglamentosDialog,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Reglamentos",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          reglamentosSeleccionados.isEmpty
                              ? Row(
                                children: const [
                                  Expanded(
                                    child: Text('Seleccione reglamentos'),
                                  ),
                                  Icon(Icons.arrow_drop_down),
                                ],
                              )
                              : Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children:
                                            reglamentosSeleccionados
                                                .map(
                                                  (r) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 8.0,
                                                        ),
                                                    child: Chip(label: Text(r)),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Conceptos (opens a dialog to select one or more conceptos from DB)
              GestureDetector(
                onTap: _showConceptosDialog,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Conceptos",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          conceptosSeleccionados.isEmpty
                              ? Row(
                                children: const [
                                  Expanded(child: Text('Seleccione conceptos')),
                                  Icon(Icons.arrow_drop_down),
                                ],
                              )
                              : Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children:
                                            conceptosSeleccionados.map((id) {
                                              final concept = conceptos
                                                  .firstWhere(
                                                    (c) => c['id'] == id,
                                                    orElse:
                                                        () => {
                                                          'name': id.toString(),
                                                        },
                                                  );
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 8.0,
                                                ),
                                                child: Chip(
                                                  label: Text(
                                                    concept['name'].toString(),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                    ),
                  ],
                ),
              ),

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
