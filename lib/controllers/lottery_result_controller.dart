import 'package:get/get.dart';
import '../models/lottery_model.dart';
import '../models/user_lottery_modal.dart';

class LotteryResultController extends GetxController {
  static LotteryResultController get instance => Get.find();

  LotteryResult checkLotteryResult(UserLottery userLottery, Lottery lottery) {
    try {
      // Parse selected numbers
      final List<String> selectedNumbersStr = userLottery.selectedNumbers.split(',');
      final List<int> selectedNumbers = selectedNumbersStr.map((n) => int.parse(n.trim())).toList();

      // Parse winning numbers
      final List<String> winningNumbersStr = lottery.winningNumber.split(',');
      final List<int> winningNumbers = winningNumbersStr.map((n) => int.parse(n.trim())).toList();

      // Determine lottery category
      final int category = int.tryParse(lottery.lotteryCategory) ?? 0;

      // Category-specific checks
      switch (category) {
        case 0: // Sequence Match only
          return _checkSequenceMatch(selectedNumbers, winningNumbers, lottery);
        case 1: // Rumble Match only
          return _checkRumbleMatch(selectedNumbers, winningNumbers, lottery);
        case 2: // Chance Match only
          return _checkChanceMatch(selectedNumbers, winningNumbers, lottery);
        case 3: // All - check all types and return best match
          return _checkAllMatches(selectedNumbers, winningNumbers, lottery);
        default:
          return _noMatchResult(selectedNumbers, winningNumbers);
      }
    } catch (e) {
      return _errorResult();
    }
  }

  LotteryResult _checkAllMatches(
      List<int> selectedNumbers,
      List<int> winningNumbers,
      Lottery lottery
      ) {
    // Check all match types
    final sequenceResult = _checkSequenceMatch(selectedNumbers, winningNumbers, lottery);
    final chanceResult = _checkChanceMatch(selectedNumbers, winningNumbers, lottery);
    final rumbleResult = _checkRumbleMatch(selectedNumbers, winningNumbers, lottery);

    // Collect all winning results
    final List<LotteryResult> winningResults = [];
    if (sequenceResult.resultType != ResultType.loss) winningResults.add(sequenceResult);
    if (chanceResult.resultType != ResultType.loss) winningResults.add(chanceResult);
    if (rumbleResult.resultType != ResultType.loss) winningResults.add(rumbleResult);

    // If no wins, return loss
    if (winningResults.isEmpty) return _noMatchResult(selectedNumbers, winningNumbers);

    // Find the result with highest prize
    winningResults.sort((a, b) => b.prizeAmount.compareTo(a.prizeAmount));
    final bestResult = winningResults.first;

    // Check for combined matches (Sequence+Rumble or Chance+Rumble)
    if (bestResult.resultType == ResultType.sequenceWin ||
        bestResult.resultType == ResultType.chanceWin) {
      // If we have a sequence or chance win, check if rumble gives better prize
      if (rumbleResult.resultType != ResultType.loss &&
          rumbleResult.prizeAmount > bestResult.prizeAmount) {
        return rumbleResult;
      }
    }

    return bestResult;
  }

  LotteryResult _noMatchResult(List<int> selectedNumbers, List<int> winningNumbers) {
    return LotteryResult(
      resultType: ResultType.loss,
      matchCount: 0,
      prizeAmount: 0,
      selectedNumbers: selectedNumbers,
      winningNumbers: winningNumbers,
      isSequenceMatch: false,
      isChanceMatch: false,
      isRumbleMatch: false,
    );
  }

