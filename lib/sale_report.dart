
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
import 'controllers/sale_report_controller.dart';

class SalesReportScreen extends StatelessWidget {
  final SalesReportController _reportController = Get.put(
    SalesReportController(),
  );

  // ignore: use_super_parameters
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

  List<String> _generateDays(int year, int month) {
    // Calculate the number of days in the selected month and year
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(daysInMonth, (index) => (index + 1).toString());
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

    // Generate days based on the current month and year
    final daysList = _generateDays(currentDate.year, currentDate.month);

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
                    _reportController.loadReport();
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
                    _reportController.loadReport();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildDropdownButton(
                label: 'Day',
                items: daysList,
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
                    _reportController.loadReport();
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


  Widget _buildSaleItem(UserLottery userLottery, int index) {
    final status = userLottery.wOrL.toUpperCase(); // "WIN", "LOSS", or "PENDING"
    final isWin = userLottery.wOrL.contains('WIN');
    final isLoss = userLottery.wOrL.contains('LOSS');

    // final statusColor = switch (status) {
    //   'WIN' => Colors.green,
    //   'LOSS' => Colors.red,
    //   _ => Colors.orange,
    // };

    // final statusIcon = switch (status) {
    //   'WIN' => Icons.emoji_events,
    //   'LOSS' => Icons.cancel,
    //   _ => Icons.access_time,
    // };

    // final statusText = switch (status) {
    //   'WIN' => 'WIN',
    //   'LOSS' => 'LOSS',
    //   _ => 'PENDING',
    // };

    final statusIcon = isWin
        ? Icons.emoji_events
        : isLoss
        ? Icons.cancel
        : Icons.access_time;
    final statusColor = isWin
        ? Colors.green
        : isLoss
        ? Colors.red
        : Colors.orange;

    final statusText = isWin
        ? userLottery.wOrL
        : isLoss
        ? 'LOSS'
        : 'PENDING';

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
                // Title Row
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
                                  'ID: ${userLottery.order_id}',
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
                      value: _formatDate(DateTime.parse(userLottery.lotteryIssueDate)),
                      icon: Icons.event,
                    ),
                    _buildInfoItem(
                      title: 'Price',
                      value: 'AED ${userLottery.purchasePrice}',
                      icon: Icons.shopping_cart,
                    ),
                    _buildInfoItem(
                      title: status == 'PENDING' ? 'Status' : 'Winning',
                      value: status == 'PENDING'
                          ? 'Pending'
                          : 'AED ${userLottery.winAmount}',
                      icon: status == 'PENDING'
                          ? Icons.hourglass_empty
                          : Icons.monetization_on,
                      valueColor: status == 'WIN'
                          ? Colors.green
                          : status == 'LOSS'
                          ? Colors.red
                          : null,
                      isBold: true,
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
                _reportController.loadReport();
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

  // Load company logo image
  Future<Uint8List?> _loadCompanyLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo2.png');
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _printReport() async {
    try {
      // Generate common data
      // Get user details
      final userController = Get.put(UserController());
      final userName = userController.currentUser.value?.name ?? 'Merchant';
      final shopName = userController.currentUser.value?.shopName ?? 'Shop';

      // Load logos
      final Uint8List? companyLogoData = await _loadCompanyLogo();

      // Create a single PDF document for all receipts
      final pdf = pw.Document();

      // Add receipt page to the document
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 30),
                // Header with logo - increased size
                companyLogoData != null
                    ? pw.Image(
                      pw.MemoryImage(companyLogoData),
                      width: 100,
                      height: 50,
                    )
                    : pw.Text(
                      'BIG RAFEAL',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                pw.SizedBox(height: 4),

                // SALES REPORT (smaller font)
                pw.Text(
                  'SALES REPORT',
                  style: pw.TextStyle(
                    fontSize: 14, // Reduced from 16
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 3),

                // Date range (smaller font)
                pw.Text(
                  '${_formatDate(_reportController.startDate.value)} to ${_formatDate(_reportController.endDate.value)}',
                  style: const pw.TextStyle(fontSize: 10), // Reduced from 12
                  textAlign: pw.TextAlign.center,
                ),

                pw.Divider(thickness: 1),

                // Thinner divide
                pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 12, // Reduced from 14
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Tickets:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "${_reportController.filteredLotteries.length}",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Winning Tickets:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${_reportController.filteredLotteries.where((l) => l.wOrL == 'WIN').length}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Sales:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "AED ${_reportController.totalSales.value.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Winnings:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "AED ${_reportController.totalWinnings.value.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Net Sales:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "AED ${(_reportController.totalSales.value - _reportController.totalWinnings.value).toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Agent Commission:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "AED ${_reportController.userCommission.value.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Payable to Admin:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "AED ${_reportController.payableToAdmin.value.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Product details
                pw.SizedBox(height: 7),
                pw.Text(
                  'MERCHANT DETAILS',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 3),

                // Ticket details - improved with bolder text
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Merchant Name:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      userName,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Shop Name:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Flexible(
                      child: pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      shopName,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                // Divider and jackpot info
                pw.Divider(thickness: 1),

                // Footer with company details
                pw.Text(
                  'BIG RAFEAL L.L.C',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Agent Commission:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'For more information,',
                  style: pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  'visit www.bigrafeal.info',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                // pw.Text('or Call us @ 0554691351',
                //     style: pw.TextStyle(fontSize: 8)),
                pw.Text(
                  'info@bigrafeal.info',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '---- Thank You ----',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                // Add cut line between receipts if not the last receipt
                pw.Column(
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '--------------------------------',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Print entire document once
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'BIG_RAFEAL_Tickets_sale.pdf',
        format: PdfPageFormat.roll80,
      );

      Get.back();
    } catch (e) {
      // _showSnackBar('Error printing receipts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user details
    final userController = Get.find<UserController>();
    final userName = userController.currentUser.value?.name ?? 'Merchant';
    final shopName = userController.currentUser.value?.shopName ?? 'Shop';
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 22, color: AppColors.backgroundColor),
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
                  onPressed: () => _reportController.loadReport(),
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
              _reportController.loadReport();
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
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.1),
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
                              Icon(
                                Icons.person_outline,
                                size: 24,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Merchant Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Name: $userName',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Shop: $shopName',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                            Text(
                              '${_reportController.filteredLotteries.length} Tickets',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
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
                                        title: 'Commission',
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
