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
      case 'EUR': return '\u20AC'; // Usamos el código Unicode para evitar errores de renderizado
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
    
    // Usamos fuentes integradas pero con manejo explícito de Unicode si es necesario
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Cabecera
          pw.Text('NATAVE', style: pw.TextStyle(font: fontBold, fontSize: 24, color: _primaryBlue)),
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 12, color: _textMain)),
          pw.SizedBox(height: 4),
          pw.Text('PERIODO: $period', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: _textLight)),
          pw.SizedBox(height: 20),

          // Resumen
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
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: e.value.entries.map((curr) => 
                        pw.Text('${_getCurrencySymbol(curr.key)} ${curr.value.toStringAsFixed(2)}', 
                          style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMain))
                      ).toList(),
                    ),
                  ),
                ],
              )).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: _border, thickness: 1),
            pw.SizedBox(height: 20),
          ],

          // Datos por Entidad
          ...segregatedData.entries.expand((entityEntry) {
            final List<pw.Widget> widgets = [];
            
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

              widgets.add(
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
                      final amountStr = '${tx.amount.isNegative ? '-' : '+'} ${_getCurrencySymbol(tx.amount.currency)}${(tx.amount.value / 100).abs().toStringAsFixed(2)}';
                      
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
