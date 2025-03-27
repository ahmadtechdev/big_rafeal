import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:lottery_app/widget/qr_scanner_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'controllers/user_controller.dart';
import 'login_screen_2.dart';
import 'lottery_sale.dart';
import 'utils/app_colors.dart';
import 'lottery_cards_screen_4.dart';
import '../controllers/lottery_controller.dart';

class LotteryScreen extends StatelessWidget {
  LotteryScreen({super.key});

  final LotteryController lotteryController = Get.put(LotteryController());
  final MobileScannerController scannerController = MobileScannerController();
  late final qrScannerService = QRScannerService(
    lotteryController: lotteryController,
  );

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

              if (lotteryController.lotteries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/no_lottery.png', // Add this asset to your project
                        width: 150,
                        height: 150,
                      ),
                      const SizedBox(height: 20),
                      // In the empty state widget, update the text to:
                      const Text(
                        'No Active Tickets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'There are currently no active tickets. Please check back later for new draws.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => lotteryController.refreshLotteries(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Add this check before the SingleChildScrollView
              if (lotteryController.lotteries
                  .every((lottery) => _isLotteryExpired(lottery.endDate))) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/no_lottery.png',
                        width: 150,
                        height: 150,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'All Lotteries Expired',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'All current lottery draws have ended. New tickets will be available soon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => lotteryController.refreshLotteries(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                    // Replace the lottery sections loop with this:
                    for (var lottery in lotteryController.lotteries.where((lottery) => !_isLotteryExpired(lottery.endDate)))
                      _buildLotterySection(
                        context,
                        lottery.lotteryName ?? 'Number ${lottery.numberLottery}',
                        lottery.winningPrice.toString(),
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
                  // Update this line to use the service
                  onPressed: () => qrScannerService.openQRScanner(context),
                ),
              ),
              const SizedBox(width: 16),
              // More options (with logout)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.primaryColor,
                ),
                onSelected: (value) async {
                  // Update the logout section in PopupMenuButton:
                  if (value == 'logout') {
                    Get.defaultDialog(
                      title: 'Logout',
                      middleText: 'Are you sure you want to logout?',
                      textConfirm: 'Yes',
                      textCancel: 'No',
                      confirmTextColor: Colors.white,
                      onConfirm: () async {
                        Get.back();
                        final userController = Get.find<UserController>();
                        userController.clearUser();

                        Get.snackbar(
                          'Logged Out',
                          'You have been successfully logged out',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.primaryColor.withOpacity(0.8),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );

                        // Navigate to login screen
                        Get.offAll(() => LoginScreen());
                      },
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return { 'Logout'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice.toLowerCase().replaceAll(' ', ''),
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
    // Replace the totalLotteries line with:
    int totalLotteries = lotteryController.lotteries
        .where((lottery) => !_isLotteryExpired(lottery.endDate))
        .length;

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
          // Replace the timer countdown section in _buildBanner with:
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
            child: Center(
              child: _buildNextDrawTimer(),
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
          GestureDetector(
            onTap: (){
              Get.to(() => LotteryHistoryScreen(), transition: Transition.rightToLeft,);

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
                  'Ticket Sale History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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

  bool _isLotteryExpired(String endDate) {
    try {
      final date = DateTime.parse(endDate);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false; // If date parsing fails, assume it's not expired
    }
  }

  Widget _buildNextDrawTimer() {
    return NextDrawTimer(lotteryController: lotteryController);
  }
  // Add this helper method to generate sequential numbers
  List<String> generateSequentialNumbers(int count) {
    return List.generate(count, (index) => (index + 1).toString());
  }
}


class NextDrawTimer extends StatefulWidget {
  final LotteryController lotteryController;

  const NextDrawTimer({super.key, required this.lotteryController});

  @override
  State<NextDrawTimer> createState() => _NextDrawTimerState();
}

class _NextDrawTimerState extends State<NextDrawTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeLeft();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    final upcomingLotteries = widget.lotteryController.lotteries
        .where((lottery) => !_isLotteryExpired(lottery.endDate))
        .toList();

    if (upcomingLotteries.isEmpty) {
      _timeLeft = Duration.zero;
      return;
    }

    upcomingLotteries.sort((a, b) => a.endDate.compareTo(b.endDate));
    final nextLottery = upcomingLotteries.first;
    final endDate = DateTime.parse(nextLottery.endDate);
    final now = DateTime.now();
    _timeLeft = endDate.difference(now);
  }

  bool _isLotteryExpired(String endDate) {
    try {
      final date = DateTime.parse(endDate);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) {
      return const Text(
        'Draw in progress',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Text(
      'Next Draw: ${days}d ${hours}h ${minutes}m ${seconds}s',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}