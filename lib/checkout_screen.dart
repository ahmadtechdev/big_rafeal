import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/core/styles/sunmi_text_style.dart';
import 'package:sunmi_printer_plus/core/sunmi/sunmi_printer.dart';
import 'api_service/api_service.dart';
import 'dashboard.dart';
import 'home_screen_1.dart';
import 'utils/app_colors.dart';
import 'ticket_details_screen.dart';
import 'controllers/user_controller.dart';
import 'controllers/lottery_controller.dart';
import 'models/lottery_model.dart';
import 'models/user_model.dart';

class CheckoutScreen extends StatefulWidget {
  final List<List<int>> selectedNumbers;
  final double price;
  final int lotteryId;
  final int combinationCode;
  final bool sequence;
  final bool rumble;
  final bool chance;

  const CheckoutScreen({
    super.key,
    required this.selectedNumbers,
    required this.price,
    required this.lotteryId,
    required this.combinationCode,
    required this.sequence,
    required this.rumble,
    required this.chance,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPrinting = false;

  // Get controllers
  final UserController _userController = Get.find<UserController>();
  final LotteryController _lotteryController = Get.find<LotteryController>();

  // Get lottery data based on lotteryId
  Lottery? get _currentLottery {
    try {
      return _lotteryController.lotteries.firstWhere((lottery) => lottery.id == widget.lotteryId);
    } catch (e) {
      return null;
    }
  }

  // Get user data
  User? get _currentUser => _userController.currentUser.value;

  PrinterStatus statusPrinter = PrinterStatus.UNKNOWN;
  String _getCurrentDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _getDrawDateTime() {
    // If lottery has endDate, use it, otherwise fallback to dummy data
    if (_currentLottery != null) {
      try {
        final drawDate = _currentLottery!.endDate;
        return '${drawDate.day.toString().padLeft(2, '0')}.${drawDate.month.toString().padLeft(2, '0')}.${drawDate.year} ${drawDate.hour.toString().padLeft(2, '0')}:${drawDate.minute.toString().padLeft(2, '0')} ${drawDate.hour >= 12 ? 'PM' : 'AM'}';
      // ignore: empty_catches
      } catch (e) {
      }
    }

    // Fallback to dummy data
    final drawTime = DateTime.now().add(const Duration(hours: 7));
    return '${drawTime.day.toString().padLeft(2, '0')}.${drawTime.month.toString().padLeft(2, '0')}.${drawTime.year} ${drawTime.hour.toString().padLeft(2, '0')}:${drawTime.minute.toString().padLeft(2, '0')} ${drawTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }
  Future<Uint8List> _generateQrCode(String uniqueReceiptId) async {
    try {
      // QR data contains only the unique receipt ID
      final qrData = {
        'receipt_id': uniqueReceiptId,
      };

      final qrValidationResult = QrValidator.validate(
        data: jsonEncode(qrData),
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception('QR code validation failed');
      }

      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );

      final qrImageSize = 250.0;
      final pictureRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(pictureRecorder);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, qrImageSize, qrImageSize),
        Paint()..color = Colors.white,
      );

      final qrPaintSize = qrImageSize * 0.8;
      final qrOffset = qrImageSize * 0.1;

      canvas.save();
      canvas.translate(qrOffset, qrOffset);
      painter.paint(canvas, Size(qrPaintSize, qrPaintSize));
      canvas.restore();

      final picture = pictureRecorder.endRecording();
      final img = await picture.toImage(qrImageSize.toInt(), qrImageSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      return Uint8List.fromList([]);
    }
  }
  // Load pencil logo image
  Future<Uint8List?> _loadPencilLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/pencil.png');
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
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


// Updated helper function to generate unique ID per receipt
  String generateUniqueReceiptId() {
    final String userId = _currentUser?.id.toString() ?? 'ID';
    final String userName = _currentUser?.name ?? 'USER';
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_${userName}_$timestamp';
  }

  Future<void> _printReceipts() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final String purchaseDateTime = _getCurrentDateTime();
      final String drawDateTime = _getDrawDateTime();
      final String lotteryName = _currentLottery?.lotteryName ?? 'Lot Name';
      final String winningPrice = _currentLottery?.maxReward.toString() ?? '000';
      final String purchasePrice = _currentLottery?.purchasePrice ?? '0';
      final String merchantName = _currentUser?.name ?? '';
      final String shopName = _currentUser?.shopName ?? '';
      final String lotteryNumbers = _currentLottery?.numberLottery.toString() ?? '';

      final User? user = _currentUser;
      if (user == null) {
        _showSnackBar('User information not available');
        return;
      }

      // Generate ONE unique ID for this receipt
      final String uniqueReceiptId = generateUniqueReceiptId();
      print(":ahmad");
      print(uniqueReceiptId);

      final ApiService apiService = ApiService();

      // Save all tickets to the API with the SAME unique ID
      for (int i = 0; i < widget.selectedNumbers.length; i++) {
        final List<int> numbers = widget.selectedNumbers[i];
        final String selectedNumbersStr = numbers.join(',');

        try {
          final response = await apiService.saveLotterySale(
            userId: user.id,
            lotteryId: widget.lotteryId,
            selectedNumbers: selectedNumbersStr,
            purchasePrice: widget.price,
            category: widget.combinationCode,
            uniqueId: uniqueReceiptId, // Send the same unique ID for all rows
          );

          if (response['success'] == true) {
            _showSnackBar('Saving lottery ticket ${i+1}/${widget.selectedNumbers.length}');
          } else {
            throw response['message'] ?? 'Failed to save ticket';
          }
        } catch (e) {
          _showSnackBar('Error saving ticket ${i+1}: $e');
          return; // Don't proceed with printing if saving fails
        }
      }

      _showSnackBar('Printing receipt...');

      // Try printing with Sunmi printer first
      bool sunmiPrintSuccess = false;
      try {
        _showSnackBar('Attempting to connect to Sunmi printer...');

        // Check if running on Sunmi device first
        bool isSunmiDevice = false;
        try {
          isSunmiDevice = true;
        } catch (e) {
          _showSnackBar('Not a Sunmi device or printer service unavailable: $e');
          isSunmiDevice = false;
        }

        if (isSunmiDevice) {
          // Initialize printer first
          _showSnackBar('Initializing Sunmi printer...');
          await SunmiPrinter.initPrinter();

          // Small delay to ensure initialization
          await Future.delayed(Duration(milliseconds: 500));

          // Check printer binding status
          bool? isConnected = await SunmiPrinter.bindingPrinter();
          _showSnackBar('Sunmi printer binding status: ${isConnected == true ? "Connected" : "Not Connected"}');

          if (isConnected == true) {
            if (true) { // Printer is normal
              // Print ONE receipt with ALL selected numbers
              _showSnackBar('Printing single receipt with all numbers...');

              // Print header
              await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
              await SunmiPrinter.printText('BIG RAFEAL', style: SunmiTextStyle(bold: true, fontSize: 32));
              await SunmiPrinter.lineWrap(1);

              // Print categories
              String categories = '';
              if (widget.sequence) categories += 'SEQUENCE ';
              if (widget.rumble) categories += 'RUMBLE ';
              if (widget.chance) categories += 'CHANCE ';
              if (categories.isNotEmpty) {
                await SunmiPrinter.printText(categories.trim(), style: SunmiTextStyle(bold: true, fontSize: 18));
                await SunmiPrinter.lineWrap(1);
              }

              // Print details
              await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
              await SunmiPrinter.printText('Price (inc. VAT 5%): AED $purchasePrice', style: SunmiTextStyle(bold: true, fontSize: 14));
              await SunmiPrinter.printText('Purchased: $purchaseDateTime', style: SunmiTextStyle(bold: true, fontSize: 14));
              await SunmiPrinter.printText('Product: $lotteryNumbers x $lotteryName', style: SunmiTextStyle(bold: true, fontSize: 14));

              // Print ALL numbers row by row
              await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
              await SunmiPrinter.lineWrap(1);

              for (int i = 0; i < widget.selectedNumbers.length; i++) {
                final List<int> numbers = widget.selectedNumbers[i];
                String numbersStr = numbers.map((n) => n.toString().padLeft(2, '0')).join('  ');
                await SunmiPrinter.printText(numbersStr, style: SunmiTextStyle(bold: true, fontSize: 24));
                if (i < widget.selectedNumbers.length - 1) {
                  await SunmiPrinter.lineWrap(1);
                }
              }
              await SunmiPrinter.lineWrap(1);

              // Print receipt info (using unique receipt ID)
              await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
              await SunmiPrinter.printText('Receipt ID: $uniqueReceiptId', style: SunmiTextStyle(bold: true, fontSize: 14));
              await SunmiPrinter.printText('Merchant: $merchantName', style: SunmiTextStyle(bold: true, fontSize: 14));
              await SunmiPrinter.printText('Shop: $shopName', style: SunmiTextStyle(bold: true, fontSize: 14));
              await SunmiPrinter.printText('Draw Date: $drawDateTime', style: SunmiTextStyle(bold: true, fontSize: 14));

              // Print footer
              await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
              await SunmiPrinter.printText('----------------------------', style: SunmiTextStyle(fontSize: 16));
              await SunmiPrinter.printText('GRAND JACKPOT $winningPrice AED', style: SunmiTextStyle(bold: true, fontSize: 18));
              await SunmiPrinter.printText('----------------------------', style: SunmiTextStyle(fontSize: 16));
              await SunmiPrinter.printText('BIG RAFEAL L.L.C', style: SunmiTextStyle(bold: true, fontSize: 16));
              await SunmiPrinter.printText('www.bigrafeal.info', style: SunmiTextStyle(fontSize: 14));
              await SunmiPrinter.printText('info@bigrafeal.info', style: SunmiTextStyle(fontSize: 14));
              await SunmiPrinter.printText('---- Thank You ----', style: SunmiTextStyle(bold: true, fontSize: 16));

              await SunmiPrinter.lineWrap(3);

              // Feed paper and cut
              _showSnackBar('Finalizing print job...');
              await SunmiPrinter.cutPaper();

              sunmiPrintSuccess = true;
              _showSnackBar('Sunmi printing completed successfully!');
            }
          } else {
            _showSnackBar('Sunmi printer binding failed. Will fall back to PDF printing.');
            throw Exception('Printer binding failed');
          }
        } else {
          _showSnackBar('Not running on Sunmi device. Will fall back to PDF printing.');
          throw Exception('Not a Sunmi device');
        }
      } catch (e) {
        _showSnackBar('Sunmi printer error: $e');
        sunmiPrintSuccess = false;
        print('Sunmi printer debug error: $e');
      }

      // If Sunmi printing failed, fall back to PDF printing
      if (!sunmiPrintSuccess) {
        _showSnackBar('Falling back to PDF printing...');

        // Load logos
        final Uint8List? companyLogoData = await _loadCompanyLogo();
        final Uint8List? pencilLogoData = await _loadPencilLogo();

        // Generate QR code with ONLY the unique receipt ID
        final Uint8List qrImageData = await _generateQrCode(uniqueReceiptId);

        // Create PDF document with ONE page for all numbers
        final pdf = pw.Document();
        final String product = '$lotteryNumbers x $lotteryName';

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.roll80,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 30),
                  // Header with logo
                  companyLogoData != null
                      ? pw.Image(pw.MemoryImage(companyLogoData), width: 100, height: 50)
                      : pw.Text('BIG RAFEAL',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),

                  // Add selected categories
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (widget.sequence)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(right: 8),
                          child: pw.Text('SEQUENCE ',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                      if (widget.rumble)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(right: 8),
                          child: pw.Text('RUMBLE ',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                      if (widget.chance)
                        pw.Text('CHANCE ',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Price (inc. VAT 5%):',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('AED $purchasePrice',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Purchased:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(purchaseDateTime,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Product:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(product,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),

                  // Product details
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Product pencil:',
                          style: pw.TextStyle(fontSize: 9)),
                      pw.Text('${int.parse(purchasePrice)/5} x 3.5 AED',
                          style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Tax:',
                          style: pw.TextStyle(fontSize: 9)),
                      pw.Text('1.5 AED',
                          style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),

                  pw.SizedBox(height: 10),
                  // Pencil logo
                  pencilLogoData != null
                      ? pw.Image(pw.MemoryImage(pencilLogoData), width: 50, height: 50)
                      : pw.SizedBox(),
                  pw.SizedBox(height: 10),

                  // ALL Selected numbers in rows
                  ...widget.selectedNumbers.asMap().entries.map((entry) {
                    int index = entry.key;
                    List<int> numbers = entry.value;

                    return pw.Column(
                      children: [
                        // pw.Text('Row ${index + 1}',
                        //     style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        // pw.SizedBox(height: 4),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          margin: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Wrap(
                            alignment: pw.WrapAlignment.center,
                            spacing: 8,
                            children: numbers.map((number) {
                              return pw.Container(
                                width: 20,
                                height: 20,
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(width: 0.8),
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  number.toString().padLeft(2, '0'),
                                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                      ],
                    );
                  }),

                  // Receipt details (using unique receipt ID)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Receipt ID:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(uniqueReceiptId,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Merchant Name:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Flexible(
                        child: pw.Text(merchantName,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(shopName,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Draw Date:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(drawDateTime,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),

                  // Divider and jackpot info
                  pw.Divider(thickness: 1),
                  pw.Text(lotteryName,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('GRAND JACKPOT $winningPrice AED',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(thickness: 1),

                  // QR code with unique receipt ID
                  qrImageData.isNotEmpty
                      ? pw.Container(
                      width: 100,
                      height: 100,
                      color: PdfColors.white,
                      child: pw.Image(pw.MemoryImage(qrImageData))
                  )
                      : pw.Container(height: 100, width: 100),

                  // Footer
                  pw.Text('BIG RAFEAL L.L.C',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('For more information,',
                      style: pw.TextStyle(fontSize: 8)),
                  pw.Text('visit www.bigrafeal.info',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('info@bigrafeal.info',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text('---- Thank You ----',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                ],
              );
            },
          ),
        );

        // Print the single document
        _showSnackBar('Printing PDF document...');
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'BIG_RAFEAL_Receipt.pdf',
          format: PdfPageFormat.roll80,
        );
      }

      _showSnackBar('Receipt processed successfully');

      // Navigate to ticket details screen after printing
      if (mounted && widget.selectedNumbers.isNotEmpty) {
        final Object lotteryCode = _currentLottery?.id ?? '';

        Get.offAll(
              () => TicketDetailsScreen(
            selectedNumbersRows: widget.selectedNumbers,
            price: widget.price,
            ticketId: uniqueReceiptId, // Use the unique receipt ID
            purchaseDateTime: _getCurrentDateTime(),
            product: '${widget.selectedNumbers.length} x ${_currentLottery?.lotteryName ?? 'GRAND 6'}',
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error processing receipt: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

// Helper method to get printer status message
  String _getPrinterStatusMessage(int status) {
    switch (status) {
      case 0:
        return "Printer is normal";
      case 1:
        return "Printer is out of paper";
      case 2:
        return "Printer is overheating";
      case 3:
        return "Printer is busy";
      case 4:
        return "Printer cover is open";
      case 5:
        return "Printer cutter error";
      case 6:
        return "Printer cutter recovery error";
      case 7:
        return "Printer is not detected";
      case 8:
        return "Printer firmware upgrade error";
      case 9:
        return "Unknown error";
      default:
        return "Unknown status: $status";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCheckoutTitle(),
                  _buildAllTickets(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                ],
              ),
            ),
          ),
          _buildCheckoutButton(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 12),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          const Spacer(),
          SizedBox(
            height: 40,
            width: 120, // Increased width for logo
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'BIG RAFEAL',
                    style: TextStyle(
                      color: Color(0xFFD71921),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCheckoutTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.primaryColor,
      child: const Center(
        child: Text(
          'CHECKOUT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildAllTickets() {
    return Column(
      children: List.generate(
        widget.selectedNumbers.length,
            (index) => _buildTicketDetails(widget.selectedNumbers[index], index + 1),
      ),
    );
  }

  Widget _buildTicketDetails(List<int> numbers, int rowNumber) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Row $rowNumber: ',
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: numbers.map((number) {
                  return Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryColor),
                    ),
                    child: Center(
                      child: Text(
                        number.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () {
              // Handle delete action - you may want to implement this
              setState(() {
                if (widget.selectedNumbers.length > 1) {
                  // Create a new list to avoid modifying the original
                  final List<List<int>> updatedList = List.from(widget.selectedNumbers);
                  updatedList.removeAt(rowNumber - 1);

                  // You'll need to update the parent state if implementing this
                  // For now, just showing a message
                  _showSnackBar('Row $rowNumber removed');
                } else {
                  _showSnackBar('Cannot remove the last row');
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: AppColors.primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Price',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'AED ${widget.price.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Cancel button
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isPrinting ? null : _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Checkout button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPrinting ? null : _printReceipts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isPrinting
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'PRINTING...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                      : const Text(
                    'CHECKOUT & PRINT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final User? user = _currentUser;
      if (user == null) {
        _showSnackBar('User information not available');
        return;
      }

      // Generate unique ID for this order (even though it's cancelled)
      final String uniqueReceiptId = generateUniqueReceiptId();

      final ApiService apiService = ApiService();

      // Save all tickets to the API with cancel=1
      for (int i = 0; i < widget.selectedNumbers.length; i++) {
        final List<int> numbers = widget.selectedNumbers[i];
        final String selectedNumbersStr = numbers.join(',');

        try {
          final response = await apiService.saveLotterySale(
            userId: user.id,
            lotteryId: widget.lotteryId,
            selectedNumbers: selectedNumbersStr,
            purchasePrice: widget.price,
            category: widget.combinationCode,
            uniqueId: uniqueReceiptId,
            cancel: 1, // Add this parameter to indicate cancellation
          );

          if (response['success'] == true) {
            _showSnackBar('Cancelling lottery ticket ${i+1}/${widget.selectedNumbers.length}');
          } else {
            throw response['message'] ?? 'Failed to cancel ticket';
          }
        } catch (e) {
          _showSnackBar('Error cancelling ticket ${i+1}: $e');
          return;
        }
      }

      _showSnackBar('Order cancelled successfully');

      // Navigate back to home
      Get.offAll(()=> AnimatedHomeScreen());

    } catch (e) {
      _showSnackBar('Error cancelling order: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }


}
