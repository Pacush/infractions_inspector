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
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
    });
    try {
      final db = await DBController.instance.database;
      final rows = await db.query('Infractions', orderBy: 'timestamp DESC');
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows);
      });
    } catch (e) {
      // show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leyendo la base de datos: $e')),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    if (_query.isEmpty) return _rows;
    final q = _query.toLowerCase();
    return _rows.where((r) {
      final folio = (r['folio'] ?? '').toString().toLowerCase();
      final visitado = (r['visitado_name'] ?? '').toString().toLowerCase();
      final est = (r['establishment_name'] ?? '').toString().toLowerCase();
      return folio.contains(q) || visitado.contains(q) || est.contains(q);
    }).toList();
  }

  void _showPdfForRow(Map<String, dynamic> row) {
    // If your stored record isn't exactly the payload PdfGenerator expects,
    // adapt this mapping to build the required data map.
    final payload = Map<String, dynamic>.from(row);
    // ensure concept_ids is a list, not a JSON string
    if (payload['concept_ids'] is String) {
      try {
        final decoded = json.decode(payload['concept_ids'] as String);
        payload['concept_ids'] = decoded;
      } catch (_) {
        // leave as-is
      }
    }
    PdfGenerator.showPdfPreview(context, payload);
  }

  Widget _buildRowTile(Map<String, dynamic> r) {
    final id = r['id'];
    final agent_id = r['agent_id'].toString();
    final folio = r['folio']?.toString() ?? '';
    final visitado = r['visitado_name']?.toString() ?? '—';
    final establishment = r['establishment_name']?.toString() ?? '';
    final timestamp = r['timestamp']?.toString() ?? '';
    List<String> conceptosList = [];
    if (r['concept_ids'] != null) {
      try {
        final raw = r['concept_ids'];
        if (raw is String) {
          final decoded = json.decode(raw) as List;
          conceptosList = decoded.map((e) => e.toString()).toList();
        } else if (raw is List) {
          conceptosList = raw.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(folio.split('/').last), // show sequence part
        ),
        title: Text('Folio: $agent_id/$folio'),
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
                onPressed: () => _showPdfForRow(r),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredRows;
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
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: refresh,
                      child:
                          list.isEmpty
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
                                itemBuilder: (c, i) => _buildRowTile(list[i]),
                              ),
                    ),
          ),
        ],
      ),
    );
  }
}
