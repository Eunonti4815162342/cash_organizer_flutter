import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:natave_flutter/domain/models/transaction_item.dart';

class LocalPdfReportGenerator {
  // Paleta (en sync con el backend Java)
  static const _blue      = PdfColor.fromInt(0xff009ffb);
  static const _greenInc  = PdfColor.fromInt(0xff00a86b);
  static const _redExp    = PdfColor.fromInt(0xffdc3545);
  static const _textMain  = PdfColor.fromInt(0xff1e2837);
  static const _textLight = PdfColor.fromInt(0xff6e8191);
  static const _border    = PdfColor.fromInt(0xffe6e8f0);
  static const _rowAlt    = PdfColor.fromInt(0xfffafcfe);
  static const _headerBg  = PdfColor.fromInt(0xfff2f6fa);

  static String _sym(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      case 'BRL': return 'R\$';
      default:    return currency;
    }
  }

  static Future<Uint8List> generate({
    required String title,
    required String period,
    required Map<String, Map<String, double>> summary,
    required Map<String, Map<String, List<TransactionItem>>> segregatedData,
    String lang = 'es',
  }) async {
    final pdf     = pw.Document();
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Arial-Regular.ttf'));
    final bold    = pw.Font.ttf(await rootBundle.load('assets/fonts/Arial-Bold.ttf'));

    double totalIncome = 0, totalExpense = 0;
    int txCount = 0;
    for (var entity in segregatedData.values) {
      for (var acc in entity.values) {
        txCount += acc.length;
        for (var tx in acc) {
          if (tx.amount.isNegative) {
            totalExpense += tx.amount.value.abs() / 100.0;
          } else {
            totalIncome += tx.amount.value / 100.0;
          }
        }
      }
    }
    final balance = totalIncome - totalExpense;

    // ── Página de resumen ─────────────────────────────────────────────────
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 50),
      footer: (ctx) => _footer(ctx, regular),
      build: (ctx) => [
        _headerBand(title, period, txCount, bold, regular),
        pw.SizedBox(height: 20),
        _kpiRow(totalIncome, totalExpense, balance, bold, regular),
        pw.SizedBox(height: 24),
        if (summary.isNotEmpty) _summaryTable(summary, bold, regular),
      ],
    ));

    // ── Una página por entidad ────────────────────────────────────────────
    for (final entityEntry in segregatedData.entries) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 50),
        footer: (ctx) => _footer(ctx, regular),
        build: (ctx) => [
          _entityBand(entityEntry.key, bold, regular),
          pw.SizedBox(height: 16),
          for (final accEntry in entityEntry.value.entries) ...[
            _accountHeader(accEntry.key, bold),
            pw.SizedBox(height: 10),
            _txTable(accEntry.value, bold, regular),
            pw.SizedBox(height: 24),
          ],
        ],
      ));
    }

    return pdf.save();
  }

  // ── Secciones ─────────────────────────────────────────────────────────────

  static pw.Widget _headerBand(String title, String period, int count,
      pw.Font bold, pw.Font regular) {
    return pw.Container(
      width: double.infinity,
      color: _blue,
      padding: const pw.EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('NATAVE',
            style: pw.TextStyle(font: bold, fontSize: 28, color: PdfColors.white)),
        pw.SizedBox(height: 4),
        pw.Text(title.toUpperCase(),
            style: pw.TextStyle(font: regular, fontSize: 10,
                color: const PdfColor.fromInt(0xffbee3ff))),
        pw.SizedBox(height: 12),
        pw.Text('PERIODO: $period   ·   $count movimientos',
            style: pw.TextStyle(font: regular, fontSize: 8,
                color: const PdfColor.fromInt(0xffaad4ff))),
      ]),
    );
  }

  static pw.Widget _entityBand(String name, pw.Font bold, pw.Font regular) {
    return pw.Container(
      width: double.infinity,
      color: _blue,
      padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(name.toUpperCase(),
            style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.white)),
        pw.SizedBox(height: 2),
        pw.Text('ENTIDAD',
            style: pw.TextStyle(font: regular, fontSize: 8,
                color: const PdfColor.fromInt(0xffbee3ff))),
      ]),
    );
  }

  static pw.Widget _kpiRow(double income, double expense, double balance,
      pw.Font bold, pw.Font regular) {
    final netColor = balance >= 0 ? _blue : const PdfColor.fromInt(0xffe67e22);
    return pw.Row(children: [
      pw.Expanded(child: _kpiCard('INGRESOS', income, _greenInc, bold, regular)),
      pw.SizedBox(width: 10),
      pw.Expanded(child: _kpiCard('GASTOS', expense, _redExp, bold, regular)),
      pw.SizedBox(width: 10),
      pw.Expanded(child: _kpiCard('NETO', balance, netColor, bold, regular)),
    ]);
  }

  static pw.Widget _kpiCard(String label, double value, PdfColor accent,
      pw.Font bold, pw.Font regular) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(top: pw.BorderSide(color: accent, width: 3)),
      ),
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label,
            style: pw.TextStyle(font: regular, fontSize: 8, color: _textLight)),
        pw.SizedBox(height: 6),
        pw.Text('€${value.toStringAsFixed(2)}',
            style: pw.TextStyle(font: bold, fontSize: 16, color: accent)),
      ]),
    );
  }

  static pw.Widget _summaryTable(Map<String, Map<String, double>> summary,
      pw.Font bold, pw.Font regular) {
    final total = summary.values
        .expand((m) => m.values)
        .fold(0.0, (s, v) => s + v.abs());

    final rows = summary.entries.toList();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('RESUMEN GENERAL',
          style: pw.TextStyle(font: bold, fontSize: 8, color: _textLight)),
      pw.SizedBox(height: 8),
      pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1.5),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _headerBg),
            children: [
              _headerCell('CATEGORÍA', bold),
              _headerCell('IMPORTE', bold, alignRight: true),
            ],
          ),
          ...rows.asMap().entries.map((e) {
            final idx   = e.key;
            final entry = e.value;
            final rowTotal = entry.value.values.fold(0.0, (s, v) => s + v.abs());
            final pct = total > 0 ? rowTotal / total * 100 : 0.0;
            final bg  = idx % 2 == 0 ? PdfColors.white : _rowAlt;
            final amtStr = entry.value.entries
                .map((c) => '${c.value.abs().toStringAsFixed(2)} ${_sym(c.key)}')
                .join('  ');
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: bg,
                border: const pw.Border(
                    bottom: pw.BorderSide(color: _border, width: 0.5)),
              ),
              children: [
                _dataCell('${entry.key}  (${pct.toStringAsFixed(0)}%)', regular),
                _dataCell(amtStr, bold, alignRight: true),
              ],
            );
          }),
        ],
      ),
    ]);
  }

  static pw.Widget _accountHeader(String name, pw.Font bold) {
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xfff0f6fd),
        border: pw.Border(left: pw.BorderSide(color: _blue, width: 3)),
      ),
      padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: pw.Text(name,
          style: pw.TextStyle(font: bold, fontSize: 10, color: _textMain)),
    );
  }

  static pw.Widget _txTable(List<TransactionItem> txs,
      pw.Font bold, pw.Font regular) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(90),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: ['FECHA', 'CATEGORÍA', 'DESCRIPCIÓN', 'IMPORTE']
              .map((h) => _headerCell(h, bold))
              .toList(),
        ),
        ...txs.asMap().entries.map((e) {
          final i  = e.key;
          final tx = e.value;
          final bg = i % 2 == 0 ? PdfColors.white : _rowAlt;
          final cat = (tx.category?.name ?? 'Otros') +
              (tx.subcategory != null ? ' › ${tx.subcategory!.name}' : '');
          final date  = tx.date.length > 10 ? tx.date.substring(0, 10) : tx.date;
          final isNeg = tx.amount.isNegative;
          final sign  = isNeg ? '-' : '+';
          final val   = (tx.amount.value / 100).abs().toStringAsFixed(2);
          final sym   = _sym(tx.amount.currency);

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: bg,
              border: const pw.Border(
                  bottom: pw.BorderSide(color: _border, width: 0.5)),
            ),
            children: [
              _dataCell(date, regular),
              _dataCell(cat, regular),
              _dataCell(tx.description, regular),
              _amountCell('$sign $val $sym', bold,
                  isNeg ? _redExp : _greenInc),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx, pw.Font regular) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5))),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('NATAVE',
              style: pw.TextStyle(font: regular, fontSize: 7, color: _textLight)),
          pw.Text('Página ${ctx.pageNumber}',
              style: pw.TextStyle(font: regular, fontSize: 7, color: _textLight)),
        ],
      ),
    );
  }

  // ── Helpers de celda ─────────────────────────────────────────────────────

  static pw.Widget _headerCell(String text, pw.Font bold,
      {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text,
            style: pw.TextStyle(font: bold, fontSize: 9, color: _textMain)),
      ),
    );
  }

  static pw.Widget _dataCell(String text, pw.Font font,
      {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text,
            style: pw.TextStyle(font: font, fontSize: 9, color: _textMain)),
      ),
    );
  }

  static pw.Widget _amountCell(String text, pw.Font bold, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(text,
            style: pw.TextStyle(font: bold, fontSize: 9, color: color)),
      ),
    );
  }
}
