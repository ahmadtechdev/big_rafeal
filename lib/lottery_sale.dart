import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/lottery_sale_controller.dart';
import '../controllers/user_controller.dart';
import '../utils/app_colors.dart';
import '../models/user_lottery_modal.dart';
import 'api_service/api_service.dart';


class LotteryHistoryScreen extends StatelessWidget {
  final LotterySaleController _saleController = Get.put(LotterySaleController());
  final UserController _userController = Get.find<UserController>();
  final ApiService _apiService = ApiService();

  LotteryHistoryScreen({super.key}) {
    _loadTickets();
  }

  void _loadTickets() {
    final userId = _userController.currentUser.value?.id ?? 0;
    if (userId > 0) {
      _saleController.loadTickets(userId);
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  bool _isToday(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      return dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day;
    } catch (e) {
      return false;
    }
  }

  Future<void> _cancelTicket(String orderId) async {
    try {
      final userId = _userController.currentUser.value?.id ?? 0;
      if (userId == 0) {
        throw 'User not logged in';
      }

      final result = await Get.defaultDialog<bool>(
        title: 'Confirm Cancellation',
        middleText: 'Are you sure you want to cancel this ticket?',
        textConfirm: 'Yes',
        textCancel: 'No',
        confirmTextColor: AppColors.textLight,
        buttonColor: AppColors.primaryColor,
        cancelTextColor: AppColors.textDark,
        onConfirm: () async {
          Get.back(result: true);
        },
        onCancel: () {
          Get.back(result: false);
        },
      );

      print("ahmad1");
      print(result);
      if (result == true) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        await _apiService.cancelTicket(orderId, userId);
        Get.back(); // Close loading dialog

        Get.snackbar(
          'Success',
          'Ticket cancelled successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        _loadTickets(); // Refresh the list
      }
    } catch (e) {
      Get.back(); // Close loading dialog if open
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  List<Widget> _buildNumberCircles(String numbersString) {
    final List<String> numbers = numbersString.split(',');
    return numbers.map((number) {
      return Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondaryColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            number.trim(),
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Today's Tickets",
          style: TextStyle(color: AppColors.textLight),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Obx(() {
                  final user = _userController.currentUser.value;
                  return Text(
                    user != null ? '${user.name}\'s Tickets' : 'Today\'s Tickets',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Text(
                  'All your today\'s tickets in one place',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_saleController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                );
              } else if (_saleController.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.primaryColor,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${_saleController.errorMessage.value}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTickets,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.textLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              } else {
                // Filter tickets to show only today's tickets
                final todayTickets = _saleController.tickets.where((ticket) =>
                    _isToday(ticket.lotteryIssueDate)).toList();

                if (todayTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 80,
                          color: AppColors.primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tickets for today',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try to sell a lottery ticket to see your history here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.textLight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Sell a Lottery Ticket'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: todayTickets.length,
                    itemBuilder: (context, index) {
                      final lottery = todayTickets[index];
                      return _buildLotteryCard(lottery, index);
                    },
                  );
                }
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLotteryCard(UserLottery lottery, int index) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: AnimatedSlide(
        offset: Offset.zero,
        duration: Duration(milliseconds: 300 + (index * 100)),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lottery.lotteryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // if (lottery.order_id != null && lottery.order_id!.isNotEmpty)
                    //   GestureDetector(
                    //     onTap: () => _cancelTicket(lottery.order_id!),
                    //     child: Container(
                    //       padding: const EdgeInsets.all(8),
                    //       decoration: BoxDecoration(
                    //         color: Colors.red.withOpacity(0.2),
                    //         shape: BoxShape.circle,
                    //       ),
                    //       child: const Icon(
                    //         Icons.delete,
                    //         color: Colors.red,
                    //         size: 20,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Purchase Date',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(lottery.lotteryIssueDate),
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Price',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AED ${lottery.purchasePrice}',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                     Text(
                      'id: ${lottery.order_id}',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selected Numbers',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _buildNumberCircles(lottery.selectedNumbers),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}