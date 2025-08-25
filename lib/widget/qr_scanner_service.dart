import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import '../api_service/api_service.dart';
import '../controllers/lottery_controller.dart';
import '../controllers/lottery_result_controller.dart';
import '../controllers/user_controller.dart';
import '../dashboard.dart';
import '../models/lottery_model.dart';
import '../utils/app_colors.dart';
import '../utils/custom_snackbar.dart';
import 'scanner_classes.dart';

class QRScannerService {
  final LotteryController lotteryController;
  MobileScannerController? scannerController; // Make nullable
  final ApiService apiService = Get.put(ApiService());
  final LotteryResultController resultController =
  Get.find<LotteryResultController>();

  // Create a RxBool to track loading state
  final RxBool isLoading = false.obs;
  final RxBool isScannerActive = false.obs; // Add scanner state tracking

  QRScannerService({required this.lotteryController});

  // Add method to initialize scanner
  void _initializeScanner() {
    scannerController?.dispose();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  // Add this new method to QRScannerService class
  Future<void> openManualInput(BuildContext context) async {
    final TextEditingController orderIdController = TextEditingController();

    await showModalBottomSheet(
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
                        const Icon(Icons.receipt_long, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Enter Order ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Beautiful input field with animation
                          TextField(
                            controller: orderIdController,
                            decoration: InputDecoration(
                              labelText: 'Order ID',
                              hintText: 'Enter your order/ticket ID',
                              prefixIcon: const Icon(Icons.confirmation_number),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryColor,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[400]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryColor,
                                  width: 2,
                                ),
                              ),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 32),
                          // Submit button with nice animation
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (orderIdController.text.isEmpty) {
                                  CustomSnackBar.error(
                                    "Please enter an order ID",
                                  );
                                  return;
                                }

                                Navigator.of(modalContext).pop();
                                await processQRCode(
                                  context,
                                  orderIdController.text,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.primaryColor.withOpacity(
                                  0.3,
                                ),
                              ),
                              child: const Text(
                                'CHECK RESULTS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Or scan QR code option
                          TextButton(
                            onPressed: () {
                              Navigator.of(modalContext).pop();
                              openQRScanner(context);
                            },
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(text: 'Or '),
                                  TextSpan(
                                    text: 'scan QR code',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Add this method to show a choice dialog
  Future<void> showScanOrInputChoice(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Check Ticket Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // QR Scan Option
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openQRScanner(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.qr_code_scanner, size: 24, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'SCAN QR CODE',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Manual Input Option
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openManualInput(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard,
                      size: 24,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ENTER ORDER ID',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Add permission check method
  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      CustomSnackBar.error(
          "Camera permission is permanently denied. Please enable it in app settings.",
          title: "Permission Required"
      );
      await openAppSettings();
      return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }


  // Update the openQRScanner method
  Future<void> openQRScanner(BuildContext context) async {

    final hasPermission = await _checkCameraPermission();
    if (!hasPermission) {
      CustomSnackBar.error("Camera permission is required to scan QR codes");
      return;
    }


    // Reset loading state and initialize scanner
    isLoading.value = false;
    isScannerActive.value = false;
    _initializeScanner();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) => SizedBox(
        height: MediaQuery.of(modalContext).size.height * 0.90,
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
                        _stopScanner();
                        Navigator.of(modalContext).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Scanner with proper initialization - REMOVE Expanded from here
                    FutureBuilder(
                      future: _startScanner(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || scannerController == null) {
                          return _buildCameraErrorUI(modalContext, context);
                        }

                        return Obx(() => isScannerActive.value
                            ? MobileScanner(
                          controller: scannerController!,
                          onDetect: (capture) {
                            _handleScanDetection(capture, modalContext);
                          },
                        )
                            : const Center(child: CircularProgressIndicator()));
                      },
                    ),
                    // Overlay with scanning frame (only show when scanner is active)
                    Obx(() => isScannerActive.value
                        ? CustomPaint(
                      size: Size(
                        MediaQuery.of(modalContext).size.width,
                        MediaQuery.of(modalContext).size.height,
                      ),
                      painter: ScannerOverlayPainter(),
                    )
                        : const SizedBox()),

                    // Scanning animation (only show when scanner is active)
                    Obx(() => isScannerActive.value
                        ? ScannerAnimation()
                        : const SizedBox()),
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
      _stopScanner();
    });
  }

  // Extract scan detection logic
  void _handleScanDetection(BarcodeCapture capture, BuildContext modalContext) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      if (isLoading.value) return;

      isLoading.value = true;
      isScannerActive.value = false;

      _stopScanner();
      Navigator.pop(modalContext);

      processQRCode(modalContext, barcodes.first.rawValue!);
    }
  }

  // Build camera error UI
  Widget _buildCameraErrorUI(BuildContext modalContext, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Camera initialization failed',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(modalContext).pop();
              openManualInput(context);
            },
            child: const Text('Enter Order ID Instead'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(modalContext).pop();
              await Future.delayed(const Duration(milliseconds: 300));
              openQRScanner(context);
            },
            child: const Text('Retry Camera'),
          ),
        ],
      ),
    );
  }

  // Improve scanner start with better error handling
  Future<void> _startScanner() async {
    try {
      if (scannerController != null) {
        await scannerController!.start();
        // Add a small delay to ensure camera is fully initialized
        await Future.delayed(const Duration(milliseconds: 800));
        isScannerActive.value = true;
      }
    } catch (e) {
      print('Scanner start error: $e');
      isScannerActive.value = false;
      rethrow;
    }
  }
  // Add method to properly stop scanner
  void _stopScanner() {
    try {
      isScannerActive.value = false;
      scannerController?.stop();
    } catch (e) {
      print('Scanner stop error: $e');
    }
  }

  // Add dispose method to clean up resources
  void dispose() {
    _stopScanner();
    scannerController?.dispose();
    scannerController = null;
  }
  Future<void> processQRCode(BuildContext context, String inputData) async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Refresh lottery data first
      await lotteryController.fetchLotteries();

      // Try to parse as QR data first
      final Map<String, dynamic>? qrDataMap = _parseQrData(inputData);
      String ticketId;

      if (qrDataMap != null &&
          qrDataMap['receipt_id']?.toString().isNotEmpty == true) {
        // This is from QR code
        ticketId = qrDataMap['receipt_id']!.toString();
      } else {
        // This is manual input - use as is
        ticketId = inputData.trim();
      }
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
              TextButton(onPressed: () => Get.back(), child: Text('OK', style: TextStyle(color: Colors.white),)),
            ],
          ),
        );
        if (response['message'].contains("yet")) {
          _handlePendingResults(response);
        } else {
          CustomSnackBar.error(
            response['message'] ?? 'An unknown error occurred',
          );
        }
        return;
      }

      // Handle successful response
      _handleSuccessfulResult(response);
    } on DioException catch (e) {
      Get.back(); // Close loading dialog
      CustomSnackBar.error(
        e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.connectionError
            ? 'Please check your internet connection'
            : 'Failed to connect to server',
        title: "Network Error",
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      CustomSnackBar.error('An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePendingResults(Map<String, dynamic> response) {
    final lotteryIdStr = response['lottery_id']?.toString().trim();
    final lotteryId = int.tryParse(lotteryIdStr ?? '');

    if (lotteryId == null) {
      CustomSnackBar.error('Invalid lottery information');

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

// Updated _claimTickets method to return success status and message
  Future<Map<String, dynamic>> _claimTickets(String orderId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final userController = Get.find<UserController>();
      if (userController.currentUser.value == null) {
        Get.back();
        return {
          'success': false,
          'message': 'User not logged in'
        };
      }

      final userId = userController.currentUser.value!.id.toString();
      final response = await apiService.claimTickets(
        orderId: orderId,
        userId: userId,
      );

      Get.back(); // Close loading dialog

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Prizes claimed successfully!'
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to claim prizes'
        };
      }
    } catch (e) {
      Get.back();
      return {
        'success': false,
        'message': 'Failed to claim prizes: $e'
      };
    }
  }

// Updated _showResultsDialog method
  void _showResultsDialog(
      List<Map<String, dynamic>> ticketResults,
      Lottery lottery,
      String orderId,
      ) {
    // Filter out only winning tickets
    final winningTickets =
    ticketResults
        .where(
          (t) =>
      t['result'].resultType != ResultType.loss &&
          t['result'].resultType != ResultType.error,
    )
        .toList();

    // If no winning tickets, show a single message and return
    if (winningTickets.isEmpty) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 60, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'NO TICKET WINNING',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Better luck next time!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Auto close after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (Get.isDialogOpen!) Get.back();
      });

      return;
    }

    // For winning tickets, show them with claim/print buttons
    final RxBool isClaimed = false.obs;
    final RxString claimMessage = ''.obs;
    final RxBool showClaimError = false.obs;

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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Winning Tickets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),

              // Winning tickets list
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(Get.context!).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                    winningTickets.map((ticket) {
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

              // Buttons/Message section
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Obx(() {
                  // If there's a claim error, show error message
                  if (showClaimError.value) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[600],
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            claimMessage.value,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // If successfully claimed, show print button
                  if (isClaimed.value) {
                    return ElevatedButton(
                      onPressed: () {
                        _printResultReceipts(
                          winningTickets,
                          lottery,
                          orderId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.print, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('PRINT ALL', style: TextStyle(color: Colors.white),),
                        ],
                      ),
                    );
                  }

                  // Default state: show claim button
                  return ElevatedButton(
                    onPressed: () async {
                      // Calculate total prize amount from all winning tickets
                      final totalPrize = winningTickets.fold(0.0, (sum, ticket) =>
                      sum + (ticket['result'] as LotteryResult).prizeAmount
                      );

                      if (totalPrize >= 750) {
                        CustomSnackBar.error(
                          "Prizes 750 or greater AED must be claimed at our office with an admin",
                          duration: 4,
                        );
                        return;
                      }

                      // If prize is under 750, proceed with normal claim
                      final claimResult = await _claimTickets(orderId);

                      if (claimResult['success'] == true) {
                        isClaimed.value = true;
                        CustomSnackBar.success(claimResult['message']);
                      } else {
                        showClaimError.value = true;
                        claimMessage.value = claimResult['message'];
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('CLAIM PRIZES', style: TextStyle(color: Colors.white),),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Auto close after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (Get.isDialogOpen!) Get.back();
    });
  }

  Future<void> _printResultReceipts(
    List<Map<String, dynamic>> ticketResults,
    Lottery lottery,
    String orderId,
  ) async {
    try {
      CustomSnackBar.success(
        "Preparing receipts for printing...",
        title: "Printing",
        duration: 1,
      );

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


      // Close the dialog after printing is complete
      Get.offAll(()=> AnimatedHomeScreen());

      CustomSnackBar.success(
        "Preparing receipts for printing...",
        title: "Printing",
        duration: 1,
      );

    } catch (e) {
      CustomSnackBar.error(
        "Preparing receipts for printing...",
        title: "Printing",
        duration: 3,
      );
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
              pw.Image(pw.MemoryImage(companyLogoData), width: 100, height: 50),
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
              child: const Text('OK', style: TextStyle(color: Colors.white),),
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
      CustomSnackBar.success(
        "Preparing receipt for printing...",
        title: "Printing",
        duration: 1,
      );

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
                      width: 40,
                      height: 40,
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

      CustomSnackBar.success(
        "Receipt printed successfully...",
        title: "Printing",
        duration: 1,
      );
    } catch (e) {
      CustomSnackBar.success(
        "Error printing receipt: $e'",
        title: "Printing",
        duration: 3,
      );
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
              child: const Text('OK', style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }
}
