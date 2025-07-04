import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottery_app/utils/custom_snackbar.dart';
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

      CustomSnackBar.success(message, duration: 2);
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
      // final String shopAddress = _currentUser?.address ?? '';
      final String shopAddress = "Address";
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
            uniqueId: uniqueReceiptId,
          );

          if (response['success'] == true) {
            _showSnackBar('Saving lottery ticket ${i+1}/${widget.selectedNumbers.length}');
          } else {
            throw response['message'] ?? 'Failed to save ticket';
          }
        } catch (e) {
          _showSnackBar('Error saving ticket ${i+1}: $e');
          return;
        }
      }

      _showSnackBar('Printing receipt...');

      // Try printing with Sunmi printer first
      bool sunmiPrintSuccess = false;
      try {
        _showSnackBar('Attempting to connect to Sunmi printer...');

        bool isSunmiDevice = false;
        try {
          isSunmiDevice = true;
        } catch (e) {
          _showSnackBar('Not a Sunmi device or printer service unavailable: $e');
          isSunmiDevice = false;
        }

        if (isSunmiDevice) {
          _showSnackBar('Initializing Sunmi printer...');
          await SunmiPrinter.initPrinter();
          await Future.delayed(Duration(milliseconds: 500));

          bool? isConnected = await SunmiPrinter.bindingPrinter();
          _showSnackBar('Sunmi printer binding status: ${isConnected == true ? "Connected" : "Not Connected"}');

          if (isConnected == true) {
            _showSnackBar('Printing single receipt with all numbers...');

            // Print header with logo
            await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
            await SunmiPrinter.printText('BIG RAFEAL', style: SunmiTextStyle(bold: true, fontSize: 32));
            await SunmiPrinter.lineWrap(1);

            // Website link
            await SunmiPrinter.printText('https://bigrafeal.info/', style: SunmiTextStyle(bold: true, fontSize: 14));
            await SunmiPrinter.lineWrap(1);

            // Promotional text
            await SunmiPrinter.printText('Buy our Products and get a free', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('entry to play our game', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.lineWrap(2);

            // Tax Invoice (underlined)
            await SunmiPrinter.printText('Tax Invoice', style: SunmiTextStyle(bold: true, fontSize: 16));
            await SunmiPrinter.printText('________________', style: SunmiTextStyle(bold: true, fontSize: 14));
            await SunmiPrinter.lineWrap(1);

            // Receipt details
            await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
            await SunmiPrinter.printText('TRN NO        : $uniqueReceiptId', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Invoice No    : ${widget.selectedNumbers.length}', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Sale Date     : $purchaseDateTime', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Price         : AED $purchasePrice', style: SunmiTextStyle(bold: true, fontSize: 12));

            // Calculate VAT details
            double totalPrice = double.parse(purchasePrice);
            double vatRate = 0.05; // 5%
            double priceWithoutVat = totalPrice / (1 + vatRate);
            double vatAmount = totalPrice - priceWithoutVat;

            await SunmiPrinter.printText('VAT%          : 5%', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('VAT 5%        : AED ${vatAmount.toStringAsFixed(2)}', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Total Inc. Vat: AED $purchasePrice', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.lineWrap(2);

            // Ticket Details (underlined)
            await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
            await SunmiPrinter.printText('Ticket Details', style: SunmiTextStyle(bold: true, fontSize: 16));
            await SunmiPrinter.printText('________________', style: SunmiTextStyle(bold: true, fontSize: 14));
            await SunmiPrinter.lineWrap(1);

            // Game details
            await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
            await SunmiPrinter.printText('Game Mode     : $lotteryName', style: SunmiTextStyle(bold: true, fontSize: 12));

            // Ticket type based on categories
            String ticketType = '';
            if (widget.sequence) ticketType += 'Straight ';
            if (widget.rumble) ticketType += 'Rumble ';
            if (widget.chance) ticketType += 'Chance ';
            if (ticketType.isEmpty) ticketType = widget.combinationCode as String;

            await SunmiPrinter.printText('Ticket Type   : ${ticketType.trim()}', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.lineWrap(1);

            // Print ALL selected numbers
            await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
            for (int i = 0; i < widget.selectedNumbers.length; i++) {
              final List<int> numbers = widget.selectedNumbers[i];
              String numbersStr = numbers.map((n) => n.toString().padLeft(2, '0')).join('  ');
              await SunmiPrinter.printText(numbersStr, style: SunmiTextStyle(bold: true, fontSize: 24));
              if (i < widget.selectedNumbers.length - 1) {
                await SunmiPrinter.lineWrap(1);
              }
            }
            await SunmiPrinter.lineWrap(2);

            // Shop Details (underlined)
            await SunmiPrinter.printText('Point of Sales Details', style: SunmiTextStyle(bold: true, fontSize: 16));
            await SunmiPrinter.printText('________________', style: SunmiTextStyle(bold: true, fontSize: 14));
            await SunmiPrinter.lineWrap(1);

            // Shop information
            await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
            await SunmiPrinter.printText('Vendor Name   : $merchantName', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Vendor        : $shopName', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Address       : $shopAddress', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.lineWrap(2);

            // QR Code placeholder (since we can't print actual QR with Sunmi easily)
            await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
            await SunmiPrinter.printText('[QR CODE HERE]', style: SunmiTextStyle(bold: true, fontSize: 14));
            await SunmiPrinter.lineWrap(2);

            // QR instruction text (not bold)
            await SunmiPrinter.printText('To claim your reward scan this QR code', style: SunmiTextStyle(bold: false, fontSize: 12));
            await SunmiPrinter.printText('at the point of sale where you made', style: SunmiTextStyle(bold: false, fontSize: 12));
            await SunmiPrinter.printText('purchase', style: SunmiTextStyle(bold: false, fontSize: 12));
            await SunmiPrinter.lineWrap(2);

            // Footer company info
            await SunmiPrinter.printText('BIG RAFEAL', style: SunmiTextStyle(bold: true, fontSize: 16));
            await SunmiPrinter.lineWrap(1);
            await SunmiPrinter.printText('Address       : API World Tower -', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('                Sheikh Zayed Rd.', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Draw Date     : $drawDateTime', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.printText('Draw Time     : 23:30:00', style: SunmiTextStyle(bold: true, fontSize: 12));
            await SunmiPrinter.lineWrap(2);

            await SunmiPrinter.printText('You must redeem your coupon if there is', style: SunmiTextStyle(bold: true, fontSize: 10));
            await SunmiPrinter.printText('any winner within 15 days', style: SunmiTextStyle(bold: true, fontSize: 10));

            await SunmiPrinter.lineWrap(3);
            await SunmiPrinter.cutPaper();

            sunmiPrintSuccess = true;
            _showSnackBar('Sunmi printing completed successfully!');
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

        // Load company logo
        final Uint8List? companyLogoData = await _loadCompanyLogo();

        // Generate QR code with ONLY the unique receipt ID
        final Uint8List qrImageData = await _generateQrCode(uniqueReceiptId);

        // Create PDF document
        final pdf = pw.Document();

        // Calculate VAT details
        double totalPrice = double.parse(purchasePrice);
        double vatRate = 0.05; // 5%
        double priceWithoutVat = totalPrice / (1 + vatRate);
        double vatAmount = totalPrice - priceWithoutVat;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.roll80,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 20),

                  // Header with logo
                  companyLogoData != null
                      ? pw.Image(pw.MemoryImage(companyLogoData), width: 100, height: 50)
                      : pw.Text('BIG RAFEAL',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),

                  // Website link
                  pw.Text('https://bigrafeal.info/',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),

                  // Promotional text
                  pw.Text('Buy our Products and get a free',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('entry to play our game',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),

                  // Tax Invoice (underlined)
                  pw.Text('Tax Invoice',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Container(
                    width: 100,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 8),

                  // Receipt details
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TRN NO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': $uniqueReceiptId', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Invoice No', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': ${widget.selectedNumbers.length}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Sale Date', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': $purchaseDateTime', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': AED $purchasePrice', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('VAT%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': 5%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('VAT 5%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': AED ${vatAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Inc. Vat', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': AED $purchasePrice', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),

                  // Ticket Details (underlined)
                  pw.Text('Ticket Details',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Container(
                    width: 100,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 8),

                  // Game details
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Game Mode', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': $lotteryName', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Ticket Type', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': ${() {
                            String ticketType = '';
                            if (widget.sequence) ticketType += 'Straight ';
                            if (widget.rumble) ticketType += 'Rumble ';
                            if (widget.chance) ticketType += 'Chance ';
                            if (ticketType.isEmpty) ticketType = widget.combinationCode as String;
                            return ticketType.trim();
                          }()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),

                  // Selected numbers in circles
                  ...widget.selectedNumbers.asMap().entries.map((entry) {
                    List<int> numbers = entry.value;
                    return pw.Container(
                      alignment: pw.Alignment.center,
                      margin: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Wrap(
                        alignment: pw.WrapAlignment.center,
                        spacing: 8,
                        children: numbers.map((number) {
                          return pw.Container(
                            width: 20,
                            height: 20,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(width: 1),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              number.toString().padLeft(2, '0'),
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                  pw.SizedBox(height: 12),

                  // Shop Details (underlined)
                  pw.Text('Point of Sales Details',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Container(
                    width: 100,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 8),

                  // Shop information
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Vendor Name', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Flexible(
                            child: pw.Text(': $merchantName', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Vendor', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Flexible(
                            child: pw.Text(': $shopName', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Address', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.Text(': $shopAddress', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),

                  // QR code
                  qrImageData.isNotEmpty
                      ? pw.Container(
                      width: 80,
                      height: 80,
                      color: PdfColors.white,
                      child: pw.Image(pw.MemoryImage(qrImageData))
                  )
                      : pw.Container(height: 80, width: 80),
                  pw.SizedBox(height: 8),

                  // QR instruction text (not bold)
                  pw.Text('To claim your reward scan this QR code',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal)),
                  pw.Text('at the point of sale where you made',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal)),
                  pw.Text('purchase',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal)),
                  pw.SizedBox(height: 12),

                  // Footer company info
                  pw.Text('BIG RAFEAL',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Address', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': API World Tower -', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Sheikh Zayed Rd.', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Draw Date', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': $drawDateTime', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Draw Time', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text(': 23:30:00', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  pw.Text('You must redeem your coupon if there is',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('any winner within 15 days',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                ],
              );
            },
          ),
        );

        // Print the PDF document
        _showSnackBar('Printing PDF document...');
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'BIG_RAFEAL_Receipt.pdf',
          format: PdfPageFormat.roll80,
        );
      }

      _showSnackBar('Receipt processed successfully');

      // Navigate to home screen after printing
      if (mounted && widget.selectedNumbers.isNotEmpty) {
        Get.offAll(() => AnimatedHomeScreen());
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
