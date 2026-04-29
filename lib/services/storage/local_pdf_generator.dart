import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';

class LocalPdfReportGenerator {
  static const _primaryBlue = PdfColor.fromInt(0xff009ffb);
  static const _textMain = PdfColor.fromInt(0xff2d3748);
  static const _textLight = PdfColor.fromInt(0xff718096);
  static const _border = PdfColor.fromInt(0xffe2e8f0);
  static const _tableHeaderBg = PdfColor.fromInt(0xfff5f8fa);

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'BRL': return 'R\$';
      case 'USD': return '\$';
      case 'EUR': return 'EU'; // Usamos EU por petición del usuario para evitar errores de fuente
      default: return currency;
    }
  }

  static Future<Uint8List> generate({
    required String title,
    required String period,
    required Map<String, Map<String, double>> summary,
    required Map<String, Map<String, List<TransactionItem>>> segregatedData,
    String lang = 'es',
  }) async {
    final pdf = pw.Document();
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    // 1. PÁGINA DE RESUMEN
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text('NATAVE', style: pw.TextStyle(font: fontBold, fontSize: 24, color: _primaryBlue)),
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 12, color: _textMain)),
          pw.SizedBox(height: 4),
          pw.Text('PERIODO: $period', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: _textLight)),
          pw.SizedBox(height: 20),

          if (summary.isNotEmpty) ...[
            pw.Text('RESUMEN GENERAL', style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain)),
            pw.SizedBox(height: 10),
            pw.Table(
              columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1)},
              children: summary.entries.map((e) => pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5))),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(e.key, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: _textMain)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: e.value.entries.map((curr) => 
                        pw.Text('${curr.value.toStringAsFixed(2)} ${_getCurrencySymbol(curr.key)}', 
                          style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain))
                      ).toList(),
                    ),
                  ),
                ],
              )).toList(),
            ),
          ],
        ],
      ),
    );

    // 2. UNA PÁGINA NUEVA POR CADA ENTIDAD
    for (var entityEntry in segregatedData.entries) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Badge de Entidad (Cabecera de página)
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
            pw.SizedBox(height: 20),

            for (var accEntry in entityEntry.value.entries) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
                child: pw.Text('CUENTA: ${accEntry.key.toUpperCase()}', 
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain)),
              ),

              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(70),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FixedColumnWidth(85),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _tableHeaderBg, border: pw.Border(bottom: pw.BorderSide(color: _border))),
                    children: ['FECHA', 'CATEGORÍA', 'DESCRIPCIÓN', 'IMPORTE'].map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(h, style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain)),
                    )).toList(),
                  ),
                  ...accEntry.value.map((tx) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx.date));
                    final catStr = (tx.category?.name ?? 'Otros') + (tx.subcategory != null ? ' > ${tx.subcategory!.name}' : '');
                    final symbol = _getCurrencySymbol(tx.amount.currency);
                    final amountStr = '${tx.amount.isNegative ? '-' : '+'} ${(tx.amount.value / 100).abs().toStringAsFixed(2)} $symbol';
                    
                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5))),
                      children: [
                        _buildCell(dateStr, fontRegular),
                        _buildCell(catStr, fontRegular),
                        _buildCell(tx.description, fontRegular),
                        _buildCell(amountStr, fontRegular, alignRight: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 30),
            ],
          ],
        ),
      );
    }

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
