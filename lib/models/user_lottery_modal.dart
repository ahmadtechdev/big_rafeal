class UserLottery {
  final int id;
  final int userId;
  final String lotteryId;
  final String ticketId;
  final String lotteryName;
  final String purchasePrice;
  final double winAmount;
  final String numberOfLottery;
  final String lotteryIssueDate;
  final String selectedNumbers;
  final String wOrL; // WIN or LOSS
  final String claimed_at; // WIN or LOSS
  final String endDate;
  final String? category;
  final String? order_id;

  UserLottery({
    required this.id,
    required this.userId,
    required this.lotteryId,
    required this.ticketId,
    required this.lotteryName,
    required this.purchasePrice,
    required this.winAmount,
    required this.numberOfLottery,
    required this.lotteryIssueDate,
    required this.selectedNumbers,
    required this.wOrL,
    required this.claimed_at,
    required this.endDate,
    this.category,
    this.order_id,
  });

  factory UserLottery.fromJson(Map<String, dynamic> json) {
    return UserLottery(
      id: json['id'] ?? 0,
      userId: int.parse(json['user_id']),
      lotteryId: json['lottery_id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      lotteryName: json['lottery_name'] ?? '',
      purchasePrice: json['purchase_price']?.toString() ?? '0',
      winAmount: double.tryParse(json['win_amount']?.toString() ?? '0') ?? 0,
      numberOfLottery: json['number_of_lottery']?.toString() ?? '',
      lotteryIssueDate: json['lottery_issue_date'] ?? '',
      selectedNumbers: json['selected_numbers'] ?? '',
      wOrL: json['w_or_l'] ?? 'LOSS',
      claimed_at: json['claimed_at'] ?? "",
      endDate: json['end_date'] ?? '',
      category: json['category']?.toString() ?? '',
      order_id: json['order_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lottery_id': lotteryId,
      'ticket_id': ticketId,
      'lottery_name': lotteryName,
      'purchase_price': purchasePrice,
      'win_amount': winAmount,
      'number_of_lottery': numberOfLottery,
      'lottery_issue_date': lotteryIssueDate,
      'selected_numbers': selectedNumbers,
      'w_or_l': wOrL,
      'claimed_at': claimed_at,
      'end_date': endDate,
      'category': category,
      'order_id': order_id,
    };
  }
}