import 'package:get/get.dart';

import '../api_service/api_service.dart';
import '../controllers/lottery_controller.dart';
import '../controllers/user_controller.dart';
import '../models/lottery_model.dart';
import '../models/user_lottery_modal.dart';
import 'lottery_result_controller.dart';

class SalesReportController extends GetxController {
  final ApiService _apiService = ApiService();
  final UserController _userController = Get.put(UserController());
  final LotteryController _lotteryController = Get.put(LotteryController());

  // Observable variables for reactive UI updates
  final startDate = DateTime.now().subtract(const Duration(days: 10)).obs;
  final endDate = DateTime.now().obs;
  final totalSales = 0.0.obs;
  final totalWinnings = 0.0.obs;
  final userCommission = 0.0.obs;
  final payableToAdmin = 0.0.obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final RxList<UserLottery> filteredLotteries = <UserLottery>[].obs;



  @override
  void onInit() {
    super.onInit();
    loadLotteries();
  }

  void loadLotteries() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    final userId = _userController.currentUser.value?.id ?? 0;
    if (userId <= 0) {
      hasError.value = true;
      errorMessage.value = 'User not logged in';
      isLoading.value = false;
      return;
    }

    try {
      final lotteries = await _apiService.fetchUserLotteries(userId);
      _filterAndCalculateTotals(lotteries);
      isLoading.value = false;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

// In sale_report_controller.dart
// Add this at the top with other imports

// Then modify the _filterAndCalculateTotals method:
  void _filterAndCalculateTotals(List<UserLottery> userLotteries) {
    final resultController = LotteryResultController.instance;

    // Filter lotteries within date range
    filteredLotteries.value = userLotteries.where((lottery) {
      try {
        final purchaseDate = DateTime.parse(lottery.lotteryIssueDate);
        return purchaseDate.isAfter(startDate.value) &&
            purchaseDate.isBefore(endDate.value.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    double sales = 0.0;
    double winnings = 0.0;

    // Calculate totals
    for (var userLottery in filteredLotteries) {
      // Add to sales total
      final salePrice = double.tryParse(userLottery.purchasePrice) ?? 0;
      sales += salePrice;

      // Find corresponding lottery
      final lottery = findMatchingLottery(userLottery);

      // Only calculate winnings if results are announced
      if (resultController.areResultsAvailable(lottery)) {
        final result = resultController.checkLotteryResult(userLottery, lottery);
        winnings += result.prizeAmount;
      }
    }

    // Update observable variables
    totalSales.value = sales;
    totalWinnings.value = winnings;

    // Calculate commission (25% of net sales)
    final netSales = sales - winnings;
    userCommission.value = totalSales * 0.15;
    payableToAdmin.value = netSales - userCommission.value;
  }

// You can remove the calculateWinningAmount method since it's now in LotteryResultController
  // Helper method to properly find matching lottery by ID
  Lottery findMatchingLottery(UserLottery userLottery) {
    // First try matching by lotteryId directly
    var lottery = _lotteryController.lotteries.firstWhereOrNull(
            (l) => l.lotteryId == userLottery.lotteryId
    );


    lottery ??= _lotteryController.lotteries.firstWhereOrNull(
            (l) => l.lotteryCode == userLottery.lotteryCode
    );

    // If not found, try matching by id as string
    lottery ??= _lotteryController.lotteries.firstWhereOrNull(
              (l) => l.id.toString() == userLottery.id.toString()
      );

    // If still not found, return default empty lottery
    return lottery ?? Lottery(
      id: 0,
      lotteryId: '',
      numberLottery: 0,
      digits: '',
      startDate: '',
      endDate: '',
      winningNumber: '',
      createdAt: '',
      updatedAt: '',
      lotteryName: '',
      purchasePrice: '0',

      lotteryCode: '',
      image: '',

      lotteryCategory: '0',
    );
  }

  // double calculateWinningAmount(UserLottery userLottery, Lottery lottery) {
  //   try {
  //     // Parse selected numbers
  //     final List<String> selectedNumbersStr = userLottery.selectedNumbers.split(',');
  //     final List<int> selectedNumbers = selectedNumbersStr.map((n) => int.parse(n.trim())).toList();
  //
  //     // Parse winning numbers
  //     final List<String> winningNumbersStr = lottery.winningNumber.split(', ');
  //     final List<int> winningNumbers = winningNumbersStr.map((n) => int.parse(n.trim())).toList();
  //
  //     // Count matching numbers
  //     int matchCount = 0;
  //     for (final num in selectedNumbers) {
  //       if (winningNumbers.contains(num)) {
  //         matchCount++;
  //       }
  //     }
  //
  //     // Determine prize based on match count
  //     if (matchCount == selectedNumbers.length) {
  //       return double.parse(lottery.winningPrice); // Full match
  //     } else if (matchCount >= 3) {
  //       // Check partial wins based on lottery model
  //       switch (matchCount) {
  //         case 3:
  //           return double.parse(lottery.thirdWin);
  //         case 4:
  //           return double.parse(lottery.fourWin);
  //         case 5:
  //           return double.parse(lottery.fiveWin);
  //         case 6:
  //           return double.parse(lottery.sixWin);
  //         case 7:
  //           return double.parse(lottery.sevenWin);
  //         case 8:
  //           return double.parse(lottery.eightWin);
  //         case 9:
  //           return double.parse(lottery.nineWin);
  //         case 10:
  //           return double.parse(lottery.tenWin);
  //         default:
  //           return 0;
  //       }
  //     }
  //     return 0;
  //   } catch (e) {
  //     print('Error calculating winning amount: $e');
  //     return 0;
  //   }
  // }
}