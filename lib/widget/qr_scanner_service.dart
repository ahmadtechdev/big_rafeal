import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../api_service/api_service.dart';
import '../controllers/lottery_controller.dart';
import '../controllers/lottery_result_controller.dart';
import '../controllers/user_controller.dart';
import '../models/lottery_model.dart';
import '../utils/app_colors.dart';
import '../utils/custom_snackbar.dart';
import 'scanner_classes.dart';

class QRScannerService {
  final LotteryController lotteryController;
  final MobileScannerController scannerController = MobileScannerController();
  final ApiService apiService = Get.put(ApiService());
  final LotteryResultController resultController =
      Get.find<LotteryResultController>();

  // Create a RxBool to track loading state
  final RxBool isLoading = false.obs;

  QRScannerService({required this.lotteryController});

  Future<void> openQRScanner(BuildContext context) async {
    // Reset loading state
    isLoading.value = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (BuildContext modalContext) => SizedBox(
            height: MediaQuery.of(modalContext).size.height * 0.85,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Scan Your Ticket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            scannerController.stop();
                            Navigator.of(modalContext).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        // Scanner
                        MobileScanner(
                          controller: scannerController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty &&
                                barcodes.first.rawValue != null) {
                              // Prevent multiple scans
                              if (isLoading.value) return;

                              isLoading.value = true;

                              // Close the scanner
                              scannerController.stop();
                              Navigator.pop(modalContext);

                              // Process the scanned QR code
                              // We pass the original context, not modalContext
                              processQRCode(context, barcodes.first.rawValue!);
                            }
                          },
                        ),
                        // Overlay with scanning frame
                        CustomPaint(
                          size: Size(
                            MediaQuery.of(modalContext).size.width,
                            MediaQuery.of(modalContext).size.height,
                          ),
                          painter: ScannerOverlayPainter(),
                        ),
                        // Scanning animation
                        ScannerAnimation(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 24,
                    ),
                    child: Text(
                      'Position the QR code inside the box to check your ticket',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ).then((_) {
      // Make sure scanner is stopped when bottom sheet is closed
      scannerController.stop();
    });
  }

  Future<void> processQRCode(BuildContext context, String qrData) async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Refresh lottery data first
      await lotteryController.fetchLotteries();

      // Parse QR data
      final Map<String, dynamic>? qrDataMap = _parseQrData(qrData);
      if (qrDataMap == null || qrDataMap['receipt_id']!.toString().isEmpty) {
        Get.back(); // Close loading dialog
        CustomSnackBar.error("The scanned QR code is not valid");
        return;
      }

      final String ticketId = qrDataMap['receipt_id']!.toString();
      // final String ticketId = "52_newuser_1751535371028";

      print("Ahjkasf");
      print(ticketId);

      // Handle the API call
      final response = await apiService.checkTicketResult(ticketId);

      print("recot response");
      print(response);

      // Close loading dialog
      Get.back();

      if (!response.containsKey('success')) {
        CustomSnackBar.error("Invalid response from server");

        return;
      }

      if (response['success'] == false) {
        Get.dialog(
          AlertDialog(
            title: Text('Big Rafeal'),
            content: Text(response['message']),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('OK')),
            ],
          ),
        );
        if (response['message'].contains("yet")) {
          _handlePendingResults(response);
        } else {

          CustomSnackBar.error(response['message'] ?? 'An unknown error occurred',);

        }
        return;
      }

      // Handle successful response
      _handleSuccessfulResult(response);
    } on DioException catch (e) {
      Get.back(); // Close loading dialog
      CustomSnackBar.error( e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError
          ? 'Please check your internet connection'
          : 'Failed to connect to server', title: "Network Error");

    } catch (e) {
      Get.back(); // Close loading dialog
      CustomSnackBar.error('An unexpected error occurred',);

    } finally {
      isLoading.value = false;
    }
  }

  void _handlePendingResults(Map<String, dynamic> response) {
    final lotteryIdStr = response['lottery_id']?.toString().trim();
    final lotteryId = int.tryParse(lotteryIdStr ?? '');

    if (lotteryId == null) {
      CustomSnackBar.error('Invalid lottery information',);

      return;
    }
    final lottery = lotteryController.lotteries.firstWhereOrNull(
      (l) => l.id == lotteryId || l.id.toString() == lotteryIdStr,
    );

    if (lottery != null) {
      final timeLeft = lottery.endDate.difference(DateTime.now());
      _showPendingResultsDialog(timeLeft);
    } else {
      CustomSnackBar.error("Lottery information not found");

    }
  }

  // Update the _handleSuccessfulResult method in qr_scanner_service.dart
  void _handleSuccessfulResult(Map<String, dynamic> response) {
    final List<dynamic> tickets =
        response['tickets'] ??
        [response]; // Fallback to single ticket if array not present

    if (tickets.isEmpty) {
      CustomSnackBar.error("No ticket data found");

      return;
    }

    final lotteryId = int.tryParse(
      tickets.first['lottery_id']?.toString() ?? '',
    );
    if (lotteryId == null) {
      CustomSnackBar.error("Invalid lottery information");

      return;
    }

    final lottery = lotteryController.lotteries.firstWhereOrNull(
      (l) => l.id == lotteryId,
    );
    if (lottery == null) {
      CustomSnackBar.error("Lottery not found");

      return;
    }

    // Parse all tickets
    final List<Map<String, dynamic>> ticketResults = [];
    for (var ticket in tickets) {
      final selectedNumbers = _parseNumbers(ticket['selected_numbers']);
      final winningNumbers = _parseNumbers(ticket['winning_numbers']);
      final sequenceMatched = ticket['sequence_matched'] ?? 0;
      final rumbleMatched = ticket['rumble_matched'] ?? 0;
      final chanceMatched = ticket['chance_matched'] ?? 0;
      final seqWin = ticket['sequence_win_amount']?.toString() ?? "0";
      final rumWin = ticket['rumble_win_amount']?.toString() ?? "0";
      final chaWin = ticket['chance_win_amount']?.toString() ?? "0";

      if (selectedNumbers.isEmpty || winningNumbers.isEmpty) continue;

      final result = LotteryResult(
        resultType: _parseResultType(ticket),
        matchCount: (ticket['matched_numbers'] as int?) ?? 0,
        prizeAmount:
            double.tryParse(ticket['win_amount']?.toString() ?? '') ?? 0,
        selectedNumbers: selectedNumbers,
        winningNumbers: winningNumbers,
        isSequenceMatch: ticket['isSequenceMatch'] ?? false,
        isChanceMatch: ticket['isChanceMatch'] ?? false,
        isRumbleMatch: ticket['isRumbleMatch'] ?? false,
      );

      ticketResults.add({
        'result': result,
        'selectedNumbers': selectedNumbers,
        'winningNumbers': winningNumbers,
        'sequenceMatched': sequenceMatched,
        'rumbleMatched': rumbleMatched,
        'chanceMatched': chanceMatched,
        'seqWin': seqWin,
        'rumWin': rumWin,
        'chaWin': chaWin,
      });
    }

    if (ticketResults.isEmpty) {
      CustomSnackBar.error("No valid ticket data");

      return;
    }

    _showResultsDialog(
      ticketResults,
      lottery,
      response['order_id']?.toString() ?? '',
    );
  }

  void _showResultsDialog(
    List<Map<String, dynamic>> ticketResults,
    Lottery lottery,
    String orderId,
  ) {
    final canClaim = ticketResults.any(
      (t) =>
          t['result'].resultType != ResultType.loss &&
          t['result'].resultType != ResultType.error,
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ticket Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),

              // Ticket results list
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        ticketResults.map((ticket) {
                          final result = ticket['result'] as LotteryResult;
                          return _buildTicketCard(
                            result,
                            lottery,
                            ticket['selectedNumbers'],
                            ticket['winningNumbers'],
                            ticket['sequenceMatched'],
                            ticket['rumbleMatched'],
                            ticket['chanceMatched'],
                            ticket['seqWin'],
                            ticket['rumWin'],
                            ticket['chaWin'],
                          );
                        }).toList(),
                  ),
                ),
              ),

              // Print and Claim buttons
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _printResultReceipts(ticketResults, lottery, orderId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.print, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'PRINT ALL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canClaim)
                      ElevatedButton(
                        onPressed: () => _claimTickets(orderId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'CLAIM PRIZES',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _printResultReceipts(
    List<Map<String, dynamic>> ticketResults,
    Lottery lottery,
    String orderId,
  ) async {
    try {
      CustomSnackBar.success("Preparing receipts for printing...", title: "Printing", duration: 1);

      final pdf = pw.Document();
      final Uint8List? companyLogoData = await _loadCompanyLogo();
      final String currentDateTime = DateTime.now().toString().substring(0, 16);

      for (var ticket in ticketResults) {
        final result = ticket['result'] as LotteryResult;
        final selectedNumbers = ticket['selectedNumbers'] as List<int>;
        final winningNumbers = ticket['winningNumbers'] as List<int>;
        final seq = ticket['sequenceMatched'] as int;
        final rum = ticket['rumbleMatched'] as int;
        final cha = ticket['chanceMatched'] as int;
        final seqWin = ticket['seqWin'] as String;
        final rumWin = ticket['rumWin'] as String;
        final chaWin = ticket['chaWin'] as String;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.roll80,
            build: (pw.Context context) {
              return _buildReceiptPage(
                result,
                lottery,
                selectedNumbers,
                winningNumbers,
                seq,
                rum,
                cha,
                seqWin,
                rumWin,
                chaWin,
                companyLogoData,
                currentDateTime,
                orderId,
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'BIG_RAFEAL_Results_$orderId.pdf',
        format: PdfPageFormat.roll80,
      );

      CustomSnackBar.success("Preparing receipts for printing...", title: "Printing", duration: 1);

    } catch (e) {
      CustomSnackBar.error("Preparing receipts for printing...", title: "Printing", duration: 3);

    }
  }

  pw.Widget _buildReceiptPage(
    LotteryResult result,
    Lottery lottery,
    List<int> selectedNumbers,
    List<int> winningNumbers,
    int seq,
    int rum,
    int cha,
    String seqWin,
    String rumWin,
    String chaWin,
    Uint8List? companyLogoData,
    String currentDateTime,
    String orderId,
  ) {
    final bool isFullWin = result.resultType == ResultType.fullWin;
    final bool hasSequenceWin = result.isSequenceMatch;
    final bool hasChanceWin = result.isChanceMatch;
    final bool hasRumbleWin = result.isRumbleMatch;

    // Determine result status and details
    String resultStatus;
    String resultDetails;

    if (isFullWin) {
      resultStatus = 'JACKPOT WINNER!';
      resultDetails =
          'You matched all ${selectedNumbers.length} numbers!\nYou won AED ${result.prizeAmount}!';
    } else if (hasSequenceWin && hasRumbleWin && hasChanceWin) {
      resultStatus = 'STRAIGHT, CHANCE & RUMBLE WIN!';
      resultDetails =
          'Straight x$seq: $seqWin AED\n'
          'Rumble x$rum: $rumWin AED\n'
          'Chance x$cha: $chaWin AED\n'
          'Total: AED ${result.prizeAmount.toStringAsFixed(2)}';
    } else if (hasSequenceWin && hasRumbleWin) {
      resultStatus = 'STRAIGHT & RUMBLE WIN!';
      resultDetails =
          'Straight x$seq: $seqWin AED\n'
          'Rumble x$rum: $rumWin AED\n'
          'Total: AED ${result.prizeAmount.toStringAsFixed(2)}';
    } else if (hasChanceWin && hasRumbleWin) {
      resultStatus = 'CHANCE & RUMBLE WIN!';
      resultDetails =
          'Chance x$cha: $chaWin AED\n'
          'Rumble x$rum: $rumWin AED\n'
          'Total: AED ${result.prizeAmount.toStringAsFixed(2)}';
    } else if (hasSequenceWin && hasChanceWin) {
      resultStatus = 'STRAIGHT & CHANCE WIN!';
      resultDetails =
          'Straight x$seq: $seqWin AED\n'
          'Chance x$cha: $chaWin AED\n'
          'Total: AED ${result.prizeAmount.toStringAsFixed(2)}';
    } else if (hasSequenceWin) {
      resultStatus = 'STRAIGHT WIN!';
      resultDetails =
          'Straight x$seq: $seqWin AED\n'
          'Total: AED ${result.prizeAmount.toStringAsFixed(2)}';
    } else if (hasChanceWin) {
      resultStatus = 'CHANCE WIN!';
      resultDetails =
          'Chance x$cha: $chaWin AED\n'
          'Total: AED ${result.prizeAmount.toStringAsFixed(2)}';
    } else if (hasRumbleWin) {
      resultStatus = 'RUMBLE WIN!';
      resultDetails =
          'Rumble x$rum: $rumWin AED\n'
          'Total: AED ${result.prizeAmount.toStringAsFixed(2)}';
    } else {
      resultStatus = 'BETTER LUCK NEXT TIME!';
      resultDetails = 'Try again for a chance to win big!';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 10),
        // Header with order ID
        pw.Text(
          'Order #$orderId',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),

        // Company logo and header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (companyLogoData != null)
              pw.Image(pw.MemoryImage(companyLogoData)),
            pw.Column(
              children: [
                pw.Text(
                  'BIG RAFEAL LOTTERY',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(lottery.lotteryName, style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.Divider(),

        // Result status
        pw.Text(
          resultStatus,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          resultDetails,
          style: pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 12),

        // Numbers section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Text(
                  'YOUR NUMBERS:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      selectedNumbers
                          .map(
                            (number) => _buildPdfNumberCircle(
                              number,
                              PdfColors.orange,
                              winningNumbers.contains(number),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
            pw.Column(
              children: [
                pw.Text(
                  'WINNING NUMBERS:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      winningNumbers
                          .map(
                            (number) => _buildPdfNumberCircle(
                              number,
                              PdfColors.blue,
                              true,
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Prize breakdown if won
        if (isFullWin || hasSequenceWin || hasChanceWin || hasRumbleWin)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PRIZE BREAKDOWN:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              if (isFullWin)
                pw.Text(
                  'Full Match: AED ${result.prizeAmount}',
                  style: pw.TextStyle(fontSize: 9),
                ),
              if (hasSequenceWin && hasRumbleWin && hasChanceWin)
                pw.Column(
                  children: [
                    pw.Text(
                      'Straight x$seq: $seqWin AED',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Rumble x$rum: $rumWin AED',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Chance x$cha: $chaWin AED',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              // Other prize breakdown conditions...
              pw.SizedBox(height: 4),
              pw.Text(
                'TOTAL PRIZE: AED ${result.prizeAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),

        pw.Divider(),
        // Footer
        pw.Text('Date: $currentDateTime', style: pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text(
          'BIG RAFEAL L.L.C',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('www.bigrafeal.info', style: pw.TextStyle(fontSize: 8)),
        pw.Text('info@bigrafeal.info', style: pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 6),
        pw.Text(
          '---- Thank You ----',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildPdfNumberCircle(int number, PdfColor color, bool isMatched) {
    return pw.Container(
      width: 18,
      height: 18,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: color, width: 1),
        color: PdfColors.grey200,
      ),
      child: pw.Center(
        child: pw.Text(
          number.toString(),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isMatched ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }

  Future<void> _claimTickets(String orderId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Get the current user ID from UserController
      final userController = Get.find<UserController>();
      if (userController.currentUser.value == null) {
        Get.back(); // Close loading dialog
        CustomSnackBar.error("User not logged in...", title: "Error", duration: 1);

        return;
      }

      final userId = userController.currentUser.value!.id.toString();

      final response = await apiService.claimTickets(
        orderId: orderId,
        userId: userId,
      );

      Get.back(); // Close loading dialog

      if (response['success'] == true) {
        CustomSnackBar.success("Prizes claimed successfully!");

        Get.back(); // Close the results dialog
      } else {
        CustomSnackBar.error(response['message'] ?? 'Failed to claim prizes');
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      CustomSnackBar.error("Failed to claim prizes: $e");

    }
  }

  Widget _buildTicketCard(
    LotteryResult result,
    Lottery lottery,
    List<int> selectedNumbers,
    List<int> winningNumbers,
    int seq,
    int rum,
    int cha,
    String seqWin,
    String rumWin,
    String chaWin,
  ) {
    final bool isFullWin = result.resultType == ResultType.fullWin;
    final bool hasSequenceWin = result.isSequenceMatch;
    final bool hasChanceWin = result.isChanceMatch;
    final bool hasRumbleWin = result.isRumbleMatch;

    // Determine title and message (same as before)
    String resultTitle;
    Color resultColor;
    String resultMessage;

    // ... rest of the title/message logic from original _showResultDialog ...

    if (hasSequenceWin && hasRumbleWin && hasChanceWin) {
      resultTitle = 'STRAIGHT, CHANCE & RUMBLE WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nRumble x ${rum.toString()} = $rumWin AED\nChance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasSequenceWin && hasRumbleWin) {
      resultTitle = 'STRAIGHT & RUMBLE WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nRumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasChanceWin && hasRumbleWin) {
      resultTitle = 'CHANCE & RUMBLE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage =
          'Chance x ${cha.toString()} = $chaWin AED\nRumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasSequenceWin && hasChanceWin) {
      resultTitle = 'STRAIGHT & CHANCE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nChance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasSequenceWin) {
      resultTitle = 'STRAIGHT WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasChanceWin) {
      resultTitle = 'CHANCE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage =
          'Chance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasRumbleWin) {
      resultTitle = 'RUMBLE WIN!';
      resultColor = Colors.orange[600]!;
      resultMessage =
          'Rumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else {
      resultTitle = 'BETTER LUCK NEXT TIME!';
      resultColor = Colors.red[600]!;
      resultMessage = 'Try again for a chance to win big!';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Result title and animation
            Text(
              resultTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              width: 80,
              child:
                  isFullWin
                      ? _buildWinnerAnimation()
                      : hasSequenceWin && hasRumbleWin
                      ? _buildSequenceRumbleWinAnimation()
                      // ... rest of animation logic ...
                      : _buildTryAgainAnimation(),
            ),

            // Numbers display (same as before but more compact)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('Your Numbers:', style: TextStyle(fontSize: 12)),
                ...selectedNumbers.map(
                  (n) => _buildNumberCircle(
                    n,
                    Colors.orange,
                    winningNumbers.contains(n),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Winning:', style: TextStyle(fontSize: 12)),
                ...winningNumbers.map(
                  (n) => _buildNumberCircle(n, Colors.blue, true),
                ),
              ],
            ),

            // Prize info
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                resultMessage,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberCircle(int number, Color color, bool isMatched) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isMatched ? color.withOpacity(0.2) : Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }

  // Helper methods
  Map<String, dynamic>? _parseQrData(String qrData) {
    try {
      return jsonDecode(qrData);
    } catch (e) {
      return null;
    }
  }

  List<int> _parseNumbers(dynamic numbers) {
    try {
      return (numbers as List).map((n) => int.parse(n.toString())).toList();
    } catch (e) {
      return [];
    }
  }

  ResultType _parseResultType(Map<String, dynamic> response) {
    if (response['isFullWin'] == true) return ResultType.fullWin;
    if (response['isSequenceMatch'] == true) return ResultType.sequenceWin;
    if (response['isChanceMatch'] == true) return ResultType.chanceWin;
    if (response['isRumbleMatch'] == true) return ResultType.rumbleWin;
    return ResultType.loss;
  }

  // Show error dialog safely
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Display pending results dialog
  void _showPendingResultsDialog(Duration timeLeft) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'RESULTS PENDING',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Results will be announced in:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),
              Text(
                '${timeLeft.inDays}d ${timeLeft.inHours % 24}h ${timeLeft.inMinutes % 60}m',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Please check back after the draw date to see if you won!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Display result dialog with win or loss
  void _showResultDialog(
    LotteryResult result,
    Lottery lottery,
    int totalNumbers,
    List<int> selectedNumbers,
    List<int> winningNumbers,
    int seq,
    int rum,
    int cha,
    String seqWin,
    String rumWin,
    String chaWin,
  ) {
    final bool isFullWin = result.resultType == ResultType.fullWin;
    final bool hasSequenceWin = result.isSequenceMatch;
    final bool hasChanceWin = result.isChanceMatch;
    final bool hasRumbleWin = result.isRumbleMatch;

    // Determine the best title and message based on match types
    String resultTitle;
    Color resultColor;
    String resultMessage;

    if (hasSequenceWin && hasRumbleWin && hasChanceWin) {
      resultTitle = 'STRAIGHT, CHANCE & RUMBLE WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nRumble x ${rum.toString()} = $rumWin AED\nChance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasSequenceWin && hasRumbleWin) {
      resultTitle = 'STRAIGHT & RUMBLE WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nRumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasChanceWin && hasRumbleWin) {
      resultTitle = 'CHANCE & RUMBLE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage =
          'Chance x ${cha.toString()} = $chaWin AED\nRumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasSequenceWin && hasChanceWin) {
      resultTitle = 'STRAIGHT & CHANCE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nChance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasSequenceWin) {
      resultTitle = 'STRAIGHT WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage =
          'Straight x ${seq.toString()} = $seqWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasChanceWin) {
      resultTitle = 'CHANCE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage =
          'Chance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasRumbleWin) {
      resultTitle = 'RUMBLE WIN!';
      resultColor = Colors.orange[600]!;
      resultMessage =
          'Rumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else {
      resultTitle = 'BETTER LUCK NEXT TIME!';
      resultColor = Colors.red[600]!;
      resultMessage = 'Try again for a chance to win big!';
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child:
                      isFullWin
                          ? _buildWinnerAnimation()
                          : hasSequenceWin && hasRumbleWin
                          ? _buildSequenceRumbleWinAnimation()
                          : hasChanceWin && hasRumbleWin
                          ? _buildChanceRumbleWinAnimation()
                          : hasSequenceWin
                          ? _buildSequenceWinAnimation()
                          : hasChanceWin
                          ? _buildChanceWinAnimation()
                          : hasRumbleWin
                          ? _buildRumbleWinAnimation()
                          : _buildTryAgainAnimation(),
                ),
                const SizedBox(height: 16),
                Text(
                  resultTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  resultMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    const Text(
                      'Your Numbers:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          selectedNumbers.map((number) {
                            winningNumbers.contains(number);
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  number.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Winning Numbers:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          winningNumbers.map((number) {
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  number.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _printResultReceipt(
                          result,
                          lottery,
                          selectedNumbers,
                          winningNumbers,
                          seq,
                          rum,
                          cha,
                          seqWin,
                          rumWin,
                          chaWin,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.print, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'PRINT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        isFullWin ||
                                hasSequenceWin ||
                                hasChanceWin ||
                                hasRumbleWin
                            ? 'CLAIM PRIZE'
                            : 'TRY AGAIN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // New animation for combined Sequence + Rumble win
  Widget _buildSequenceRumbleWinAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating circle
            Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.5),
                    width: 8,
                  ),
                ),
              ),
            ),
            // Sequence icon
            Icon(Icons.format_list_numbered, size: 60, color: Colors.blue[600]),
            // Rumble icon
            Transform.translate(
              offset: const Offset(20, 20),
              child: Icon(Icons.casino, size: 40, color: Colors.orange[600]),
            ),
            // Sparkles
            if (value > 0.5)
              Positioned(
                right: 20,
                top: 20,
                child: Icon(
                  Icons.star,
                  size: 30 * (value - 0.5) * 2,
                  color: Colors.blue[300],
                ),
              ),
          ],
        );
      },
    );
  }

  // New animation for combined Chance + Rumble win
  Widget _buildChanceRumbleWinAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating circle
            Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.5),
                    width: 8,
                  ),
                ),
              ),
            ),
            // Chance icon
            Icon(Icons.compare_arrows, size: 60, color: Colors.purple[600]),
            // Rumble icon
            Transform.translate(
              offset: const Offset(20, 20),
              child: Icon(Icons.casino, size: 40, color: Colors.orange[600]),
            ),
            // Sparkles
            if (value > 0.5)
              Positioned(
                right: 20,
                top: 20,
                child: Icon(
                  Icons.star,
                  size: 30 * (value - 0.5) * 2,
                  color: Colors.purple[300],
                ),
              ),
          ],
        );
      },
    );
  }

  // Add this new animation for chance wins
  Widget _buildChanceWinAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating circle
            Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.5),
                    width: 8,
                  ),
                ),
              ),
            ),
            // Reverse icon
            Icon(Icons.compare_arrows, size: 80, color: Colors.purple[600]),
            // Sparkles
            if (value > 0.5)
              Positioned(
                right: 20,
                top: 20,
                child: Icon(
                  Icons.star,
                  size: 30 * (value - 0.5) * 2,
                  color: Colors.purple[300],
                ),
              ),
          ],
        );
      },
    );
  }

  // Update the partial win animation to rumble win
  Widget _buildRumbleWinAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating circle
            Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 8,
                  ),
                ),
              ),
            ),
            // Dollar sign
            Icon(Icons.casino, size: 80, color: Colors.orange[600]),
            // Sparkles
            if (value > 0.5)
              Positioned(
                right: 20,
                top: 20,
                child: Icon(
                  Icons.star,
                  size: 30 * (value - 0.5) * 2,
                  color: Colors.orange[300],
                ),
              ),
          ],
        );
      },
    );
  }

  // Update the _printResultReceipt method
  Future<void> _printResultReceipt(
    LotteryResult result,
    Lottery lottery,
    List<int> selectedNumbers,
    List<int> winningNumbers,
    int seq,
    int rum,
    int cha,
    String seqWin,
    String rumWin,
    String chaWin,
  ) async {
    try {
      // Show printing indicator
      CustomSnackBar.success("Preparing receipt for printing...", title: "Printing", duration: 1);

      // Create PDF document
      final pdf = pw.Document();
      final Uint8List? companyLogoData = await _loadCompanyLogo();

      // Get current date time for receipt
      final String currentDateTime = DateTime.now().toString().substring(0, 16);

      // Format result information
      final bool isFullWin = result.resultType == ResultType.fullWin;
      final bool hasSequenceWin = result.resultType == ResultType.sequenceWin;
      final bool hasChanceWin = result.resultType == ResultType.chanceWin;
      final bool hasRumbleWin = result.resultType == ResultType.rumbleWin;

      final int totalNumbers = selectedNumbers.length;

      // Determine result status and details based on all possible combinations
      String resultStatus;
      String resultDetails;

      if (isFullWin) {
        resultStatus = 'JACKPOT WINNER!';
        resultDetails =
            'You matched all $totalNumbers numbers!\nYou won AED ${result.prizeAmount}!';
      } else if (hasSequenceWin && hasRumbleWin && hasChanceWin) {
        resultStatus = 'STRAIGHT, CHANCE & RUMBLE WIN!';
        resultDetails =
            'Straight x ${seq.toString()} = $seqWin AED\n'
            'Rumble x ${rum.toString()} = $rumWin AED\n'
            'Chance x ${cha.toString()} = $chaWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasSequenceWin && hasRumbleWin) {
        resultStatus = 'STRAIGHT & RUMBLE WIN!';
        resultDetails =
            'Straight x ${seq.toString()} = $seqWin AED\n'
            'Rumble x ${rum.toString()} = $rumWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasChanceWin && hasRumbleWin) {
        resultStatus = 'CHANCE & RUMBLE WIN!';
        resultDetails =
            'Chance x ${cha.toString()} = $chaWin AED\n'
            'Rumble x ${rum.toString()} = $rumWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasSequenceWin && hasChanceWin) {
        resultStatus = 'STRAIGHT & CHANCE WIN!';
        resultDetails =
            'Straight x ${seq.toString()} = $seqWin AED\n'
            'Chance x ${cha.toString()} = $chaWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasSequenceWin) {
        resultStatus = 'STRAIGHT WIN!';
        resultDetails =
            'Straight x ${seq.toString()} = $seqWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasChanceWin) {
        resultStatus = 'CHANCE WIN!';
        resultDetails =
            'Chance x ${cha.toString()} = $chaWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasRumbleWin) {
        resultStatus = 'RUMBLE WIN!';
        resultDetails =
            'Rumble x ${rum.toString()} = $rumWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else {
        resultStatus = 'BETTER LUCK NEXT TIME!';
        resultDetails = 'Try again for a chance to win big!';
      }

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
                pw.Text(
                  'LOTTERY RESULT',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  lottery.lotteryName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'GRAND JACKPOT ${lottery.maxReward} AED',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(thickness: 1),

                // Result status
                pw.SizedBox(height: 12),
                pw.Text(
                  resultStatus,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  resultDetails,
                  style: pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),

                // Your Numbers section
                pw.Text(
                  'YOUR NUMBERS:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Wrap(
                    alignment: pw.WrapAlignment.center,
                    spacing: 8,
                    children:
                        selectedNumbers.map((number) {
                          final isMatched = winningNumbers.contains(number);
                          return pw.Container(
                            width: 18,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(width: 1),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              number.toString(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    isMatched ? pw.FontWeight.bold : null,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),

                // Winning Numbers section
                pw.SizedBox(height: 12),
                pw.Text(
                  'WINNING NUMBERS:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Wrap(
                    alignment: pw.WrapAlignment.center,
                    spacing: 8,
                    children:
                        winningNumbers.map((number) {
                          return pw.Container(
                            width: 18,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(width: 1),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              number.toString(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),

                pw.SizedBox(height: 12),
                // Prize breakdown section
                (isFullWin || hasSequenceWin || hasChanceWin || hasRumbleWin)
                    ? pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PRIZE BREAKDOWN:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (isFullWin)
                          pw.Text(
                            'Full Match: AED ${result.prizeAmount}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        if (hasSequenceWin && hasRumbleWin && hasChanceWin)
                          pw.Column(
                            children: [
                              pw.Text(
                                'Straight x$seq: $seqWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                'Rumble x$rum: $rumWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                'Chance x$cha: $chaWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        if (hasSequenceWin && hasRumbleWin && !hasChanceWin)
                          pw.Column(
                            children: [
                              pw.Text(
                                'Straight x$seq: $seqWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                'Rumble x$rum: $rumWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        if (hasChanceWin && hasRumbleWin)
                          pw.Column(
                            children: [
                              pw.Text(
                                'Chance x$cha: $chaWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                'Rumble x$rum: $rumWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        if (hasSequenceWin && hasChanceWin)
                          pw.Column(
                            children: [
                              pw.Text(
                                'Straight x$seq: $seqWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                'Chance x$cha: $chaWin AED',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        if (hasSequenceWin && !hasRumbleWin && !hasChanceWin)
                          pw.Text(
                            'Straight x$seq: $seqWin AED',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        if (hasChanceWin && !hasRumbleWin && !hasSequenceWin)
                          pw.Text(
                            'Chance x$cha: $chaWin AED',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        if (hasRumbleWin && !hasChanceWin && !hasSequenceWin)
                          pw.Text(
                            'Rumble x$rum: $rumWin AED',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'TOTAL PRIZE: AED ${result.prizeAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                    : pw.SizedBox(),

                pw.Divider(thickness: 1),
                // Footer
                pw.Text(
                  'Date: $currentDateTime',
                  style: pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'BIG RAFEAL L.L.C',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('www.bigrafeal.info', style: pw.TextStyle(fontSize: 8)),
                pw.Text(
                  'info@bigrafeal.info',
                  style: pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '---- Thank You ----',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          },
        ),
      );

      // Print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'BIG_RAFEAL_Result.pdf',
        format: PdfPageFormat.roll80,
      );

      CustomSnackBar.success("Receipt printed successfully...", title: "Printing", duration: 1);

    } catch (e) {
      CustomSnackBar.success("Error printing receipt: $e'", title: "Printing", duration: 3);


    }
  }

  Future<Uint8List?> _loadCompanyLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo2.png');
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  // Add this new animation for sequence wins
  Widget _buildSequenceWinAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating circle
            Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.5),
                    width: 8,
                  ),
                ),
              ),
            ),
            // Sequence icon
            Icon(Icons.format_list_numbered, size: 80, color: Colors.blue[600]),
            // Sparkles
            if (value > 0.5)
              Positioned(
                right: 20,
                top: 20,
                child: Icon(
                  Icons.star,
                  size: 30 * (value - 0.5) * 2,
                  color: Colors.blue[300],
                ),
              ),
          ],
        );
      },
    );
  }

  // Simple winner animation using built-in Flutter animations
  Widget _buildWinnerAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Trophy icon
            Icon(Icons.emoji_events, size: 80, color: Colors.amber[600]),
            // Animated circles around trophy
            ...List.generate(8, (index) {
              final angle = index * (2 * 3.14159 / 8);
              final x = 75 + math.cos(angle) * 50 * value;
              final y = 75 + math.sin(angle) * 50 * value;
              return Positioned(
                left: x,
                top: y,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.amber[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
            // Star animation
            AnimatedBuilder(
              animation: AnimationController(
                duration: const Duration(milliseconds: 1500),
                vsync: const TickerProviderImpl(),
              )..repeat(),
              builder: (context, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Icon(
                    Icons.star,
                    size: 120 * value,
                    color: Colors.amber.withOpacity(0.3),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Simple try again animation using built-in Flutter animations
  Widget _buildTryAgainAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating circle
            Transform.rotate(
              angle: value * 2 * 3.14159,
              child: CircularProgressIndicator(
                value: value,
                color: Colors.red[300],
                strokeWidth: 8,
              ),
            ),
            // Sad face icon
            Icon(
              Icons.sentiment_dissatisfied,
              size: 80,
              color: Colors.red[600],
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
