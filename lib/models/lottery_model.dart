import 'dart:convert';

class Lottery {
  final int id;
  final String lotteryName;
  final String numberLottery;
  final String lotteryCategory; // Added field
  final String purchasePrice;
  final String digits;
  final int announcedResult;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, String> sequenceRewards;
  final Map<String, String> rumbleRewards;
  final Map<String, String> chanceRewards;
  final String image;
  final double maxReward; // Calculated field

  Lottery({
    required this.id,
    required this.lotteryName,
    required this.numberLottery,
    required this.lotteryCategory, // Added to constructor
    required this.purchasePrice,
    required this.digits,
    required this.announcedResult,
    required this.startDate,
    required this.endDate,
    required this.sequenceRewards,
    required this.rumbleRewards,
    required this.chanceRewards,
    required this.image,
    required this.maxReward,
  });


  factory Lottery.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse rewards
    Map<String, String> parseRewards(dynamic rewardsJson) {
      if (rewardsJson == null || rewardsJson == '[]') {
        return {};
      }
      try {
        final decoded = jsonDecode(rewardsJson.toString());
        if (decoded is Map) {
          return Map<String, String>.from(decoded);
        }
        return {};
      } catch (e) {
        return {};
      }
    }

    final sequenceRewards = parseRewards(json['sequence_rewards']);
    final rumbleRewards = parseRewards(json['rumble_rewards']);
    final chanceRewards = parseRewards(json['chance_rewards']);

    // Calculate maximum reward from all three reward types
    final maxReward = _calculateMaxReward(
      sequenceRewards,
      rumbleRewards,
      chanceRewards,
    );

    return Lottery(
      id: json['id'] ?? 0,
      lotteryName: json['lottery_name'] ?? '',
      numberLottery: json['number_lottery'] ?? '',
      lotteryCategory: json['lottery_category'] ?? '1',
      purchasePrice: json['purchase_price'] ?? '',
      digits: json['digits'] ?? '',
      announcedResult: int.tryParse(json['announced_result'].toString()) ?? 0,
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toString()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toString()),
      sequenceRewards: sequenceRewards,
      rumbleRewards: rumbleRewards,
      chanceRewards: chanceRewards,
      image: json['image'] ?? '',
      maxReward: maxReward,
    );
  }
  static double _calculateMaxReward(
      Map<String, String> sequenceRewards,
      Map<String, String> rumbleRewards,
      Map<String, String> chanceRewards,
      ) {
    double max = 0;

    // Check sequence rewards
    for (var value in sequenceRewards.values) {
      final amount = double.tryParse(value) ?? 0;
      if (amount > max) max = amount;
    }

    // Check rumble rewards
    for (var value in rumbleRewards.values) {
      final amount = double.tryParse(value) ?? 0;
      if (amount > max) max = amount;
    }

    // Check chance rewards
    for (var value in chanceRewards.values) {
      final amount = double.tryParse(value) ?? 0;
      if (amount > max) max = amount;
    }

    return max;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lottery_name': lotteryName,
      'number_lottery': numberLottery,
      'lottery_category': lotteryCategory, // Added to JSON output
      'purchase_price': purchasePrice,
      'digits': digits,
      'announced_result': announcedResult,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'sequence_rewards': jsonEncode(sequenceRewards),
      'rumble_rewards': jsonEncode(rumbleRewards),
      'chance_rewards': jsonEncode(chanceRewards),
      'image': image,
    };
  }
}