import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../domain/models/transaction_item.dart';

class LocalPdfReportGenerator {
  // Colores extraídos exactamente de ReportStyler.java
  static const _primaryBlue = PdfColor.fromInt(0xff009ffb);
  static const _textMain = PdfColor.fromInt(0xff2d3748);
  static const _textLight = PdfColor.fromInt(0xff718096);
  static const _softBg = PdfColor.fromInt(0xfff7fafc);
  static const _border = PdfColor.fromInt(0xffe2e8f0);
  static const _tableHeaderBg = PdfColor.fromInt(0xfff5f8fa);

  static Future<Uint8List> generate({
    required String title,
    required String period,
    required Map<String, double> summary,
    required Map<String, Map<String, List<TransactionItem>>> segregatedData,
    String lang = 'es',
  }) async {
    final pdf = pw.Document();

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // 1. Cabecera (clonada de addModernHeader)
          pw.Text('NATAVE', style: pw.TextStyle(font: fontBold, fontSize: 24, color: _primaryBlue)),
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 12, color: _textMain)),
          pw.SizedBox(height: 4),
          pw.Text('PERIODO: $period', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: _textLight)),
          pw.SizedBox(height: 20),

          // 2. Resumen (clonado de addModernSummary)
          if (summary.isNotEmpty) ...[
            pw.Text('RESUMEN GENERAL', style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain)),
            pw.SizedBox(height: 10),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
              },
              children: summary.entries.map((e) => pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5))),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(e.key, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: _textMain)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('€ ${e.value.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain)),
                    ),
                  ),
                ],
              )).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: _border, thickness: 1),
            pw.SizedBox(height: 20),
          ],

          // 3. Contenido Segregado (clonado de renderModernSegregatedContent)
          ...segregatedData.entries.expand((entityEntry) {
            final List<pw.Widget> widgets = [];
            
            // Badge de Entidad
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xfff0f7ff),
                  border: pw.Border(left: pw.BorderSide(color: _primaryBlue, width: 4)),
                ),
                child: pw.Text('ENTIDAD: ${entityEntry.key.toUpperCase()}', 
                  style: pw.TextStyle(font: fontBold, fontSize: 12, color: _textMain)),
              ),
            );
            widgets.add(pw.SizedBox(height: 12));

            for (var accEntry in entityEntry.value.entries) {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
                child: pw.Text('CUENTA: ${accEntry.key.toUpperCase()}', 
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain)),
              ));

              // Tabla de Transacciones
              widgets.add(
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(70), // Fecha
                    1: const pw.FlexColumnWidth(2),   // Categoría
                    2: const pw.FlexColumnWidth(3),   // Descripción
                    3: const pw.FixedColumnWidth(70), // Importe
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _tableHeaderBg, border: pw.Border(bottom: pw.BorderSide(color: _border))),
                      children: ['FECHA', 'CATEGORÍA', 'DESCRIPCIÓN', 'IMPORTE'].map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(h, style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain)),
                      )).toList(),
                    ),
                    // Rows
                    ...accEntry.value.map((tx) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx.date));
                      final catStr = (tx.category?.name ?? 'Otros') + (tx.subcategory != null ? ' > ${tx.subcategory!.name}' : '');
                      final amountStr = '${tx.amount.isNegative ? '-' : '+'} €${(tx.amount.value / 100).abs().toStringAsFixed(2)}';
                      
                      return pw.TableRow(
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5))),
                        children: [
                          _buildCell(dateStr, fontRegular),
                          _buildCell(catStr, fontRegular),
                          _buildCell(tx.description ?? '', fontRegular),
                          _buildCell(amountStr, fontRegular, alignRight: true),
                        ],
                      );
                    }),
                  ],
                ),
              );
              widgets.add(pw.SizedBox(height: 20));
            }
            return widgets;
          }).toList(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCell(String text, pw.Font font, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: _textMain)),
      ),
    );
  }
}
