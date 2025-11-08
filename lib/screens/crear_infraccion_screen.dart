import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infractions_inspector/components/app_bar.dart';
import 'package:infractions_inspector/screens/menu_screen.dart';
import 'package:infractions_inspector/services/db_controller.dart';
import 'package:infractions_inspector/services/pdf_generator.dart';
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
  bool formLocked = false;
  Map<String, dynamic>? lastSavedInfraccion;
  int? lastSavedInfraccionId;

  // Form controllers
  final nombreVisitadoController = TextEditingController();
  final numIdentificacionController = TextEditingController();
  final nombreEstablecimientoController = TextEditingController();
  final giroOtroController = TextEditingController();
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
  final List<String> giros = ['Tienda', 'Restaurante', 'Cafetería', 'Otro'];
  List<String> reglamentos = [];
  List<Map<String, dynamic>> conceptos = [];
  List<Map<String, dynamic>> filteredConceptos = [];
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
        filteredConceptos = loadedConceptos;
        agentes = loadedAgentes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando datos. Por favor intente más tarde'),
        ),
      );
    }
  }

  Future<void> updateAllowedConceptos(List<String> reglamentos) async {
    List<Map<String, dynamic>> newConceptos = [];

    for (final concepto in conceptos) {
      final String reglamentoFromConcepto = concepto['legal_basis'].toString();
      final List<String> parts = reglamentoFromConcepto.split(RegExp(r'\s+'));
      final String articuloFromConcepto = parts.take(2).join(' ');

      if (reglamentos.contains(articuloFromConcepto)) {
        newConceptos.add(concepto);
      }
    }

    setState(() {
      filteredConceptos = newConceptos;
    });
  }

  Future<void> showReglamentosSelector() async {
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
              onPressed: () async {
                // Update allowed conceptos based on the temporary reglamentos selection
                await updateAllowedConceptos(tempSelected);
                Navigator.of(context).pop(tempSelected);
              },
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
      // Update allowed conceptos after the selection has been applied
      await updateAllowedConceptos(result);
    }
  }

  Future<void> showConceptosSelector() async {
    // Multi-select dialog for conceptos (store list of ids)
    final List<int> tempSelected = List<int>.from(conceptosSeleccionados);

    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar conceptos'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredConceptos.length,
                    itemBuilder: (context, index) {
                      final c = filteredConceptos[index];
                      final id = (c['id'] is int) ? c['id'] as int : index;
                      final name = c['name']?.toString() ?? 'Concepto $index';
                      final subtitle = c['legal_basis']?.toString();
                      final checked = tempSelected.contains(id);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(name),
                        subtitle: subtitle != null ? Text(subtitle) : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? v) {
                          setState(() {
                            if (v == true) {
                              if (!tempSelected.contains(id))
                                tempSelected.add(id);
                            } else {
                              tempSelected.remove(id);
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
        conceptosSeleccionados = result;
      });
    }
  }

  Future<void> guardarInfraccion() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final db = await DBController.instance.database;

    setState(() {
      isSaving = true;
    });

    try {
      final addressData = {
        'calle': calleController.text,
        'ext_num': numExtController.text,
        'interior_num':
            numIntController.text == '' ? null : numIntController.text,
        'colonia': coloniaController.text,
        'entrecalle1': entrecalle1Controller.text,
        'entrecalle2': entrecalle2Controller.text,
      };

      // compute folio: inspectorId/secuencial (secuencial = max existing + 1)
      final agentIdStr = prefs.getString('loggedUserId');
      final agentId = int.tryParse(agentIdStr ?? '') ?? 0;
      final folio = await DBController.nextFolioForAgent(agentId);

      final infraccionData = {
        'visitado_name': nombreVisitadoController.text,
        'visitado_identification': tipoIdentificacion,
        'num_identificacion': numIdentificacionController.text,
        'establishment_name': nombreEstablecimientoController.text,
        'establishment_business':
            giroSeleccionado == 'Otro'
                ? giroOtroController.text
                : giroSeleccionado,
        'establishment_address': jsonEncode(addressData),
        'reglamento': jsonEncode(reglamentosSeleccionados),
        // Save the list of selected concept ids as JSON so DB can store multiple concepts
        'concept_ids':
            conceptosSeleccionados.isNotEmpty
                ? jsonEncode(conceptosSeleccionados)
                : jsonEncode([]),
        'folio': folio,
        'testigo1': testigo1Controller.text,
        'testigo2': testigo2Controller.text,
        'agent_id': prefs.getString('loggedUserId'),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final id = await db.insert('Infractions', infraccionData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Infracción guardada con ID: $id')),
      );

      // store last saved data for PDF generation
      lastSavedInfraccionId = id as int? ?? id;
      lastSavedInfraccion = Map<String, dynamic>.from(infraccionData);
      setState(() {
        formLocked = true;
      });
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
    await previewPdf();
  }

  Future<void> showAgentSelector(TextEditingController controller) async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar agente'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: agentes.length,
              itemBuilder: (context, index) {
                final agente = agentes[index];
                return ListTile(
                  title: Text(agente['name']?.toString() ?? 'Agente $index'),
                  subtitle:
                      agente['badge'] != null
                          ? Text('Placa: ${agente['badge']}')
                          : null,
                  onTap: () {
                    Navigator.of(context).pop(agente);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      setState(() {
        controller.text = selected['name']?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    nombreVisitadoController.dispose();
    numIdentificacionController.dispose();
    nombreEstablecimientoController.dispose();
    giroOtroController.dispose();
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

  Future<void> previewPdf() async {
    final prefs = await SharedPreferences.getInstance();
    final agentIdStr = prefs.getString('loggedUserId');
    final agentId = int.parse(agentIdStr ?? '');
    final folio = await DBController.nextFolioForAgent(agentId);

    final data = {
      'visitado_name': nombreVisitadoController.text,
      'visitado_identification': tipoIdentificacion,
      'num_identificacion': numIdentificacionController.text,
      'establishment_name': nombreEstablecimientoController.text,
      'establishment_business':
          giroSeleccionado == 'Otro'
              ? giroOtroController.text
              : giroSeleccionado,
      'establishment_address': jsonEncode({
        'calle': calleController.text,
        'ext_num': numExtController.text,
        'interior_num': numIntController.text,
        'colonia': coloniaController.text,
        'entrecalle1': entrecalle1Controller.text,
        'entrecalle2': entrecalle2Controller.text,
      }),
      'reglamento': jsonEncode(reglamentosSeleccionados),
      'concept_ids': jsonEncode(conceptosSeleccionados),
      'testigo1': testigo1Controller.text,
      'testigo2': testigo2Controller.text,
      'agent_id': agentId,
      'folio': folio,
      'timestamp': DateTime.now().toIso8601String(),
    };

    PdfGenerator.showPdfPreview(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: generateAppBar(
        context,
        "Crear infracción",
        showBack: true,
        onBack:
            () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MenuScreen()),
              (route) => false,
            ),
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
                enabled: !formLocked,
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
                onChanged:
                    formLocked
                        ? null
                        : (value) {
                          setState(() {
                            tipoIdentificacion = value!;
                          });
                        },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: numIdentificacionController,
                enabled: !formLocked,
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
                enabled: !formLocked,
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
                onChanged:
                    formLocked
                        ? null
                        : (value) {
                          setState(() {
                            giroSeleccionado = value!;
                          });
                        },
                validator:
                    (value) =>
                        value?.isEmpty == true ? 'Seleccione un giro' : null,
              ),
              // If 'Otro' is selected, show a text field to input a custom giro
              if (giroSeleccionado == 'Otro') ...[
                SizedBox(height: 8),
                TextFormField(
                  controller: giroOtroController,
                  enabled: !formLocked,
                  decoration: InputDecoration(labelText: 'Giro (especifique)'),
                  validator: (value) {
                    if (giroSeleccionado == 'Otro' &&
                        (value == null || value.isEmpty)) {
                      return 'Especifique el giro';
                    }
                    return null;
                  },
                ),
              ],

              // 3. Domicilio del establecimiento
              SizedBox(height: 24),
              buildSectionTitle('Domicilio del establecimiento'),
              TextFormField(
                controller: calleController,
                enabled: !formLocked,
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
                      enabled: !formLocked,
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
                      enabled: !formLocked,
                      decoration: InputDecoration(labelText: 'Número interior'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: coloniaController,
                enabled: !formLocked,
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
                enabled: !formLocked,
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
                enabled: !formLocked,
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
              FormField<List<String>>(
                initialValue: reglamentosSeleccionados,
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Reglamentos",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            formLocked
                                ? null
                                : () async {
                                  await showReglamentosSelector();
                                  // after selector updates, revalidate this field
                                  state.validate();
                                },
                        child: Container(
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
                                                        child: Chip(
                                                          label: Text(r),
                                                        ),
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
                      ),
                      if (state.errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16),
              // Conceptos (opens a dialog to select one or more conceptos from DB)
              FormField<List<int>>(
                initialValue: conceptosSeleccionados,

                builder: (state) {
                  //state.didChange(conceptosSeleccionados);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Conceptos",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            formLocked
                                ? null
                                : () async {
                                  await showConceptosSelector();
                                  state.validate();
                                },
                        child: Container(
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
                                      Expanded(
                                        child: Text('Seleccione conceptos'),
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
                                                conceptosSeleccionados.map((
                                                  id,
                                                ) {
                                                  final concept = filteredConceptos
                                                      .firstWhere(
                                                        (c) => c['id'] == id,
                                                        orElse:
                                                            () => {
                                                              'name':
                                                                  id.toString(),
                                                            },
                                                      );
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 8.0,
                                                        ),
                                                    child: Chip(
                                                      label: Text(
                                                        concept['name']
                                                            .toString(),
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
                      ),
                      if (state.errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Testigos
              SizedBox(height: 16),
              TextFormField(
                controller: testigo1Controller,
                decoration: InputDecoration(
                  labelText: 'Testigo 1',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.person_search),
                    onPressed:
                        formLocked
                            ? null
                            : () {
                              showAgentSelector(testigo1Controller);
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
                    onPressed:
                        formLocked
                            ? null
                            : () {
                              showAgentSelector(testigo2Controller);
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
                  if (lastSavedInfraccion == null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.preview),
                        label: Text('Vista Previa'),
                        onPressed: (isSaving || formLocked) ? null : previewPdf,
                      ),
                    ),

                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                        onPressed:
                            (isSaving || formLocked) ? null : guardarInfraccion,
                      ),
                    ),
                  ],
                  if (lastSavedInfraccion != null) ...[
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('Generar PDF'),
                        onPressed: () {
                          PdfGenerator.showPdfPreview(
                            context,
                            lastSavedInfraccion!,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.home),
                label: Text('Volver al menú'),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => MenuScreen()),
                    (route) => false,
                  );
                },
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
