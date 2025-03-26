// lottery_cards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:lottery_app/widget/qr_scanner_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Alternative to qr_code_scanner
import 'utils/app_colors.dart';
import 'lottery_number_selection_screen_5.dart';
import 'controllers/lottery_controller.dart';

// Import needed for math functions
import 'dart:math' as math;

class LotteryCardsScreen extends StatelessWidget {
  final LotteryController lotteryController = Get.put(LotteryController());
  late final qrScannerService = QRScannerService(
    lotteryController: lotteryController,
  );

  LotteryCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (lotteryController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
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
          // Update this line to use the service
          onPressed: () => qrScannerService.openQRScanner(context),
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
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
          // Then modify the GestureDetector for the Play button:
          GestureDetector(
            onTap: () {
              if (_isDatePassed(drawDate)) {
                Get.snackbar(
                  'Expired Lottery',
                  'This lottery draw has ended and cannot be played',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } else {
                Get.to(
                      () => LotteryNumberSelectionScreen(
                    lotteryId: lotteryId,
                    lotteryName: title,
                    numbersPerRow: circleCount,
                    price: price,
                    endDate: drawDate, // Add this parameter
                  ),
                  transition: Transition.rightToLeft,
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: _isDatePassed(drawDate)
                    ? LinearGradient(colors: [Colors.grey, Colors.grey.shade600])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _isDatePassed(drawDate)
                        ? Colors.grey.withOpacity(0.3)
                        : AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isDatePassed(drawDate) ? 'Expired' : 'Play Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (!_isDatePassed(drawDate)) const SizedBox(width: 8),
                  if (!_isDatePassed(drawDate))
                    const Icon(
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

  // Add this helper method to check if date has passed
  bool _isDatePassed(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false; // If date parsing fails, assume it's not passed
    }
  }
}
