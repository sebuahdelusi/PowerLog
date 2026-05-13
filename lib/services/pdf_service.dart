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
    double ratePerKwh,
  ) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Calculate totals
    final totals = _calculateReportTotals(logs, appliances, ratePerKwh);
    final totalLoggedKwh = totals.loggedKwh;
    final totalLoggedCost = totals.loggedCost;
    double dailyApplianceKwh = appliances.fold(
      0.0,
      (sum, item) => sum + item.dailyKwh,
    );
    double monthlyPredictedKwh = dailyApplianceKwh * 30;
    double monthlyPredictedCost = monthlyPredictedKwh * ratePerKwh;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(username),
            pw.SizedBox(height: 20),
            _buildSummary(totalLoggedKwh, totalLoggedCost, currencyFormat),
            pw.SizedBox(height: 20),
            if (appliances.isNotEmpty) ...[
              pw.Text(
                'Appliance Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildApplianceTable(appliances),
              pw.SizedBox(height: 20),
              _buildPredictions(
                dailyApplianceKwh,
                monthlyPredictedKwh,
                monthlyPredictedCost,
                currencyFormat,
              ),
            ],
            if (logs.isEmpty && appliances.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No data available to generate report.',
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              ),
            pw.SizedBox(height: 30),
            _buildFooter(),
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
    final appsBuffer = StringBuffer();
    appsBuffer.writeln(
      'Appliance${delimiter}Wattage_W${delimiter}Hours_Per_Day${delimiter}Daily_kWh',
    );
    for (final app in appliances) {
      appsBuffer.writeln(
        '${_csvEscape(app.name)}$delimiter${app.wattage.toStringAsFixed(0)}$delimiter${app.hoursPerDay.toStringAsFixed(2)}$delimiter${app.dailyKwh.toStringAsFixed(2)}',
      );
    }

    final output = await getTemporaryDirectory();
    final appsFile = File('${output.path}/PowerLog_Appliances.csv');
    final appsContent =
        '\uFEFF${appsBuffer.toString().replaceAll('\n', '\r\n')}';
    await appsFile.writeAsString(appsContent);

    await OpenFilex.open(appsFile.path);
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
        pw.Text(
          'PowerLog',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Electricity Usage Report',
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'User: $username',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Date Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummary(
    double totalKwh,
    double totalCost,
    NumberFormat currency,
  ) {
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
              pw.Text(
                'Total Logged Usage',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                '${totalKwh.toStringAsFixed(2)} kWh',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total Estimated Cost',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                currency.format(totalCost),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
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

  pw.Widget _buildPredictions(
    double daily,
    double monthly,
    double cost,
    NumberFormat currency,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monthly Prediction (Based on Appliances)',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPredictItem('Daily Avg', '${daily.toStringAsFixed(2)} kWh'),
              _buildPredictItem(
                'Monthly Est.',
                '${monthly.toStringAsFixed(2)} kWh',
              ),
              _buildPredictItem(
                'Monthly Cost',
                currency.format(cost),
                isHighlight: true,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '* Monthly prediction assumes appliances are used consistently for 30 days.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildPredictItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight ? PdfColors.blue900 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by PowerLog App',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.Text(
              'Eco-friendly Electricity Management',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.green700),
            ),
          ],
        ),
      ],
    );
  }

  _ReportTotals _calculateReportTotals(
    List<LogModel> logs,
    List<ApplianceModel> appliances,
    double ratePerKwh,
  ) {
    var loggedKwh = logs.fold(0.0, (sum, item) => sum + item.kwhUsage);
    var loggedCost = logs.fold(0.0, (sum, item) => sum + item.estimatedCost);

    if (loggedCost <= 0 && ratePerKwh > 0) {
      final recalculatedCost = logs.fold(
        0.0,
        (sum, item) => sum + (item.kwhUsage * ratePerKwh),
      );
      if (recalculatedCost > 0) {
        loggedCost = recalculatedCost;
      }
    }

    if (loggedKwh <= 0 && loggedCost > 0 && ratePerKwh > 0) {
      loggedKwh = loggedCost / ratePerKwh;
    }

    if (logs.isEmpty && appliances.isNotEmpty) {
      final dailyKwh = appliances.fold(0.0, (sum, item) => sum + item.dailyKwh);
      final monthlyKwh = dailyKwh * 30;
      loggedKwh = monthlyKwh;
      loggedCost = monthlyKwh * ratePerKwh;
    }

    return _ReportTotals(loggedKwh, loggedCost);
  }
}

class _ReportTotals {
  final double loggedKwh;
  final double loggedCost;

  const _ReportTotals(this.loggedKwh, this.loggedCost);
}
