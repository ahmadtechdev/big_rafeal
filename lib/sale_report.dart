import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/user_controller.dart';
import '../models/user_lottery_modal.dart';
import '../utils/app_colors.dart';
import 'api_service/api_service.dart';
import 'controllers/lottery_controller.dart';
import 'controllers/sale_report_controller.dart';
import 'models/lottery_model.dart';

class SalesReportScreen extends StatelessWidget {
  final SalesReportController _reportController = Get.put(
    SalesReportController(),
  );

  SalesReportScreen({Key? key}) : super(key: key);

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Generate list of years (current year and previous 5 years)
  List<int> _generateYears() {
    final currentYear = DateTime.now().year;
    return List.generate(6, (index) => currentYear - index);
  }

  // Generate list of months
  List<String> _generateMonths() {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
  }

  // Generate list of days (1-30)
  List<String> _generateDays() {
    return List.generate(30, (index) => (index + 1).toString());
  }

  // Convert month name to month number (1-12)
  int _monthNameToNumber(String monthName) {
    return _generateMonths().indexOf(monthName) + 1;
  }

  Widget _buildDropdownButton({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.inputFieldBackground,
          borderRadius: BorderRadius.circular(10),
          items:
              items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 14, color: AppColors.textDark),
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateSelectorRow(String title, bool isStartDate) {
    final currentDate =
        isStartDate
            ? _reportController.startDate.value
            : _reportController.endDate.value;

    final currentYear = currentDate.year.toString();
    final currentMonth = _generateMonths()[currentDate.month - 1];
    final currentDay = currentDate.day.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                isStartDate ? Icons.calendar_today : Icons.calendar_month,
                size: 18,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdownButton(
                label: 'Year',
                items: _generateYears().map((year) => year.toString()).toList(),
                value: currentYear,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final year = int.parse(newValue);
                    if (isStartDate) {
                      _reportController.startDate.value = DateTime(
                        year,
                        currentDate.month,
                        currentDate.day,
                      );
                    } else {
                      _reportController.endDate.value = DateTime(
                        year,
                        currentDate.month,
                        currentDate.day,
                      );
                    }
                    _reportController.loadLotteries();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildDropdownButton(
                label: 'Month',
                items: _generateMonths(),
                value: currentMonth,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final month = _monthNameToNumber(newValue);
                    if (isStartDate) {
                      _reportController.startDate.value = DateTime(
                        currentDate.year,
                        month,
                        currentDate.day,
                      );
                    } else {
                      _reportController.endDate.value = DateTime(
                        currentDate.year,
                        month,
                        currentDate.day,
                      );
                    }
                    _reportController.loadLotteries();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildDropdownButton(
                label: 'Day',
                items: _generateDays(),
                value: currentDay,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final day = int.parse(newValue);
                    if (isStartDate) {
                      _reportController.startDate.value = DateTime(
                        currentDate.year,
                        currentDate.month,
                        day,
                      );
                    } else {
                      _reportController.endDate.value = DateTime(
                        currentDate.year,
                        currentDate.month,
                        day,
                      );
                    }
                    _reportController.loadLotteries();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Add this helper method to your class for the summary items
  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: valueColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: double.tryParse(value) ?? 0,
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  return Text(
                    'AED ${animValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color valueColor,
    IconData icon,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.inputFieldBackground.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: double.tryParse(value) ?? 0,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      'AED ${value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleItem(UserLottery userLottery, int index) {
    // Find corresponding lottery by properly matching IDs
    final lottery = _reportController.findMatchingLottery(userLottery);
    // Calculate winning amount
    double winningAmount = 0;
    bool resultsAvailable = false;

    if (lottery.endDate.isNotEmpty) {
      final endDate = DateTime.tryParse(lottery.endDate);
      if (endDate != null && DateTime.now().isAfter(endDate)) {
        resultsAvailable = true;
        winningAmount = _reportController.calculateWinningAmount(
          userLottery,
          lottery,
        );
      }
    }

    final isWin = winningAmount > 0;
    final statusColor =
        isWin ? Colors.green : (resultsAvailable ? Colors.red : Colors.orange);
    final statusText = isWin ? 'WIN' : (resultsAvailable ? 'LOSS' : 'PENDING');
    final statusIcon =
        isWin
            ? Icons.emoji_events
            : (resultsAvailable ? Icons.cancel : Icons.access_time);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        shadowColor: AppColors.primaryColor.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.inputFieldBackground.withOpacity(0.2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.confirmation_number,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userLottery.lotteryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${userLottery.ticketId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.dividerColor, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      title: 'Date',
                      value: _formatDate(
                        DateTime.parse(userLottery.lotteryIssueDate),
                      ),
                      icon: Icons.event,
                    ),
                    _buildInfoItem(
                      title: 'Price',
                      value: 'AED ${userLottery.purchasePrice}',
                      icon: Icons.shopping_cart,
                    ),
                    if (resultsAvailable)
                      _buildInfoItem(
                        title: 'Winning',
                        value: 'AED ${winningAmount.toStringAsFixed(2)}',
                        icon: Icons.monetization_on,
                        valueColor: isWin ? Colors.green : Colors.red,
                        isBold: true,
                      ),
                    if (!resultsAvailable)
                      _buildInfoItem(
                        title: 'Status',
                        value: 'Pending',
                        icon: Icons.hourglass_empty,
                        valueColor: Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textGrey),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor ?? AppColors.textDark,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No sales in selected date range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different date range',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _reportController.startDate.value = DateTime.now().subtract(
                  const Duration(days: 30),
                );
                _reportController.endDate.value = DateTime.now();
                _reportController.loadLotteries();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('View Last 30 Days'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Load company logo from assets
    final logo = await rootBundle.load('assets/logo2.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header with large logo
              pw.Container(
                alignment: pw.Alignment.center,
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Image(logoImage, width: 150, height: 80),
              ),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'SALES REPORT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 5),
              pw.Text(
                '${_formatDate(_reportController.startDate.value)} to ${_formatDate(_reportController.endDate.value)}',
                style: const pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),

              pw.Divider(thickness: 2, color: PdfColors.black),
              pw.SizedBox(height: 10),

              // Summary section with improved styling
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Summary items with better layout
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildPdfSummaryRow(
                    'Total Tickets:',
                    '${_reportController.filteredLotteries.length}',
                  ),
                  _buildPdfSummaryRow(
                    'Winning Tickets:',
                    '${_reportController.filteredLotteries.where((l) {
                      final lottery = _reportController.findMatchingLottery(l);
                      return _reportController.calculateWinningAmount(l, lottery) > 0;
                    }).length}',
                  ),
                  _buildPdfSummaryRow(
                    'Total Sales:',
                    'AED ${_reportController.totalSales.value.toStringAsFixed(2)}',
                  ),
                  _buildPdfSummaryRow(
                    'Total Winnings:',
                    'AED ${_reportController.totalWinnings.value.toStringAsFixed(2)}',
                  ),
                  _buildPdfSummaryRow(
                    'Net Sales:',
                    'AED ${(_reportController.totalSales.value - _reportController.totalWinnings.value).toStringAsFixed(2)}',
                  ),
                  _buildPdfSummaryRow(
                    'Agent Commission (25%):',
                    'AED ${_reportController.userCommission.value.toStringAsFixed(2)}',
                  ),
                  _buildPdfSummaryRow(
                    'Payable to Admin:',
                    'AED ${_reportController.payableToAdmin.value.toStringAsFixed(2)}',
                  ),
                ],
              ),

              pw.SizedBox(height: 15),


              // Footer with company details
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'BIG RAFEAL L.L.C',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Agent Commission Percentage: 25%',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'For more information, visit www.bigrafeal.info',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Email: info@bigrafeal.info',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Printed on: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                '---- Thank You For Your Business ----',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // Helper method for PDF summary rows with improved styling
  pw.TableRow _buildPdfSummaryRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Print function
  Future<void> _printReport() async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => _generatePdf(format),
          name: 'BIG_RAFEAL_Tickets_sale.pdf',
          format: PdfPageFormat.roll80
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to print: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 22, color: AppColors.backgroundColor,),
            SizedBox(width: 8),
            Text(
              'Sales Report',
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            color: AppColors.backgroundColor,
            icon: Icon(Icons.print),
            onPressed: _printReport,
            tooltip: 'Print Report',
          ),
        ],
      ),
      body: Obx(() {
        if (_reportController.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Sales Data...',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else if (_reportController.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${_reportController.errorMessage.value}',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _reportController.loadLotteries(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        } else {
          return RefreshIndicator(
            onRefresh: () async {
              _reportController.loadLotteries();
            },
            color: AppColors.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range selector - now inside the scrollable area
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.date_range,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Select Date Range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            _buildDateSelectorRow('From Date', true),
                            const SizedBox(height: 20),
                            _buildDateSelectorRow('To Date', false),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Summary section
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 18,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              AppColors.inputFieldBackground.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.assessment,
                                    size: 24,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sales Performance Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Summary data
                            Column(
                              children: [
                                // Row 1: Sales & Winnings
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        title: 'Total Sales',
                                        value: _reportController
                                            .totalSales
                                            .value
                                            .toStringAsFixed(2),
                                        valueColor: AppColors.primaryColor,
                                        icon: Icons.shopping_cart,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        title: 'Total Winnings',
                                        value: _reportController
                                            .totalWinnings
                                            .value
                                            .toStringAsFixed(2),
                                        valueColor: Colors.red,
                                        icon: Icons.monetization_on,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                const Divider(
                                  height: 1,
                                  color: AppColors.dividerColor,
                                ),
                                const SizedBox(height: 16),

                                // Row 2: Commission & Payable to Admin
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        title: 'Commission (25%)',
                                        value: _reportController
                                            .userCommission
                                            .value
                                            .toStringAsFixed(2),
                                        valueColor: Colors.green,
                                        icon: Icons.payments,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        title: 'Payable to Admin',
                                        value: _reportController
                                            .payableToAdmin
                                            .value
                                            .toStringAsFixed(2),
                                        valueColor: Colors.blue,
                                        icon: Icons.account_balance,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (_reportController.filteredLotteries.isEmpty)
                    _buildEmptyState()
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 18,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sales History',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_reportController.filteredLotteries.length}',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reportController.filteredLotteries.length,
                          itemBuilder: (context, index) {
                            final lottery =
                                _reportController.filteredLotteries[index];
                            return _buildSaleItem(lottery, index);
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
      }),
    );
  }
}
