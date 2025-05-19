import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'api_service/api_service.dart';
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
  Future<Uint8List> _generateQrCode(String ticketId) async {
    try {
      // Simplify the QR data to just the ticket ID
      final qrData = {
        'ticket_id': ticketId,
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


  String generateUniqueTicketId() {
    // Get current timestamp in milliseconds
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    // Convert to string and take last 6-8 digits
    String ticketId = timestamp.toString().substring(
        timestamp.toString().length - 8,
        timestamp.toString().length - 2
    );

    return ticketId;
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

      final ApiService apiService = ApiService();
      List<String> ticketIds = [];

      for (int i = 0; i < widget.selectedNumbers.length; i++) {
        final List<int> numbers = widget.selectedNumbers[i];
        final String selectedNumbersStr = numbers.join(',');

        try {
          // Call the updated API with required fields
          final response = await apiService.saveLotterySale(
            userId: user.id,
            lotteryId: widget.lotteryId,
            selectedNumbers: selectedNumbersStr,
            purchasePrice: widget.price,
            category: widget.combinationCode,
          );

          if (response['success'] == true) {
            // Get the ticket ID from the response
            final ticketId = response['ticket']['id'].toString();
            ticketIds.add(ticketId);
            _showSnackBar('Saving lottery ticket ${i+1}/${widget.selectedNumbers.length}');

            // Rest of your printing logic...
            // Make sure to use the ticketId from response for the receipt
          } else {
            throw response['message'] ?? 'Failed to save ticket';
          }
        } catch (e) {
          _showSnackBar('Error saving ticket ${i+1}: $e');
        }
      }


      _showSnackBar('Printing receipts...');

      // Load logos
      final Uint8List? companyLogoData = await _loadCompanyLogo();
      final Uint8List? pencilLogoData = await _loadPencilLogo();

      // Create a single PDF document for all receipts
      final pdf = pw.Document();

      // Add all receipts to the same document
      for (int i = 0; i < widget.selectedNumbers.length; i++) {
        final List<int> numbers = widget.selectedNumbers[i];
        final String ticketId = ticketIds[i];
        final String product = '$lotteryNumbers x $lotteryName';

        // Generate QR code with lottery code
        final Uint8List qrImageData = await _generateQrCode(ticketId);

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
                        ? pw.Image(pw.MemoryImage(companyLogoData), width: 100, height: 50)
                        : pw.Text('BIG RAFEAL',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),

                    // Add selected categories here
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
                    // Pencil logo (if available)
                    pencilLogoData != null
                        ? pw.Image(pw.MemoryImage(pencilLogoData), width: 50, height: 50)
                        : pw.SizedBox(),
                    pw.SizedBox(height: 5),

                    pw.SizedBox(height: 10),

                    // Selected numbers - INCREASED SIZE AND BOLD as requested
                    pw.Container(
                      alignment: pw.Alignment.center,
                      margin: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Wrap(
                        alignment: pw.WrapAlignment.center,
                        spacing: 8,
                        children: numbers.map((number) {
                          return pw.Container(
                            width: 20, // Increased from 16
                            height: 20, // Increased from 16
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(width: 0.8),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              number.toString().padLeft(2, '0'),
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), // Increased from 8 to 12
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    pw.SizedBox(height: 8),

                    // Ticket details - improved with bolder text
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Ticket ID:',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(ticketId,
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

                    // QR code - larger for better scanning
                    qrImageData.isNotEmpty
                        ? pw.Container(
                        width: 100,
                        height: 100,
                        color: PdfColors.white,
                        child: pw.Image(pw.MemoryImage(qrImageData))
                    )
                        : pw.Container(height: 100, width: 100),

                    // Footer with company details
                    pw.Text('BIG RAFEAL L.L.C',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('For more information,',
                        style: pw.TextStyle(fontSize: 8)),
                    pw.Text('visit www.bigrafeal.info',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    // pw.Text('or Call us @ 0554691351',
                    //     style: pw.TextStyle(fontSize: 8)),
                    pw.Text('info@bigrafeal.info',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('---- Thank You ----',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),

                    // Add cut line between receipts if not the last receipt
                    i < widget.selectedNumbers.length - 1
                        ? pw.Column(
                      children: [
                        pw.SizedBox(height: 10),
                        pw.Text('--------------------------------',
                            style: pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 10),
                      ],
                    )
                        : pw.SizedBox(height: 30),
                  ],
                );
              }
          ),
        );
      }

      // Print entire document once
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'BIG_RAFEAL_Tickets.pdf',
          format: PdfPageFormat.roll80
      );

      _showSnackBar('All receipts printed successfully');

      // Navigate to ticket details screen after printing
      if (mounted && widget.selectedNumbers.isNotEmpty) {
        final Object lotteryCode = _currentLottery?.id ?? '';

          Get.offAll(
            () => TicketDetailsScreen(
              selectedNumbersRows: widget.selectedNumbers,
              price: widget.price,
              ticketId: "BIGR$lotteryCode", // First ticket ID
              purchaseDateTime: _getCurrentDateTime(),
              product: '${widget.selectedNumbers.length} x ${_currentLottery?.lotteryName ?? 'GRAND 6'}',
            ),
          );
      }
    } catch (e) {
      _showSnackBar('Error printing receipts: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
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
      child: ElevatedButton(
        onPressed: _isPrinting ? null : _printReceipts,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
    );
  }
}
