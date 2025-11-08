import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:infractions_inspector/components/app_bar.dart';
import 'package:infractions_inspector/screens/menu_screen.dart';
import 'package:infractions_inspector/services/db_controller.dart';
import 'package:infractions_inspector/services/pdf_generator.dart';

class ConsultarInfraccionScreen extends StatefulWidget {
  const ConsultarInfraccionScreen({super.key});

  @override
  State<ConsultarInfraccionScreen> createState() =>
      _ConsultarInfraccionScreenState();
}

class _ConsultarInfraccionScreenState extends State<ConsultarInfraccionScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool loading = false;
  String query = '';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Updates the existing records (_rows List) stored on Infractions table, ordered by date and time
  Future<void> refresh() async {
    setState(() {
      loading = true;
    });
    try {
      final db = await DBController.instance.database;
      final rows = await db.query('Infractions', orderBy: 'timestamp DESC');
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error leyendo la base de datos. Por favor intente más tarde',
            ),
          ),
        );
      }
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// Returns a list of filtered records based on current values of 'query'
  /// Query is updated by the TextField used to filter by Folio
  List<Map<String, dynamic>> get filteredRows {
    if (query.isEmpty) return _rows;
    final q = query.toLowerCase();
    return _rows.where((r) {
      final folio = r['folio'].toString().toLowerCase();
      return folio.contains(q);
    }).toList();
  }

  /// Builds the card (row) for the record received (expecting an Infraction record)
  Widget buildRecordCard(Map<String, dynamic> r) {
    final agentId = r['agent_id'].toString();
    final folio = r['folio'].toString();
    final visitado = r['visitado_name'].toString();
    final establishment = r['establishment_name'].toString();
    final timestamp = r['timestamp'].toString();
    List<String> conceptosList = [];
    try {
      final concepts = r['concept_ids'];
      final decodedConceptsList =
          json.decode(concepts)
              as List; // Converts the list of concepts stored as a String to List type
      conceptosList = decodedConceptsList.map((e) => e.toString()).toList();
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text('$agentId/$folio')),
        title: Text('Folio: $agentId/$folio'),
        subtitle: Text('$visitado — $establishment'),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          if (timestamp.isNotEmpty)
            Text('Fecha: ${timestamp.substring(0, 10)}'),
          const SizedBox(height: 8),
          Text('Conceptos: ${conceptosList.join(', ')}'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Vista previa PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => PdfGenerator.showPdfPreview(context, r),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredRows;
    return Scaffold(
      appBar: generateAppBar(
        context,
        "Consultar infracción",
        showBack: true,
        onBack:
            () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MenuScreen()),
              (route) => false,
            ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por folio',
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (v) => setState(
                    () => query = v,
                  ), // When Text is typed, updates the value of 'query' so it can be filtered by 'filteredRows'
            ),
          ),
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: refresh,
                      child:
                          list
                                  .isEmpty // If there are no Infraction records, just shows a message indicating so
                              ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'No se encontraron infracciones',
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (c, i) => buildRecordCard(list[i]),
                              ),
                    ),
          ),
        ],
      ),
    );
  }
}
