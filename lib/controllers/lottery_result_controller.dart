import 'package:get/get.dart';
import '../api_service/api_service.dart';
import '../models/lottery_model.dart';
import '../models/user_lottery_modal.dart';

class LotteryResultController extends GetxController {
  static LotteryResultController get instance => Get.find();

  Future<LotteryResult> checkLotteryResult(UserLottery userLottery, Lottery lottery) async {
    try {
      // Parse selected numbers
      final List<String> selectedNumbersStr = userLottery.selectedNumbers.split(',');
      final List<int> selectedNumbers = selectedNumbersStr.map((n) => int.parse(n.trim())).toList();

      // In the new flow, we just need to call the API with the ticket ID
      // The server will handle all the matching logic
      final apiService = Get.find<ApiService>();
      final response = await apiService.checkTicketResult(userLottery.ticketId);

      if (response['success'] == true) {
        return _parseApiResponse(response, selectedNumbers);
      } else {
        return _errorResult(response['message'] ?? 'Failed to check result');
      }
    } catch (e) {
      return _errorResult(e.toString());
    }
  }

  LotteryResult _parseApiResponse(Map<String, dynamic> response, List<int> selectedNumbers) {
    // Parse winning numbers from response
    final List<int> winningNumbers = (response['winning_numbers'] as List)
        .map((n) => int.parse(n.toString()))
        .toList();

    return LotteryResult(
      resultType: _parseResultType(response),
      matchCount: response['matched_numbers'] ?? 0,
      prizeAmount: double.tryParse(response['win_amount']?.toString() ?? '0') ?? 0,
      selectedNumbers: selectedNumbers,
      winningNumbers: winningNumbers,
      isSequenceMatch: response['isSequenceMatch'] ?? false,
      isChanceMatch: response['isChanceMatch'] ?? false,
      isRumbleMatch: response['isRumbleMatch'] ?? false,
    );
  }

  ResultType _parseResultType(Map<String, dynamic> response) {
    if (response['isFullWin'] == true) return ResultType.fullWin;
    if (response['isSequenceMatch'] == true) return ResultType.sequenceWin;
    if (response['isChanceMatch'] == true) return ResultType.chanceWin;
    if (response['isRumbleMatch'] == true) return ResultType.rumbleWin;
    return ResultType.loss;
  }

  LotteryResult _errorResult(String errorMessage) {
    return LotteryResult(
      resultType: ResultType.error,
      matchCount: 0,
      prizeAmount: 0,
      selectedNumbers: [],
      winningNumbers: [],
      isSequenceMatch: false,
      isChanceMatch: false,
      isRumbleMatch: false,
      errorMessage: errorMessage,
    );
  }

  // Helper method to check if results are a
  bool areResultsAvailable(Lottery lottery) {
    // Only check announcedResult, no time condition
    return lottery.announcedResult == 1;
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
  final String? errorMessage;  // Error message if resultType is error

  LotteryResult({
    required this.resultType,
    required this.matchCount,
    required this.prizeAmount,
    required this.selectedNumbers,
    required this.winningNumbers,
    required this.isSequenceMatch,
    required this.isChanceMatch,
    required this.isRumbleMatch,
    this.errorMessage,
  });
}