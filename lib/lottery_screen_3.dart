import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'lottery_sale.dart';
import 'utils/app_colors.dart';
import 'lottery_cards_screen_4.dart';
import '../controllers/lottery_controller.dart';

class LotteryScreen extends StatelessWidget {
  LotteryScreen({super.key});

  final LotteryController lotteryController = Get.put(LotteryController());
  final MobileScannerController scannerController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom App Bar
          _buildAppBar(context),

          // Main content
          Expanded(
            child: Obx(() {
              if (lotteryController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (lotteryController.errorMessage.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${lotteryController.errorMessage.value}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => lotteryController.refreshLotteries(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Banner
                    _buildBanner(context),

                    // Gradient buttons
                    _buildActionButtons(context),

                    // Lottery sections based on numberLottery groups
                    for (var lottery in lotteryController.lotteries)
                      _buildLotterySection(
                        context,
                        lottery.lotteryName ??
                            'Number ${lottery.numberLottery}',
                        lottery.winningPrice
                            .toString(), // Replace with actual price if available in your model
                        lottery.numberLottery,
                        generateSequentialNumbers(lottery.numberLottery),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Helper method to get lottery numbers for a specific lottery type
  List<String> getLotteryNumbers(String numberLottery) {
    final filteredLotteries = lotteryController.getLotteriesByNumberLottery(
      numberLottery,
    );
    if (filteredLotteries.isEmpty) return [];

    // Get the most recent lottery of this type (assuming sorted by id)
    final latestLottery = filteredLotteries.reduce(
      (a, b) => a.id > b.id ? a : b,
    );

    // Parse the winning numbers
    return latestLottery.winningNumber.split(', ');
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Container(
            height: 40,
            width: 100,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          Row(
            children: [
              // Refresh button
              GestureDetector(
                onTap: () => lotteryController.refreshLotteries(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // QR Code scanner
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                  onPressed: () => _openQRScanner(context),
                ),
              ),
              const SizedBox(width: 16),
              // More options (with logout)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.primaryColor,
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    // Handle logout logic here
                    Get.snackbar(
                      'Logout',
                      'Logging out...',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.primaryColor.withOpacity(0.8),
                      colorText: Colors.white,
                    );
                    // Implement actual logout functionality here
                  }else if(value == 'lottery'){
                    Get.to(()=> LotteryHistoryScreen());
                  }
                },
                itemBuilder: (BuildContext context) {
                  return {'lottery','Logout'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice.toLowerCase(),
                      child: Text(choice),
                    );
                  }).toList();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    // Get the total number of lotteries
    int totalLotteries = lotteryController.lotteries.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.8),
            AppColors.secondaryColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Prize showcase
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                // Prize info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Jackpot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AED',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lotteryController.lotteries[0].winningPrice
                                .toString(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalLotteries Active Lotteries',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Winner illustration or placeholder
                Expanded(
                  flex: 2,
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.emoji_events,
                                size: 50,
                                color: Colors.amber[300],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Timer countdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Text(
                'Next Draw: 4d 12h 30m 15s',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Play button
          GestureDetector(
            onTap: () {
              Get.to(
                () => LotteryCardsScreen(),
                transition: Transition.rightToLeft,
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Prize Details button
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Prize Details',
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
    );
  }

  Widget _buildLotterySection(
    BuildContext context,
    String title,
    String amount,
    int circleCount,
    List<String> numbers,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'AED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Numbers display
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Numbers:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    circleCount,
                    (index) => TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                numbers.length > index
                                    ? numbers[index]
                                    : (index + 1).toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Play button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InkWell(
              onTap: () {
                Get.to(
                  () => LotteryCardsScreen(),
                  transition: Transition.rightToLeft,
                );
              },
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'Play Now',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method to generate sequential numbers
  List<String> generateSequentialNumbers(int count) {
    return List.generate(count, (index) => (index + 1).toString());
  }

  void _openQRScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
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
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MobileScanner(
                      controller: scannerController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty &&
                            barcodes.first.rawValue != null) {
                          // Close the scanner
                          scannerController.stop();
                          Navigator.pop(context);

                          // Process the scanned QR code
                          _processQRCode(context, barcodes.first.rawValue!);
                        }
                      },
                      // overlayBuilder: CustomPaint(
                      //   painter: ScannerOverlayPainter(
                      //     borderColor: AppColors.primaryColor,
                      //     borderRadius: 10,
                      //     borderLength: 30,
                      //     borderWidth: 10,
                      //     cutOutSize: MediaQuery.of(context).size.width * 0.7,
                      //   ),
                      // ),
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

  void _processQRCode(BuildContext context, String qrData) {
    try {
      // Parse QR data in format "lotteryId_BIGR{lotteryCode}"
      final parts = qrData.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid QR code format');
      }

      final lotteryId = int.parse(parts[0]);
      final ticketId = parts[1];

      // Find the lottery by ID
      final lottery = lotteryController.lotteries.firstWhere(
        (l) => l.id == lotteryId,
        orElse: () => throw Exception('Lottery not found'),
      );

      // In a real app, you would check with the backend if the ticket is a winner
      // For this example, we'll generate a random result
      final bool isWinner = DateTime.now().millisecondsSinceEpoch % 2 == 0;

      // Show result dialog with animation
      _showResultDialog(context, isWinner, lottery);
    } catch (e) {
      print('Error processing QR code: $e');
      _showErrorDialog(
        context,
        'Invalid Ticket',
        'The scanned ticket is invalid or expired.',
      );
    }
  }

  void _showResultDialog(BuildContext context, bool isWinner, dynamic lottery) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
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
                // Simple animation instead of Lottie
                SizedBox(
                  height: 150,
                  width: 150,
                  child:
                      isWinner
                          ? _buildWinnerAnimation()
                          : _buildTryAgainAnimation(),
                ),
                const SizedBox(height: 20),
                // Result text
                Text(
                  isWinner ? 'CONGRATULATIONS!' : 'BETTER LUCK NEXT TIME!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isWinner
                      ? 'You won AED ${lottery.winningPrice}!'
                      : 'Don\'t give up! Try again for a chance to win big!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                  child: Text(
                    isWinner ? 'CLAIM PRIZE' : 'TRY AGAIN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              return Positioned(
                left: 75 + math.cos(angle) * 50 * value,
                top: 75 + math.sin(angle) * 50 * value,
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

  void _showErrorDialog(BuildContext context, String title, String message) {
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

class _TickerProviderImpl extends TickerProvider {
  const _TickerProviderImpl();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

// Extension to add missing functions
extension MathFunctions on num {
  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);
}
