import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/account_item.dart';

class PdfReportService {
  static Future<void> generateFinancialReport({
    required String title,
    required List<TransactionItem> transactions,
    required List<AccountItem> accounts,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cash Organizer - Financial Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text(DateTime.now().toString().split(' ')[0]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            
            pw.Text('Account Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['Account', 'Type', 'Balance'],
              data: accounts.map((acc) => [
                acc.name,
                acc.accountType ?? 'N/A',
                '€ ${(acc.amount.value / 100).toStringAsFixed(2)}'
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            
            pw.SizedBox(height: 30),
            pw.Text('Recent Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Description', 'Amount'],
              data: transactions.map((tx) => [
                tx.date.split('T')[0],
                tx.category?.name ?? 'General',
                tx.description,
                '${tx.amount.isNegative ? "-" : ""}€ ${(tx.amount.value / 100).toStringAsFixed(2)}'
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
