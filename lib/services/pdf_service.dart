import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../data/models/log_model.dart';
import '../data/models/appliance_model.dart';

class PdfService {
  Future<void> generateAndOpenMonthlyReport(
    String username,
    List<LogModel> logs,
    List<ApplianceModel> appliances,
  ) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Calculate totals
    double totalKwh = logs.fold(0.0, (sum, item) => sum + item.kwhUsage);
    double totalCost = logs.fold(0.0, (sum, item) => sum + item.estimatedCost);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(username),
            pw.SizedBox(height: 20),
            _buildSummary(totalKwh, totalCost, currencyFormat),
            pw.SizedBox(height: 20),
            if (appliances.isNotEmpty) ...[
              pw.Text('Appliance Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildApplianceTable(appliances),
              pw.SizedBox(height: 20),
            ],
            pw.Text('Usage History (Recent Logs)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildLogsTable(logs, currencyFormat),
          ];
        },
      ),
    );

    // Save and open
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/PowerLog_Report.pdf');
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  Future<void> generateAndOpenMonthlyCsv(
    String username,
    List<LogModel> logs,
    List<ApplianceModel> appliances,
  ) async {
    const delimiter = ',';
    final logsBuffer = StringBuffer();
    logsBuffer.writeln('Date${delimiter}Usage_kWh${delimiter}Estimated_Cost_IDR');

    for (final log in logs) {
      logsBuffer.writeln(
        '${_csvEscape(log.date)}$delimiter${log.kwhUsage.toStringAsFixed(2)}$delimiter${log.estimatedCost.toStringAsFixed(0)}',
      );
    }

    final appsBuffer = StringBuffer();
    if (appliances.isNotEmpty) {
      appsBuffer.writeln('Appliance${delimiter}Wattage_W${delimiter}Hours_Per_Day${delimiter}Daily_kWh');
      for (final app in appliances) {
        appsBuffer.writeln(
          '${_csvEscape(app.name)}$delimiter${app.wattage.toStringAsFixed(0)}$delimiter${app.hoursPerDay.toStringAsFixed(2)}$delimiter${app.dailyKwh.toStringAsFixed(2)}',
        );
      }
    }

    final output = await getTemporaryDirectory();
    final logsFile = File('${output.path}/PowerLog_Logs.csv');
    final logsContent = '\uFEFF${logsBuffer.toString().replaceAll('\n', '\r\n')}';
    await logsFile.writeAsString(logsContent);

    if (appliances.isNotEmpty) {
      final appsFile = File('${output.path}/PowerLog_Appliances.csv');
      final appsContent = '\uFEFF${appsBuffer.toString().replaceAll('\n', '\r\n')}';
      await appsFile.writeAsString(appsContent);
    }

    await OpenFilex.open(logsFile.path);
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  pw.Widget _buildHeader(String username) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PowerLog', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 4),
        pw.Text('Electricity Usage Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.SizedBox(height: 14),
        pw.Text('User: $username', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text('Date Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummary(double totalKwh, double totalCost, NumberFormat currency) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Total Logged Usage', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('${totalKwh.toStringAsFixed(2)} kWh', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Total Estimated Cost', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(currency.format(totalCost), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildApplianceTable(List<ApplianceModel> appliances) {
    return pw.TableHelper.fromTextArray(
      context: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerHeight: 25,
      cellHeight: 30,
      headers: ['Appliance', 'Wattage', 'Hours/Day', 'Daily kWh'],
      data: appliances.map((app) {
        return [
          app.name,
          '${app.wattage} W',
          '${app.hoursPerDay} h',
          '${app.dailyKwh.toStringAsFixed(2)} kWh',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildLogsTable(List<LogModel> logs, NumberFormat currency) {
    // Only show top 20 to avoid massive PDFs
    final displayLogs = logs.take(20).toList();
    
    return pw.TableHelper.fromTextArray(
      context: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerHeight: 25,
      cellHeight: 30,
      headers: ['Date', 'Usage', 'Estimated Cost'],
      data: displayLogs.map((log) {
        return [
          DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(log.date)),
          '${log.kwhUsage.toStringAsFixed(2)} kWh',
          currency.format(log.estimatedCost),
        ];
      }).toList(),
    );
  }
}