  LotteryResult _errorResult() {
    return LotteryResult(
      resultType: ResultType.error,
      matchCount: 0,
      prizeAmount: 0,
      selectedNumbers: [],
      winningNumbers: [],
      isSequenceMatch: false,
      isChanceMatch: false,
      isRumbleMatch: false,
    );
  }
  // Check for sequence match (exact order from start)
  LotteryResult _checkSequenceMatch(List<int> selectedNumbers, List<int> winningNumbers, Lottery lottery) {
    int sequenceMatchCount = 0;

    // Count consecutive matches from the start
    for (int i = 0; i < selectedNumbers.length && i < winningNumbers.length; i++) {
      if (selectedNumbers[i] == winningNumbers[i]) {
        sequenceMatchCount++;
      } else {
        break; // Sequence must be consecutive from start
      }
    }

    // Minimum 3 matches required (unless specified differently)
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
          isChanceMatch: false,
          isRumbleMatch: false,
        );
      }
    }

    // No sequence match
    return LotteryResult(
      resultType: ResultType.loss,
      matchCount: 0,
      prizeAmount: 0,
      selectedNumbers: selectedNumbers,
      winningNumbers: winningNumbers,
      isSequenceMatch: false,
      isChanceMatch: false,
      isRumbleMatch: false,
    );
  }

  // Check for chance match (reverse order from end)
  LotteryResult _checkChanceMatch(List<int> selectedNumbers, List<int> winningNumbers, Lottery lottery) {
    int chanceMatchCount = 0;

    // Count consecutive matches from the end in reverse order
    for (int i = 0; i < selectedNumbers.length && i < winningNumbers.length; i++) {
      int selectedIndex = selectedNumbers.length - 1 - i;
      int winningIndex = winningNumbers.length - 1 - i;

      if (selectedIndex >= 0 && winningIndex >= 0 &&
          selectedNumbers[selectedIndex] == winningNumbers[winningIndex]) {
        chanceMatchCount++;
      } else {
        break; // Chance must be consecutive from end in reverse
      }
    }

    // For chance, even 1 match counts
    if (chanceMatchCount >= 1) {
      double? chancePrize;
      switch (chanceMatchCount) {
        case 1:
          chancePrize = double.tryParse(lottery.firstMatchChance ?? '0');
          break;
        case 2:
          chancePrize = double.tryParse(lottery.secondMatchChance ?? '0');
          break;
        case 3:
          chancePrize = double.tryParse(lottery.thirdMatchChance ?? '0');
          break;
        case 4:
          chancePrize = double.tryParse(lottery.fourMatchChance ?? '0');
          break;
        case 5:
          chancePrize = double.tryParse(lottery.fiveMatchChance ?? '0');
          break;
        case 6:
          chancePrize = double.tryParse(lottery.sixMatchChance ?? '0');
          break;
        case 7:
          chancePrize = double.tryParse(lottery.sevenMatchChance ?? '0');
          break;
        case 8:
          chancePrize = double.tryParse(lottery.eightMatchChance ?? '0');
          break;
        case 9:
          chancePrize = double.tryParse(lottery.nineMatchChance ?? '0');
          break;
        case 10:
          chancePrize = double.tryParse(lottery.tenMatchChance ?? '0');
          break;
      }

      if (chancePrize != null && chancePrize > 0) {
        return LotteryResult(
          resultType: ResultType.chanceWin,
          matchCount: chanceMatchCount,
          prizeAmount: chancePrize,
          selectedNumbers: selectedNumbers,
          winningNumbers: winningNumbers,
          isSequenceMatch: false,
          isChanceMatch: true,
          isRumbleMatch: false,
        );
      }
    }

    // No chance match
    return LotteryResult(
      resultType: ResultType.loss,
      matchCount: 0,
      prizeAmount: 0,
      selectedNumbers: selectedNumbers,
      winningNumbers: winningNumbers,
      isSequenceMatch: false,
      isChanceMatch: false,
      isRumbleMatch: false,
    );
  }

  // Check for rumble match (any order, anywhere)
  LotteryResult _checkRumbleMatch(List<int> selectedNumbers, List<int> winningNumbers, Lottery lottery) {
    // Create a frequency map of winning numbers
    final winningNumberFrequency = <int, int>{};
    for (final num in winningNumbers) {
      winningNumberFrequency[num] = (winningNumberFrequency[num] ?? 0) + 1;
    }

    int rumbleMatchCount = 0;
    // Create a copy of the frequency map to decrement as we count matches
    final availableWinningNumbers = Map<int, int>.from(winningNumberFrequency);

    for (final num in selectedNumbers) {
      if (availableWinningNumbers.containsKey(num) && availableWinningNumbers[num]! > 0) {
        rumbleMatchCount++;
        availableWinningNumbers[num] = availableWinningNumbers[num]! - 1;
      }
    }

    if (rumbleMatchCount >= 3) {
      double? rumblePrize;
      switch (rumbleMatchCount) {
        case 3:
          rumblePrize = double.tryParse(lottery.thirdMatchRamble ?? '0');
          break;
        case 4:
          rumblePrize = double.tryParse(lottery.fourMatchRamble ?? '0');
          break;
        case 5:
          rumblePrize = double.tryParse(lottery.fiveMatchRamble ?? '0');
          break;
        case 6:
          rumblePrize = double.tryParse(lottery.sixMatchRamble ?? '0');
          break;
        case 7:
          rumblePrize = double.tryParse(lottery.sevenMatchRamble ?? '0');
          break;
        case 8:
          rumblePrize = double.tryParse(lottery.eightMatchRamble ?? '0');
          break;
        case 9:
          rumblePrize = double.tryParse(lottery.nineMatchRamble ?? '0');
          break;
        case 10:
          rumblePrize = double.tryParse(lottery.tenMatchRamble ?? '0');
          break;
      }

      if (rumblePrize != null && rumblePrize > 0) {
        return LotteryResult(
          resultType: ResultType.rumbleWin,
          matchCount: rumbleMatchCount,
          prizeAmount: rumblePrize,
          selectedNumbers: selectedNumbers,
          winningNumbers: winningNumbers,
          isSequenceMatch: false,
          isChanceMatch: false,
          isRumbleMatch: true,
        );
      }
    }

    // No rumble match
    return LotteryResult(
      resultType: ResultType.loss,
      matchCount: 0,
      prizeAmount: 0,
      selectedNumbers: selectedNumbers,
      winningNumbers: winningNumbers,
      isSequenceMatch: false,
      isChanceMatch: false,
      isRumbleMatch: false,
    );
  }

  // Helper method to check if results are available
  bool areResultsAvailable(Lottery lottery) {
    if (lottery.endDate.isEmpty) return false;

    final endDate = DateTime.tryParse(lottery.endDate);
    if (endDate == null) return false;

    // Check if announced result is set to 1
    if (lottery.announcedResult == '1') {
      return true;
    }

    return DateTime.now().isAfter(endDate);
  }
}

enum ResultType {
  fullWin,        // All numbers matched in exact sequence
  sequenceWin,    // Partial sequence match (3+ numbers from start)
  chanceWin,      // Reverse sequence match (from the end)
  rumbleWin,      // Any order match (previously partialWin)
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
  final bool isChanceMatch;   // True if this was a chance match
  final bool isRumbleMatch;   // True if this was a rumble match

  LotteryResult({
    required this.resultType,
    required this.matchCount,
    required this.prizeAmount,
    required this.selectedNumbers,
    required this.winningNumbers,
    required this.isSequenceMatch,
    required this.isChanceMatch,
    required this.isRumbleMatch,
  });
}