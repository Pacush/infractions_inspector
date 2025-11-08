import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infractions_inspector/services/db_controller.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  /// Compute next folio for an agent in format 'agentId/seq'

  /// Build PDF bytes from infraction data map.
  static Future<Uint8List> buildPdfBytes(Map<String, dynamic> data) async {
    final folioFormatted =
        data['agent_id'].toString() + "/" + data['folio'].toString();
    final pdf = pw.Document();
    // Load logo if available
    pw.ImageProvider? logo;
    try {
      final bytes =
          (await rootBundle.load(
            'assets/images/logo.png',
          )).buffer.asUint8List();
      logo = pw.MemoryImage(bytes);
    } catch (_) {
      logo = null;
    }

    final db = await DBController.instance.database;
    final agentId =
        data['agent_id'] is int
            ? data['agent_id'] as int
            : int.tryParse(data['agent_id']?.toString() ?? '') ?? 0;
    Map<String, dynamic>? agent;
    if (agentId != 0) {
      final rows = await db.query(
        'Agents',
        where: 'id = ?',
        whereArgs: [agentId],
      );
      if (rows.isNotEmpty) agent = rows.first;
    }
    Map<String, dynamic>? jef;
    if (agent != null && agent['jefatura_id'] != null) {
      jef = await DBController.instance.getJefatura(
        agent['jefatura_id'] as int,
      );
    }

    // Concepts
    List<int> conceptIds = [];
    try {
      final decoded = json.decode(data['concept_ids']?.toString() ?? '[]');
      conceptIds = List<int>.from(
        (decoded as List).map((e) => int.parse(e.toString())),
      );
    } catch (_) {}

    List<Map<String, dynamic>> conceptRows = [];
    if (conceptIds.isNotEmpty) {
      final q = await db.query('Concepts');
      for (final c in q) {
        if (conceptIds.contains(c['id'])) conceptRows.add(c);
      }
    }

    // Parse and group legal_basis
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final c in conceptRows) {
      final lb = c['legal_basis']?.toString() ?? '';
      String regl = lb;
      int art = 0;
      final lower = lb.toLowerCase();
      final idx = lower.indexOf('artículo');
      if (idx >= 0) {
        regl = lb.substring(0, idx).trim();
        // attempt to parse number after 'Artículo'
        final after = lb.substring(idx + 'artículo'.length);
        final m = RegExp(r"(\d+)").firstMatch(after);
        if (m != null) art = int.tryParse(m.group(0) ?? '0') ?? 0;
      }
      groups.putIfAbsent(regl, () => []).add({...c, 'article_num': art});
    }

    // Sort groups by smallest article number
    final sortedGroups =
        groups.entries.toList()..sort((a, b) {
          final aMin = a.value
              .map((e) => e['article_num'] as int? ?? 0)
              .fold<int>(999999, (p, n) => p == 999999 ? n : (n < p ? n : p));
          final bMin = b.value
              .map((e) => e['article_num'] as int? ?? 0)
              .fold<int>(999999, (p, n) => p == 999999 ? n : (n < p ? n : p));
          return aMin.compareTo(bMin);
        });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      jef?['name']?.toString() ?? '',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Folio: $folioFormatted',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (logo != null)
                  pw.Container(width: 60, height: 60, child: pw.Image(logo)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Datos del visitado',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Nombre: ${data['visitado_name'] ?? ''}'),
            pw.Text(
              'Tipo identificación: ${data['visitado_identification'] ?? ''}',
            ),
            pw.Text(
              'Número de identificación: ${data['num_identificacion'] ?? ''}',
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Datos del establecimiento',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Nombre: ${data['establishment_name'] ?? ''}'),
            pw.Text('Giro: ${data['establishment_business'] ?? ''}'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Datos de la infracción',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Conceptos:'),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  conceptRows
                      .map((c) => pw.Text('- ${c['name'] ?? ''}'))
                      .toList(),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Fundamento legal:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  sortedGroups.map((g) {
                    final list =
                        g.value..sort(
                          (a, b) => (a['article_num'] as int).compareTo(
                            b['article_num'] as int,
                          ),
                        );
                    final concat = list
                        .map((e) => e['legal_basis']?.toString() ?? '')
                        .join(' \n');
                    return pw.Padding(
                      padding: pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text(concat),
                    );
                  }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Inspector: ${agent?['name'] ?? ''}'),
                    pw.SizedBox(height: 24),
                    pw.Text('_______________________'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Firma visitado:'),
                    pw.SizedBox(height: 24),
                    pw.Text('_______________________'),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Show a PDF preview route
  static void showPdfPreview(BuildContext context, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: Text('Vista preliminar PDF')),
              body: PdfPreview(build: (format) => buildPdfBytes(data)),
            ),
      ),
    );
  }
}


