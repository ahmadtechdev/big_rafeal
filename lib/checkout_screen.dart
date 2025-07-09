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
      final String shopAddress = _currentUser?.address ?? '';
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

      // Generate PDF receipt
      _showSnackBar('Generating PDF receipt...');

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
      double vatAmount = widget.price * vatRate ;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 8), // Reduced top spacing

                // Header with logo - Enhanced with monospace font
                companyLogoData != null
                    ? pw.Image(pw.MemoryImage(companyLogoData), width: 120, height: 60)
                    : pw.Text('BIG RAFEAL',
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.SizedBox(height: 6),

                // Website link - Enhanced with monospace font
                pw.Text('https://bigrafeal.info/',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.SizedBox(height: 4),

                // Promotional text - Enhanced with monospace font
                pw.Text('Buy our Products and get a ',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.Text(' free entry to play our game',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.SizedBox(height: 8),

                // Tax Invoice (underlined) - Enhanced with monospace font
                pw.Text('Tax Invoice',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.Container(
                  width: 120,
                  height: 2,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 8),

                // Receipt details - Enhanced with bigger, bolder text and monospace font
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TRN NO: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text(uniqueReceiptId, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Invoice No: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text('${widget.selectedNumbers.length}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Sale Date: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text(purchaseDateTime, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Price: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text('AED $purchasePrice', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('VAT%: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text('5%', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('VAT 5%: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text('AED ${vatAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Inc. Vat: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text('AED ${widget.price}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Ticket Details (underlined) - Enhanced with monospace font
                pw.Text('Ticket Details',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.Container(
                  width: 120,
                  height: 2,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 8),

                // Game details - Enhanced with monospace font
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Game Mode: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text('$lotteryName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Ticket Type: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text(() {
                          String ticketType = '';
                          if (widget.sequence) ticketType += 'Straight ';
                          if (widget.rumble) ticketType += 'Rumble ';
                          if (widget.chance) ticketType += 'Chance ';
                          if (ticketType.isEmpty) ticketType = widget.combinationCode as String;
                          return ticketType.trim();
                        }(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Selected numbers in circles - Enhanced with bigger circles
                ...widget.selectedNumbers.asMap().entries.map((entry) {
                  List<int> numbers = entry.value;
                  return pw.Container(
                    alignment: pw.Alignment.center,
                    margin: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Wrap(
                      alignment: pw.WrapAlignment.center,
                      spacing: 10,
                      children: numbers.map((number) {
                        return pw.Container(
                          width: 26,
                          height: 26,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(width: 2),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            number.toString(),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: pw.Font.courier()),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
                pw.SizedBox(height: 10),

                // Shop Details (underlined) - Enhanced with monospace font
                pw.Text('Point of Sales Details',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.Container(
                  width: 120,
                  height: 2,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 8),

                // Shop information - Enhanced with monospace font
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Vendor Name: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Flexible(
                          child: pw.Text(merchantName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Vendor: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Flexible(
                          child: pw.Text(shopName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Address: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Expanded(
                          child: pw.Text(shopAddress, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // QR code - Enhanced with bigger size
                qrImageData.isNotEmpty
                    ? pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(width: 1, color: PdfColors.black),
                    ),
                    child: pw.Image(pw.MemoryImage(qrImageData))
                )
                    : pw.Container(
                  height: 100,
                  width: 100,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1, color: PdfColors.black),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text('QR CODE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                ),
                pw.SizedBox(height: 8),

                // QR instruction text - Enhanced with monospace font
                pw.Text('To claim your reward scan this ',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.normal, font: pw.Font.courier())),
                pw.Text('QR code at the point of sale where you made purchase',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.normal, font: pw.Font.courier())),
                pw.SizedBox(height: 10),

                // Footer company info - Enhanced with monospace font
                pw.Text('BIG RAFEAL',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.SizedBox(height: 6),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // pw.Row(
                    //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     pw.Text('Address', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                    //     pw.Text(': API World Tower -', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                    //   ],
                    // ),
                    // pw.Row(
                    //   mainAxisAlignment: pw.MainAxisAlignment.end,
                    //   children: [
                    //     pw.Text('Sheikh Zayed Rd.', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                    //   ],
                    // ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Draw Time: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                        pw.Text(drawDateTime, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                      ],
                    ),
                    pw.SizedBox(height: 2),

                  ],
                ),
                pw.SizedBox(height: 8),

                // Final disclaimer - Enhanced with monospace font
                pw.Text('You must redeem your coupon if ',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.Text('there is any winner within 15 days',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                pw.SizedBox(height: 15),
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
