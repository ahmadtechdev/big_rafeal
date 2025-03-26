class Lottery {
  final int id;
  final String lotteryId;
  final int numberLottery;
  final String digits;
  final String startDate;
  final String endDate;
  final String winningNumber;
  final String createdAt;
  final String updatedAt;
  final String lotteryName;
  final String purchasePrice;
  final String winningPrice;
  final String lotteryCode;
  final String image;
  final String thirdWin;
  final String fourWin;
  final String fiveWin;
  final String sixWin;
  final String sevenWin;
  final String eightWin;
  final String nineWin;
  final String tenWin;

  Lottery({
    required this.id,
    required this.lotteryId,
    required this.numberLottery,
    required this.digits,
    required this.startDate,
    required this.endDate,
    required this.winningNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.lotteryName,
    required this.purchasePrice,
    required this.winningPrice,
    required this.lotteryCode,
    required this.image,
    required this.thirdWin,
    required this.fourWin,
    required this.fiveWin,
    required this.sixWin,
    required this.sevenWin,
    required this.eightWin,
    required this.nineWin,
    required this.tenWin,
  });

  factory Lottery.fromJson(Map<String, dynamic> json) {
    return Lottery(
      id: json['id'] ?? 0,
      lotteryId: json['lottery_id'] ?? '',
      numberLottery: int.tryParse(json['number_lottery'].toString()) ?? 0,
      digits: json['digits'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      winningNumber: json['winning_number'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      lotteryName: json['lottery_name'] ?? '',
      purchasePrice: json['purchase_price'] ?? '0',
      winningPrice: json['winning_price'] ?? '0',
      lotteryCode: json['lottery_code'] ?? '',
      image: json['image'] ?? '',
      thirdWin: json['third_win'] ?? '0',
      fourWin: json['four_win'] ?? '0',
      fiveWin: json['five_win'] ?? '0',
      sixWin: json['six_win'] ?? '0',
      sevenWin: json['seven_win'] ?? '0',
      eightWin: json['eight_win'] ?? '0',
      nineWin: json['nine_win'] ?? '0',
      tenWin: json['ten_win'] ?? '0',
    );
  }
}