class UserLottery {
  final int id;
  final int userId;
  final String lotteryId;
  final String ticketId;
  final String userName;
  final String userEmail;
  final String userNumber;
  final String lotteryName;
  final String purchasePrice;
  final String winningPrice;
  final String numberOfLottery;
  final String lotteryIssueDate;
  final String selectedNumbers;
  final String wOrL; // win or loss
  final String createdAt;
  final String updatedAt;
  final String? image;
  final String? lotteryCode;

  UserLottery({
    required this.id,
    required this.userId,
    required this.ticketId,
    required this.lotteryId,
    required this.userName,
    required this.userEmail,
    required this.userNumber,
    required this.lotteryName,
    required this.purchasePrice,
    required this.winningPrice,
    required this.numberOfLottery,
    required this.lotteryIssueDate,
    required this.selectedNumbers,
    required this.wOrL,
    required this.createdAt,
    required this.updatedAt,
    this.image,
    this.lotteryCode,
  });

  factory UserLottery.fromJson(Map<String, dynamic> json) {
    return UserLottery(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      ticketId: json['ticket_id'] ?? '',
      lotteryId: json['lottery_id'] ?? '',
      userName: json['User_name'] ?? '',
      userEmail: json['User_email'] ?? '',
      userNumber: json['User_number'] ?? '',
      lotteryName: json['lottery_name'] ?? '',
      purchasePrice: json['purchase_price'] ?? '',
      winningPrice: json['winning_price'] ?? '',
      numberOfLottery: json['number_of_lottery'] ?? '',
      lotteryIssueDate: json['lottery_issue_date'] ?? '',
      selectedNumbers: json['selected_numbers'] ?? '',
      wOrL: json['w_or_l'] ?? 'loss',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      image: json['image'],
      lotteryCode: json['lottery_code'],
    );
  }
}