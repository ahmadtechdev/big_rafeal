// lottery_cards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Alternative to qr_code_scanner
import 'utils/app_colors.dart';
import 'lottery_number_selection_screen_5.dart';
import 'controllers/lottery_controller.dart';

// Import needed for math functions
import 'dart:math' as math;

class LotteryCardsScreen extends StatelessWidget {
  final LotteryController lotteryController = Get.put(LotteryController());
  final MobileScannerController scannerController = MobileScannerController();

  LotteryCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (lotteryController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        } else if (lotteryController.lotteries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_off_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No lottery data available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: lotteryController.lotteries.length,
            itemBuilder: (context, index) {
              final lottery = lotteryController.lotteries[index];
              return _buildLotteryCard(
                context: context,
                lotteryId: lottery.id,
                title: lottery.lotteryName ?? 'Lottery Name',
                price: double.parse(lottery.purchasePrice.toString()),
                drawDate: lottery.endDate,
                prizeAmount: lottery.winningPrice.toString(),
                circleCount: lottery.numberLottery,
              );
            },
          );
        }
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textDark,
          size: 22,
        ),
        onPressed: () => Get.back(),
      ),
      title: Image.asset(
        'assets/logo.png',
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'Big Rafeal',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          );
        },
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.textDark,
            size: 22,
          ),
          onPressed: () => _openQRScanner(context),
        ),
        IconButton(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.textDark,
            size: 22,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildLotteryCard({
    required BuildContext context,
    required int lotteryId,
    required String title,
    required double price,
    required String drawDate,
    required String prizeAmount,
    required int circleCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Title and lottery numbers
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select $circleCount numbers',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AED ${price.toInt()}',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lottery numbers preview
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      circleCount > 6 ? 6 : circleCount,
                          (index) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.inputFieldBackground,
                          border: Border.all(
                            color: AppColors.inputFieldBorder,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (circleCount > 6)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.inputFieldBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${circleCount - 6}',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Draw date and prize info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Calendar icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.inputFieldBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primaryColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Draw Date: $drawDate',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.inputFieldBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.primaryColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prizeAmount,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Play button
          GestureDetector(
            onTap: () {
              Get.to(
                    () => LotteryNumberSelectionScreen(
                  lotteryId: lotteryId,
                  lotteryName: title,
                  numbersPerRow: circleCount,
                  price: price,
                ),
                transition: Transition.rightToLeft,
              );
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Play Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openQRScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
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
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
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
      _showErrorDialog(context, 'Invalid Ticket', 'The scanned ticket is invalid or expired.');
    }
  }

  void _showResultDialog(BuildContext context, bool isWinner, dynamic lottery) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
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
                // Simple animation instead of Lottie
                SizedBox(
                  height: 150,
                  width: 150,
                  child: isWinner
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber[600],
            ),
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

// Custom overlay painter for the scanner
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.borderLength,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanArea,
          Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw background with hole
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, cutoutPath),
      backgroundPaint,
    );

    // Draw corners
    final cornerSize = borderLength;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.left, scanArea.top + borderRadius)
        ..lineTo(scanArea.left, scanArea.top)
        ..lineTo(scanArea.left + cornerSize, scanArea.top),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.right - cornerSize, scanArea.top)
        ..lineTo(scanArea.right, scanArea.top)
        ..lineTo(scanArea.right, scanArea.top + cornerSize),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.right, scanArea.bottom - cornerSize)
        ..lineTo(scanArea.right, scanArea.bottom)
        ..lineTo(scanArea.right - cornerSize, scanArea.bottom),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.left + cornerSize, scanArea.bottom)
        ..lineTo(scanArea.left, scanArea.bottom)
        ..lineTo(scanArea.left, scanArea.bottom - cornerSize),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) => false;
}

// Helper class for animations
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
