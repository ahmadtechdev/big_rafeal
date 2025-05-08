// lottery_cards_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_app/widget/qr_scanner_service.dart';
// Alternative to qr_code_scanner
import 'models/lottery_model.dart';
import 'utils/app_colors.dart';
import 'lottery_number_selection_screen_5.dart';
import 'controllers/lottery_controller.dart';

// Import needed for math functions

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
          // Update the ListView.builder section in the build method
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: lotteryController.lotteries.length,
            itemBuilder: (context, index) {
              try {
                final sortedLotteries = _getSortedLotteries(lotteryController.lotteries);
                final lottery = sortedLotteries[index];

                // Add null checks and default values for everything
                return _buildLotteryCard(
                  context: context,
                  lotteryId: lottery.id,
                  title: lottery.lotteryName.isNotEmpty ? lottery.lotteryName : 'Lottery',
                  price: double.tryParse(lottery.purchasePrice.toString()) ?? 0.0,
                  drawDate: lottery.endDate.isNotEmpty ? lottery.endDate : 'TBD',
                  prizeAmount: lottery.highestPrize.toString(),
                  circleCount: lottery.numberLottery > 0 ? lottery.numberLottery : 1,
                  maxNumbers: int.tryParse(lottery.digits) ?? 9,
                  image: lottery.image,
                  lotteryCategory: lottery.lotteryCategory,
                  announcedResult: lottery.announcedResult,
                );
              } catch (e) {
                // Fallback widget if there's any error
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'Error loading lottery card',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
            },
          );
        }
      }),
    );
  }

  List<Lottery> _getSortedLotteries(List<Lottery> lotteries) {
    return lotteries.toList()
      ..sort((a, b) {
        final aExpired = _isLotteryExpired(a);
        final bExpired = _isLotteryExpired(b);

        // If both are active or both are expired, sort by end date
        if (aExpired == bExpired) {
          return DateTime.parse(a.endDate).compareTo(DateTime.parse(b.endDate));
        }
        // Active cards come before expired cards
        return aExpired ? 1 : -1;
      });
  }

  // New method to check if lottery is expired based on announcedResult
  bool _isLotteryExpired(Lottery lottery) {
    // Check if announcedResult is '1', which means the lottery is expired
    if (lottery.announcedResult == '1') {
      return true;
    }
    return false;
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
    required int maxNumbers,
    String? image,
    String? lotteryCategory,
    String? announcedResult,
  }) {
    // Convert lottery category to readable string
    String getCategoryName(String? category) {
      switch (category) {
        case '0':
          return 'Straight';
        case '1':
          return 'Rumble';
        case '2':
          return 'Chance';
        case '3':
          return 'All';
        default:
          return 'Unknown';
      }
    }

    // Get color for category tag
    Color getCategoryColor(String? category) {
      switch (category) {
        case '0':
          return Colors.blue;
        case '1':
          return Colors.orange;
        case '2':
          return Colors.green;
        case '3':
          return AppColors.secondaryColor;
        default:
          return Colors.grey;
      }
    }

    // Check if lottery is expired based on announcedResult
    final bool isExpired = announcedResult == '1';
    final String categoryName = getCategoryName(lotteryCategory ?? '0');
    final Color categoryColor = getCategoryColor(lotteryCategory ?? '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Header with image background if available
          Stack(
            children: [
              // Background gradient or image
              Container(
                height: 90, // Reduced height
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                // Only try to display image if it's not null or empty
                // child: (image != null && image.isNotEmpty)
                //     ? ClipRRect(
                //   borderRadius: const BorderRadius.only(
                //     topLeft: Radius.circular(12),
                //     topRight: Radius.circular(12),
                //   ),
                //   child: Image.network(
                //     image,
                //     fit: BoxFit.cover,
                //     errorBuilder: (context, error, stackTrace) {
                //       return const SizedBox.shrink();
                //     },
                //   ),
                // )
                //     : null,
              ),

              // Header content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with category tag and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),

                        // Price tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AED ${price.toInt()}',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Lottery title and description
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Select $circleCount numbers',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Expired badge if applicable
              if (isExpired)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EXPIRED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Lottery numbers preview
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      circleCount > 6 ? 6 : circleCount,
                          (index) => Container(
                        width: 28,
                        height: 28,
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (circleCount > 6)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFieldBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${circleCount - 6}',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Draw date and prize info (more compact layout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // Calendar info
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.inputFieldBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primaryColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          drawDate,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Prize info
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.inputFieldBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.primaryColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          prizeAmount,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Play button (more compact)
          GestureDetector(
            onTap: () {
              if (isExpired) {
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
                    endDate: drawDate,
                    maxNumber: maxNumbers,
                        announcedResult: announcedResult,
                  ),
                  transition: Transition.rightToLeft,
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isExpired
                    ? LinearGradient(colors: [Colors.grey, Colors.grey.shade600])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isExpired
                        ? Colors.grey.withOpacity(0.2)
                        : AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpired ? 'Expired' : 'Play Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (!isExpired) const SizedBox(width: 6),
                  if (!isExpired)
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}