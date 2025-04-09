class Lottery {
  final int id;
  final String lotteryId;
  final int numberLottery;  // Changed from int to String
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
  final String? thirdWin;
  final String? fourWin;
  final String? fiveWin;
  final String? sixWin;
  final String? sevenWin;
  final String? eightWin;
  final String? nineWin;
  final String? tenWin;
  // New fields for match sequences
  final String? thirdMatchSequence;
  final String? fourMatchSequence;
  final String? fiveMatchSequence;
  final String? sixMatchSequence;
  final String? sevenMatchSequence;
  final String? eightMatchSequence;
  final String? nineMatchSequence;
  final String? tenMatchSequence;

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
    this.thirdWin,
    this.fourWin,
    this.fiveWin,
    this.sixWin,
    this.sevenWin,
    this.eightWin,
    this.nineWin,
    this.tenWin,
    this.thirdMatchSequence,
    this.fourMatchSequence,
    this.fiveMatchSequence,
    this.sixMatchSequence,
    this.sevenMatchSequence,
    this.eightMatchSequence,
    this.nineMatchSequence,
    this.tenMatchSequence,
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
      thirdWin: json['third_win'],
      fourWin: json['four_win'],
      fiveWin: json['five_win'],
      sixWin: json['six_win'],
      sevenWin: json['seven_win'],
      eightWin: json['eight_win'],
      nineWin: json['nine_win'],
      tenWin: json['ten_win'],
      thirdMatchSequence: json['third_match_sequence'],
      fourMatchSequence: json['four_match_sequence'],
      fiveMatchSequence: json['five_match_sequence'],
      sixMatchSequence: json['six_match_sequence'],
      sevenMatchSequence: json['seven_match_sequence'],
      eightMatchSequence: json['eight_match_sequence'],
      nineMatchSequence: json['nine_match_sequence'],
      tenMatchSequence: json['ten_match_sequence'],
    );
  }
}