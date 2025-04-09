// controllers/lottery_result_controller.dart
import 'package:get/get.dart';
import '../models/lottery_model.dart';
import '../models/user_lottery_modal.dart';

class LotteryResultController extends GetxController {
  // Singleton instance
  static LotteryResultController get instance => Get.find();

  /// Checks if results are available for a lottery
  bool areResultsAvailable(Lottery lottery) {
    if (lottery.endDate.isEmpty) return false;

    final endDate = DateTime.tryParse(lottery.endDate);
    if (endDate == null) return false;

    return DateTime.now().isAfter(endDate);
  }

  /// Calculates the winning amount for a user lottery
  double calculateWinningAmount(UserLottery userLottery, Lottery lottery) {
    if (!areResultsAvailable(lottery)) return 0;

    // Parse the selected numbers from the user lottery
    final selectedNumbers = userLottery.selectedNumbers.split(',')
        .map((n) => int.tryParse(n.trim()) ?? 0)
        .toList();

    // Parse the winning numbers from the lottery
    final winningNumbers = lottery.winningNumber.split(', ')
        .map((n) => int.tryParse(n) ?? 0)
        .toList();

    // Count matching numbers
    int matchCount = 0;
    for (final num in selectedNumbers) {
      if (winningNumbers.contains(num)) {
        matchCount++;
      }
    }

    // Determine prize based on match count
    if (matchCount == selectedNumbers.length) {
      return double.tryParse(lottery.winningPrice) ?? 0; // Full match
    } else if (matchCount >= 3) {
      // Check partial wins based on lottery model
      switch (matchCount) {
        case 3: return double.tryParse(lottery.thirdWin) ?? 0;
        case 4: return double.tryParse(lottery.fourWin) ?? 0;
        case 5: return double.tryParse(lottery.fiveWin) ?? 0;
        case 6: return double.tryParse(lottery.sixWin) ?? 0;
        case 7: return double.tryParse(lottery.sevenWin) ?? 0;
        case 8: return double.tryParse(lottery.eightWin) ?? 0;
        case 9: return double.tryParse(lottery.nineWin) ?? 0;
        case 10: return double.tryParse(lottery.tenWin) ?? 0;
        default: return 0;
      }
    }

    return 0;
  }

  /// Determines the status of a lottery (win/loss/pending)
  LotteryStatus determineLotteryStatus(UserLottery userLottery, Lottery lottery) {
    if (!areResultsAvailable(lottery)) {
      return LotteryStatus.pending;
    }

    final winningAmount = calculateWinningAmount(userLottery, lottery);
    return winningAmount > 0 ? LotteryStatus.win : LotteryStatus.loss;
  }
}

enum LotteryStatus {
  win,
  loss,
  pending
}