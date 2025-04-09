// qr_scanner_service.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/lottery_controller.dart';
import '../controllers/lottery_result_controller.dart';
import '../models/lottery_model.dart';
import '../utils/app_colors.dart';


class QRScannerService {
  final LotteryController lotteryController;
  final MobileScannerController scannerController = MobileScannerController();

  QRScannerService({required this.lotteryController});

  Future<void> openQRScanner(BuildContext context) async {
    // Fetch lotteries first before opening scanner
    await lotteryController.fetchLotteries();

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
                child: Stack(
                  children: [
                    // Scanner
                    MobileScanner(
                      controller: scannerController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                          // Close the scanner
                          scannerController.stop();
                          Navigator.pop(context);

                          // Process the scanned QR code
                          processQRCode(context, barcodes.first.rawValue!);
                        }
                      },
                    ),
                    // Overlay with scanning frame
                    CustomPaint(
                      size: Size(
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height,
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

  void processQRCode(BuildContext context, String qrData) async {
    try {

      final resultController = LotteryResultController.instance;

      // Parse the JSON data from QR code
      final Map<String, dynamic> qrDataMap = jsonDecode(qrData);

      final int lotteryId = qrDataMap['l'];
      final String ticketId = qrDataMap['t'];
      final int rowIndex = qrDataMap['r'];

      // Handle numbers conversion
      final String numbersString = qrDataMap['n'];
      final List<int> selectedNumbers = numbersString.split(',').map((n) => int.parse(n.trim())).toList();

      // Handle timestamp conversion
      final int timestamp = qrDataMap['d'];
      final DateTime purchaseDate = DateTime.fromMillisecondsSinceEpoch(timestamp);

      print("QR Data:");
      print("Lottery ID: $lotteryId");
      print("Ticket ID: $ticketId");
      print("Row Index: $rowIndex");
      print("Selected Numbers: $selectedNumbers");
      print("Purchase Date: $purchaseDate");

      // Find the lottery by ID
      final lottery = lotteryController.lotteries.firstWhere(
            (l) => l.id == lotteryId,
        orElse: () => throw Exception('Lottery not found'),
      );

      // Parse end date
      final DateTime endDate = DateTime.parse(lottery.endDate);
      final DateTime now = DateTime.now();

      if (now.isBefore(endDate)) {
        // Results not announced yet
        final timeLeft = endDate.difference(now);
        showPendingResultsDialog(context, timeLeft);
        return;
      }

      // Results are available - check winning numbers
      final List<String> winningNumbersStr = lottery.winningNumber.split(', ');
      final List<int> winningNumbers = winningNumbersStr.map((n) => int.parse(n)).toList();

      // Count matching numbers
      int matchCount = 0;
      for (final num in selectedNumbers) {
        if (winningNumbers.contains(num)) {
          matchCount++;
        }
      }

      // Determine prize based on match count
      String prizeAmount = '0';
      if (matchCount == selectedNumbers.length) {
        prizeAmount = lottery.winningPrice; // Full match
      } else if (matchCount >= 3) {
        // Check partial wins based on lottery model
        switch (matchCount) {
          case 3:
            prizeAmount = lottery.thirdWin;
            break;
          case 4:
            prizeAmount = lottery.fourWin;
            break;
          case 5:
            prizeAmount = lottery.fiveWin;
            break;
          case 6:
            prizeAmount = lottery.sixWin;
            break;
          case 7:
            prizeAmount = lottery.sevenWin;
            break;
          case 8:
            prizeAmount = lottery.eightWin;
            break;
          case 9:
            prizeAmount = lottery.nineWin;
            break;
          case 10:
            prizeAmount = lottery.tenWin;
            break;
          default:
            prizeAmount = '0';
        }
      }

      // Show results
      showResultDialog(
        context,
        matchCount == selectedNumbers.length, // isFullWin
        lottery,
        matchCount,
        prizeAmount,
        selectedNumbers.length,
        selectedNumbers, // Add this line to pass the selected numbers
      );
    } catch (e) {
      print('Error processing QR code: $e');
      showErrorDialog(
        context,
        'Invalid Ticket',
        'The scanned ticket is invalid or expired. Error: ${e.toString()}',
      );
    }
  }
// Add this new dialog for pending results
  void showPendingResultsDialog(BuildContext context, Duration timeLeft) {
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
                  onPressed: () => Navigator.of(context).pop(),
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
        );
      },
    );
  }

  void showResultDialog(
      BuildContext context,
      bool isFullWin,
      Lottery lottery,
      int matchCount,
      String prizeAmount,
      int totalNumbers,
      List<int> selectedNumbers,
      ) {
    final bool hasPartialWin = matchCount >= 3 && !isFullWin;

    // Get winning numbers
    final List<String> winningNumbersStr = lottery.winningNumber.split(', ');
    final List<int> winningNumbers = winningNumbersStr.map((n) => int.parse(n)).toList();

    // Get user's selected numbers (you'll need to pass these to the method)
    final List<int> selectedNumbers = []; // Replace with actual selected numbers from QR code

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
                SizedBox(
                  height: 150,
                  width: 150,
                  child: isFullWin
                      ? _buildWinnerAnimation()
                      : hasPartialWin
                      ? _buildPartialWinAnimation()
                      : _buildTryAgainAnimation(),
                ),
                const SizedBox(height: 20),
                Text(
                  isFullWin
                      ? 'JACKPOT WINNER!'
                      : hasPartialWin
                      ? 'PARTIAL WIN!'
                      : 'BETTER LUCK NEXT TIME!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isFullWin
                        ? Colors.green[600]
                        : hasPartialWin
                        ? Colors.orange[600]
                        : Colors.red[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isFullWin
                      ? 'You matched all $totalNumbers numbers!\nYou won AED ${lottery.winningPrice}!'
                      : hasPartialWin
                      ? 'You matched $matchCount out of $totalNumbers numbers!\nYou won AED $prizeAmount!'
                      : 'Try again for a chance to win big!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                // Add this section to show the numbers
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
                        final isMatched = winningNumbers.contains(number);
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isMatched ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isMatched ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              number.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isMatched ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
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
                const SizedBox(height: 24),
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
                    isFullWin || hasPartialWin ? 'CLAIM PRIZE' : 'TRY AGAIN',
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
// Add this new animation for partial wins
  Widget _buildPartialWinAnimation() {
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
              Icons.attach_money,
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