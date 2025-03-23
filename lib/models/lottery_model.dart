// models/lottery_model.dart
class Lottery {
  final int id;
  final String lotteryId;
  final int numberLottery; // We keep this as int
  final String digits;
  final String endDate;
  final String winningNumber;
  final String createdAt;
  final String updatedAt;
  final String? lotteryName;
  final String? purchasePrice;
  final String? winningPrice;
  final String? lotteryCode;

  Lottery({
    required this.id,
    required this.lotteryId,
    required this.numberLottery,
    required this.digits,
    required this.endDate,
    required this.winningNumber,
    required this.createdAt,
    required this.updatedAt,
    this.lotteryName,
    this.purchasePrice,
    this.winningPrice,
    this.lotteryCode,
  });

  factory Lottery.fromJson(Map<String, dynamic> json) {
    return Lottery(
      id: json['id'],
      lotteryId: json['lottery_id'],
      numberLottery: int.parse(json['number_lottery']), // Parse string to int
      digits: json['digits'],
      endDate: json['end_date'],
      winningNumber: json['winning_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      lotteryName: json['lottery_name'] ?? '',
      purchasePrice: json['purchase_price'] ?? '0',
      winningPrice: json['winning_price'] ?? '0',
      lotteryCode: json['lottery_code'],
    );
  }
}