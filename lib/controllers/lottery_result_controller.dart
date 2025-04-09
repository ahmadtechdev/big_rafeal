import 'package:get/get.dart';
import '../models/lottery_model.dart';
import '../models/user_lottery_modal.dart';

class LotteryResultController extends GetxController {
  static LotteryResultController get instance => Get.find();

  // Centralized method to check lottery results
  LotteryResult checkLotteryResult(UserLottery userLottery, Lottery lottery) {
    try {
      // Parse selected numbers
      final List<String> selectedNumbersStr = userLottery.selectedNumbers.split(',');
      final List<int> selectedNumbers = selectedNumbersStr.map((n) => int.parse(n.trim())).toList();

      // Parse winning numbers
      final List<String> winningNumbersStr = lottery.winningNumber.split(', ');
      final List<int> winningNumbers = winningNumbersStr.map((n) => int.parse(n.trim())).toList();

      // Check for sequence match (exact order) - applies to all lotteries
      int sequenceMatchCount = 0;
      for (int i = 0; i < selectedNumbers.length; i++) {
        if (selectedNumbers[i] == winningNumbers[i]) {
          sequenceMatchCount++;
        } else {
          break; // Sequence must be consecutive from start
        }
      }

      // Check for full sequence match
      if (sequenceMatchCount == selectedNumbers.length) {
        return LotteryResult(
          resultType: ResultType.fullWin,
          matchCount: sequenceMatchCount,
          prizeAmount: double.parse(lottery.winningPrice),
          selectedNumbers: selectedNumbers,
          winningNumbers: winningNumbers,
          isSequenceMatch: true,
        );
      }

      // Handle sequence matches (for all lotteries)
      // In the checkLotteryResult method, modify the sequence match section:
      if (sequenceMatchCount >= 3) {
        double? sequencePrize;
        switch (sequenceMatchCount) {
          case 3:
            sequencePrize = double.tryParse(lottery.thirdMatchSequence ?? '0');
            break;
          case 4:
            sequencePrize = double.tryParse(lottery.fourMatchSequence ?? '0');
            break;
          case 5:
            sequencePrize = double.tryParse(lottery.fiveMatchSequence ?? '0');
            break;
          case 6:
            sequencePrize = double.tryParse(lottery.sixMatchSequence ?? '0');
            break;
          case 7:
            sequencePrize = double.tryParse(lottery.sevenMatchSequence ?? '0');
            break;
          case 8:
            sequencePrize = double.tryParse(lottery.eightMatchSequence ?? '0');
            break;
          case 9:
            sequencePrize = double.tryParse(lottery.nineMatchSequence ?? '0');
            break;
          case 10:
            sequencePrize = double.tryParse(lottery.tenMatchSequence ?? '0');
            break;
        }

        if (sequencePrize != null && sequencePrize > 0) {
          return LotteryResult(
            resultType: ResultType.sequenceWin,
            matchCount: sequenceMatchCount,
            prizeAmount: sequencePrize,
            selectedNumbers: selectedNumbers,
            winningNumbers: winningNumbers,
            isSequenceMatch: true,
          );
        }
      }
      // Special handling for 6-digit lotteries (rumble matches)
      if (selectedNumbers.length == 6) {
        // Count matching numbers regardless of position
        int rumbleMatchCount = 0;
        for (final num in selectedNumbers) {
          if (winningNumbers.contains(num)) {
            rumbleMatchCount++;
          }
        }

        // Determine prize based on rumble match count
        if (rumbleMatchCount >= 3) {
          double? rumblePrize;
          switch (rumbleMatchCount) {
            case 3:
              rumblePrize = double.tryParse(lottery.thirdWin ?? '0');
              break;
            case 4:
              rumblePrize = double.tryParse(lottery.fourWin ?? '0');
              break;
            case 5:
              rumblePrize = double.tryParse(lottery.fiveWin ?? '0');
              break;
            case 6:
              rumblePrize = double.tryParse(lottery.sixWin ?? '0');
              break;
          }

          if (rumblePrize != null && rumblePrize > 0) {
            return LotteryResult(
              resultType: ResultType.partialWin,
              matchCount: rumbleMatchCount,
              prizeAmount: rumblePrize,
              selectedNumbers: selectedNumbers,
              winningNumbers: winningNumbers,
              isSequenceMatch: false,
            );
          }
        }
      }

      // If no matches found
      return LotteryResult(
        resultType: ResultType.loss,
        matchCount: 0,
        prizeAmount: 0,
        selectedNumbers: selectedNumbers,
        winningNumbers: winningNumbers,
        isSequenceMatch: false,
      );
    } catch (e) {
      print('Error checking lottery result: $e');
      return LotteryResult(
        resultType: ResultType.error,
        matchCount: 0,
        prizeAmount: 0,
        selectedNumbers: [],
        winningNumbers: [],
        isSequenceMatch: false,
      );
    }
  }

  // Helper method to check if results are available
  bool areResultsAvailable(Lottery lottery) {
    if (lottery.endDate.isEmpty) return false;

    final endDate = DateTime.tryParse(lottery.endDate);
    if (endDate == null) return false;

    return DateTime.now().isAfter(endDate);
  }
}

enum ResultType {
  fullWin,        // All numbers matched in exact sequence
  sequenceWin,    // Partial sequence match (3+ numbers from start)
  partialWin,     // Rumble match (6-digit lotteries only)
  loss,           // No match
  pending,        // Results not yet available
  error,          // Error occurred during checking
}

class LotteryResult {
  final ResultType resultType;
  final int matchCount;
  final double prizeAmount;
  final List<int> selectedNumbers;
  final List<int> winningNumbers;
  final bool isSequenceMatch; // True if this was a sequence match

  LotteryResult({
    required this.resultType,
    required this.matchCount,
    required this.prizeAmount,
    required this.selectedNumbers,
    required this.winningNumbers,
    required this.isSequenceMatch,
  });
}