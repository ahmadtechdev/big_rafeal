import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../api_service/api_service.dart';
import '../controllers/lottery_controller.dart';
import '../controllers/lottery_result_controller.dart';
import '../models/lottery_model.dart';
import '../utils/app_colors.dart';

class QRScannerService {
  final LotteryController lotteryController;
  final MobileScannerController scannerController = MobileScannerController();
  final ApiService apiService = Get.put(ApiService());
  final LotteryResultController resultController = Get.find<LotteryResultController>();

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
      builder: (BuildContext modalContext) => SizedBox(
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
                        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
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
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Text(
                  'Position the QR code inside the box to check your ticket',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
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
        Get.snackbar('Invalid QR Code', 'The scanned QR code is not valid');
        return;
      }

      final String ticketId = qrDataMap['receipt_id']!.toString();

      print("Ahjkasf");
      print(ticketId);

      // Handle the API call
      final response = await apiService.checkTicketResult(ticketId);

      print("recot response");
      print(response);

      // Close loading dialog
      Get.back();

      if (!response.containsKey('success')) {
        Get.snackbar('Error', 'Invalid response from server');
        return;
      }

      if (response['success'] == false) {
        if (response['message'] == 'Ticket not found') {
          Get.dialog(
            AlertDialog(
              title: Text('Ticket Not Found'),
              content: Text('This ticket could not be found in our system'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else if (response['message'] == 'Lottery result is not announced yet') {
          _handlePendingResults(response);
        } else {
          Get.snackbar('Error', response['message'] ?? 'An unknown error occurred');
        }
        return;
      }

      // Handle successful response
      _handleSuccessfulResult(response);
    } on DioException catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Network Error',
        e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError
            ? 'Please check your internet connection'
            : 'Failed to connect to server',
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar('Error', 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePendingResults(Map<String, dynamic> response) {
    final lotteryIdStr = response['lottery_id']?.toString().trim();
    final lotteryId = int.tryParse(lotteryIdStr ?? '');

    if (lotteryId == null) {
      Get.snackbar('Error', 'Invalid lottery information');
      return;
    }
    final lottery = lotteryController.lotteries.firstWhereOrNull(
            (l) => l.id == lotteryId || l.id.toString() == lotteryIdStr
    );

    if (lottery != null) {
      final timeLeft = lottery.endDate.difference(DateTime.now());
      _showPendingResultsDialog(timeLeft);
    } else {
      Get.snackbar('Error', 'Lottery information not found');
    }
  }

  void _handleSuccessfulResult(Map<String, dynamic> response) {
    final lotteryId = int.tryParse(response['lottery_id']?.toString() ?? '');
    if (lotteryId == null) {
      Get.snackbar('Error', 'Invalid lottery information');
      return;
    }

    final lottery = lotteryController.lotteries.firstWhereOrNull((l) => l.id == lotteryId);
    if (lottery == null) {
      Get.snackbar('Error', 'Lottery not found');
      return;
    }

    final selectedNumbers = _parseNumbers(response['selected_numbers']);
    final winningNumbers = _parseNumbers(response['winning_numbers']);
    final sequenceMatched = response['sequence_matched'];
    final rumbleMatched = response['rumble_matched'];
    final chanceMatched =response['chance_matched'];

    if (selectedNumbers.isEmpty || winningNumbers.isEmpty) {
      Get.snackbar('Error', 'Invalid number data');
      return;
    }

    final result = LotteryResult(
      resultType: _parseResultType(response),
      matchCount: (response['matched_numbers'] as int?) ?? 0,
      prizeAmount: double.tryParse(response['win_amount']?.toString() ?? '') ?? 0,
      selectedNumbers: selectedNumbers,
      winningNumbers: winningNumbers,
      isSequenceMatch: response['isSequenceMatch'] ?? false,
      isChanceMatch: response['isChanceMatch'] ?? false,
      isRumbleMatch: response['isRumbleMatch'] ?? false,
    );

    _showResultDialog(
      result,
      lottery,
      selectedNumbers.length,
      selectedNumbers,
      winningNumbers,
      sequenceMatched,
      rumbleMatched,
      chanceMatched,
        response['sequence_win_amount']??"",
        response['rumble_win_amount']??"",
        response['chance_win_amount']??"",


    );
  }
  // Helper to close loading dialog and show error

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
                const Icon(
                  Icons.access_time,
                  size: 80,
                  color: Colors.blue,
                ),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
      String chaWin
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
      resultTitle = 'SEQUENCE, CHANCE & RUMBLE WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage = 'Sequence x ${seq.toString()} = $seqWin AED\nRumble x ${rum.toString()} = $rumWin AED\nChance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    }else if (hasSequenceWin && hasRumbleWin) {
      resultTitle = 'SEQUENCE & RUMBLE WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage = 'Sequence x ${seq.toString()} = $seqWin AED\nRumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasChanceWin && hasRumbleWin) {
      resultTitle = 'CHANCE & RUMBLE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage = 'Chance x ${cha.toString()} = $chaWin AED\nRumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    }else if (hasSequenceWin && hasChanceWin) {
      resultTitle = 'SEQUENCE & CHANCE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage = 'Sequence x ${seq.toString()} = $seqWin AED\nChance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasSequenceWin) {
      resultTitle = 'SEQUENCE WIN!';
      resultColor = Colors.blue[600]!;
      resultMessage = 'Sequence x ${seq.toString()} = $seqWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasChanceWin) {
      resultTitle = 'CHANCE WIN!';
      resultColor = Colors.purple[600]!;
      resultMessage = 'Chance x ${cha.toString()} = $chaWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
    } else if (hasRumbleWin) {
      resultTitle = 'RUMBLE WIN!';
      resultColor = Colors.orange[600]!;
      resultMessage = 'Rumble x ${rum.toString()} = $rumWin AED\nYou won AED ${result.prizeAmount.toStringAsFixed(2)}!';
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
                    child: isFullWin
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
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
                        children: selectedNumbers.map((number) {
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
                        children: winningNumbers.map((number) {
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
                          _printResultReceipt(result, lottery, selectedNumbers, winningNumbers, seq, rum, cha, seqWin, rumWin, chaWin);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isFullWin || hasSequenceWin || hasChanceWin || hasRumbleWin
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
            Icon(
              Icons.format_list_numbered,
              size: 60,
              color: Colors.blue[600],
            ),
            // Rumble icon
            Transform.translate(
              offset: const Offset(20, 20),
              child: Icon(
                Icons.casino,
                size: 40,
                color: Colors.orange[600],
              ),
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
            Icon(
              Icons.compare_arrows,
              size: 60,
              color: Colors.purple[600],
            ),
            // Rumble icon
            Transform.translate(
              offset: const Offset(20, 20),
              child: Icon(
                Icons.casino,
                size: 40,
                color: Colors.orange[600],
              ),
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
            Icon(
              Icons.compare_arrows,
              size: 80,
              color: Colors.purple[600],
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
            Icon(
              Icons.casino,
              size: 80,
              color: Colors.orange[600],
            ),
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
      String chaWin
      ) async {
    try {
      // Show printing indicator
      Get.snackbar("Printing", "Preparing receipt for printing...");

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
        resultDetails = 'You matched all $totalNumbers numbers!\nYou won AED ${result.prizeAmount}!';
      } else if (hasSequenceWin && hasRumbleWin && hasChanceWin) {
        resultStatus = 'SEQUENCE, CHANCE & RUMBLE WIN!';
        resultDetails = 'Sequence x ${seq.toString()} = $seqWin AED\n'
            'Rumble x ${rum.toString()} = $rumWin AED\n'
            'Chance x ${cha.toString()} = $chaWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasSequenceWin && hasRumbleWin) {
        resultStatus = 'SEQUENCE & RUMBLE WIN!';
        resultDetails = 'Sequence x ${seq.toString()} = $seqWin AED\n'
            'Rumble x ${rum.toString()} = $rumWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasChanceWin && hasRumbleWin) {
        resultStatus = 'CHANCE & RUMBLE WIN!';
        resultDetails = 'Chance x ${cha.toString()} = $chaWin AED\n'
            'Rumble x ${rum.toString()} = $rumWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasSequenceWin && hasChanceWin) {
        resultStatus = 'SEQUENCE & CHANCE WIN!';
        resultDetails = 'Sequence x ${seq.toString()} = $seqWin AED\n'
            'Chance x ${cha.toString()} = $chaWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasSequenceWin) {
        resultStatus = 'SEQUENCE WIN!';
        resultDetails = 'Sequence x ${seq.toString()} = $seqWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasChanceWin) {
        resultStatus = 'CHANCE WIN!';
        resultDetails = 'Chance x ${cha.toString()} = $chaWin AED\n'
            'You won AED ${result.prizeAmount.toStringAsFixed(2)}!';
      } else if (hasRumbleWin) {
        resultStatus = 'RUMBLE WIN!';
        resultDetails = 'Rumble x ${rum.toString()} = $rumWin AED\n'
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
                      ? pw.Image(pw.MemoryImage(companyLogoData), width: 100, height: 50)
                      : pw.Text('BIG RAFEAL',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('LOTTERY RESULT',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(lottery.lotteryName,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('GRAND JACKPOT ${lottery.maxReward} AED',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(thickness: 1),

                  // Result status
                  pw.SizedBox(height: 12),
                  pw.Text(resultStatus,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text(resultDetails,
                      style: pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 12),

                  // Your Numbers section
                  pw.Text('YOUR NUMBERS:',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    child: pw.Wrap(
                      alignment: pw.WrapAlignment.center,
                      spacing: 8,
                      children: selectedNumbers.map((number) {
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
                                fontWeight: isMatched ? pw.FontWeight.bold : null
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Winning Numbers section
                  pw.SizedBox(height: 12),
                  pw.Text('WINNING NUMBERS:',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    child: pw.Wrap(
                      alignment: pw.WrapAlignment.center,
                      spacing: 8,
                      children: winningNumbers.map((number) {
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
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
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
                        pw.Text('PRIZE BREAKDOWN:',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        if (isFullWin)
                          pw.Text('Full Match: AED ${result.prizeAmount}',
                              style: pw.TextStyle(fontSize: 9)),
                        if (hasSequenceWin && hasRumbleWin && hasChanceWin)
                          pw.Column(children: [
                            pw.Text('Sequence x$seq: $seqWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                            pw.Text('Rumble x$rum: $rumWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                            pw.Text('Chance x$cha: $chaWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                          ]),
                        if (hasSequenceWin && hasRumbleWin && !hasChanceWin)
                          pw.Column(children: [
                            pw.Text('Sequence x$seq: $seqWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                            pw.Text('Rumble x$rum: $rumWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                          ]),
                        if (hasChanceWin && hasRumbleWin)
                          pw.Column(children: [
                            pw.Text('Chance x$cha: $chaWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                            pw.Text('Rumble x$rum: $rumWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                          ]),
                        if (hasSequenceWin && hasChanceWin)
                          pw.Column(children: [
                            pw.Text('Sequence x$seq: $seqWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                            pw.Text('Chance x$cha: $chaWin AED',
                                style: pw.TextStyle(fontSize: 9)),
                          ]),
                        if (hasSequenceWin && !hasRumbleWin && !hasChanceWin)
                          pw.Text('Sequence x$seq: $seqWin AED',
                              style: pw.TextStyle(fontSize: 9)),
                        if (hasChanceWin && !hasRumbleWin && !hasSequenceWin)
                          pw.Text('Chance x$cha: $chaWin AED',
                              style: pw.TextStyle(fontSize: 9)),
                        if (hasRumbleWin && !hasChanceWin && !hasSequenceWin)
                          pw.Text('Rumble x$rum: $rumWin AED',
                              style: pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('TOTAL PRIZE: AED ${result.prizeAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ]
                  )
                      : pw.SizedBox(),

                  pw.Divider(thickness: 1),
                  // Footer
                  pw.Text('Date: $currentDateTime',
                      style: pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 4),
                  pw.Text('BIG RAFEAL L.L.C',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('www.bigrafeal.info',
                      style: pw.TextStyle(fontSize: 8)),
                  pw.Text('info@bigrafeal.info',
                      style: pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 6),
                  pw.Text('---- Thank You ----',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                ],
              );
            }
        ),
      );

      // Print the PDF
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'BIG_RAFEAL_Result.pdf',
          format: PdfPageFormat.roll80
      );

      Get.snackbar("Printing", "Receipt printed successfully");
    } catch (e) {
      Get.snackbar("Printing", "Error printing receipt: $e'");
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
            Icon(
              Icons.format_list_numbered,
              size: 80,
              color: Colors.blue[600],
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
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber[600],
            ),
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
                vsync: const _TickerProviderImpl(),
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

// Helper class for animations
class _TickerProviderImpl extends TickerProvider {
  const _TickerProviderImpl();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

// Custom painter to create the overlay with scanning box
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double boxWidth = size.width * 0.7;
    final double boxHeight = boxWidth;
    final double left = (size.width - boxWidth) / 2;
    final double top = (size.height - boxHeight) / 2;
    final double right = left + boxWidth;
    final double bottom = top + boxHeight;

    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw overlay
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(Rect.fromLTRB(left, top, right, bottom))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw scan box borders
    final borderPaint = Paint()
      ..color = AppColors.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top-left corner
    canvas.drawLine(Offset(left, top + 30), Offset(left, top), borderPaint);
    canvas.drawLine(Offset(left, top), Offset(left + 30, top), borderPaint);

    // Top-right corner
    canvas.drawLine(Offset(right - 30, top), Offset(right, top), borderPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + 30), borderPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, bottom - 30), Offset(left, bottom), borderPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + 30, bottom), borderPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(right - 30, bottom), Offset(right, bottom), borderPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - 30), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Animated scanner line
class ScannerAnimation extends StatefulWidget {
  const ScannerAnimation({super.key});

  @override
  _ScannerAnimationState createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double boxWidth = MediaQuery.of(context).size.width * 0.7;
    final double boxHeight = boxWidth;
    final double left = (MediaQuery.of(context).size.width - boxWidth) / 2;
    final double top = (MediaQuery.of(context).size.height - boxHeight) / 4.2;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: top + (boxHeight * _animationController.value),
          left: left,
          child: Container(
            width: boxWidth,
            height: 2.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0),
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        );
      },
    );
  }
}