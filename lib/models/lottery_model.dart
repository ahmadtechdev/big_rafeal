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
  final String lotteryCode;
  final String? image;

  // Match sequence fields
  final String? thirdMatchSequence;
  final String? fourMatchSequence;
  final String? fiveMatchSequence;
  final String? sixMatchSequence;
  final String? sevenMatchSequence;
  final String? eightMatchSequence;
  final String? nineMatchSequence;
  final String? tenMatchSequence;
  // Match chance fields
  final String? firstMatchChance;
  final String? secondMatchChance;
  final String? thirdMatchChance;
  final String? fourMatchChance;
  final String? fiveMatchChance;
  final String? sixMatchChance;
  final String? sevenMatchChance;
  final String? eightMatchChance;
  final String? nineMatchChance;
  final String? tenMatchChance;
  // Match ramble fields
  final String? thirdMatchRamble;
  final String? fourMatchRamble;
  final String? fiveMatchRamble;
  final String? sixMatchRamble;
  final String? sevenMatchRamble;
  final String? eightMatchRamble;
  final String? nineMatchRamble;
  final String? tenMatchRamble;
  // Added fields
  final String lotteryCategory;
  final String? announcedResult;

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
    required this.lotteryCode,
    this.image,
    required this.lotteryCategory,
    this.announcedResult,

    this.thirdMatchSequence,
    this.fourMatchSequence,
    this.fiveMatchSequence,
    this.sixMatchSequence,
    this.sevenMatchSequence,
    this.eightMatchSequence,
    this.nineMatchSequence,
    this.tenMatchSequence,
    this.firstMatchChance,
    this.secondMatchChance,
    this.thirdMatchChance,
    this.fourMatchChance,
    this.fiveMatchChance,
    this.sixMatchChance,
    this.sevenMatchChance,
    this.eightMatchChance,
    this.nineMatchChance,
    this.tenMatchChance,
    this.thirdMatchRamble,
    this.fourMatchRamble,
    this.fiveMatchRamble,
    this.sixMatchRamble,
    this.sevenMatchRamble,
    this.eightMatchRamble,
    this.nineMatchRamble,
    this.tenMatchRamble,
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

      lotteryCode: json['lottery_code'] ?? '',
      image: json['image'],
      lotteryCategory: json['lottery_category'] ?? '0',
      announcedResult: json['announced_result'],

      thirdMatchSequence: json['third_match_sequence'],
      fourMatchSequence: json['four_match_sequence'],
      fiveMatchSequence: json['five_match_sequence'],
      sixMatchSequence: json['six_match_sequence'],
      sevenMatchSequence: json['seven_match_sequence'],
      eightMatchSequence: json['eight_match_sequence'],
      nineMatchSequence: json['nine_match_sequence'],
      tenMatchSequence: json['ten_match_sequence'],
      firstMatchChance: json['first_match_chance'],
      secondMatchChance: json['second_match_chance'],
      thirdMatchChance: json['third_match_chance'],
      fourMatchChance: json['four_match_chance'],
      fiveMatchChance: json['five_match_chance'],
      sixMatchChance: json['six_match_chance'],
      sevenMatchChance: json['seven_match_chance'],
      eightMatchChance: json['eight_match_chance'],
      nineMatchChance: json['nine_match_chance'],
      tenMatchChance: json['ten_match_chance'],
      thirdMatchRamble: json['third_match_ramble'],
      fourMatchRamble: json['four_match_ramble'],
      fiveMatchRamble: json['five_match_ramble'],
      sixMatchRamble: json['six_match_ramble'],
      sevenMatchRamble: json['seven_match_ramble'],
      eightMatchRamble: json['eight_match_ramble'],
      nineMatchRamble: json['nine_match_ramble'],
      tenMatchRamble: json['ten_match_ramble'],
    );
  }

  double get highestPrize {
    // Convert all possible prize amounts to doubles
    final List<double?> prizes = [

      double.tryParse(tenMatchSequence ?? '0'),
      double.tryParse(nineMatchSequence ?? '0'),
      double.tryParse(eightMatchSequence ?? '0'),
      double.tryParse(sevenMatchSequence ?? '0'),
      double.tryParse(sixMatchSequence ?? '0'),
      double.tryParse(fiveMatchSequence ?? '0'),
      double.tryParse(fourMatchSequence ?? '0'),
      double.tryParse(thirdMatchSequence ?? '0'),
      // Adding the new match ramble fields
      double.tryParse(tenMatchRamble ?? '0'),
      double.tryParse(nineMatchRamble ?? '0'),
      double.tryParse(eightMatchRamble ?? '0'),
      double.tryParse(sevenMatchRamble ?? '0'),
      double.tryParse(sixMatchRamble ?? '0'),
      double.tryParse(fiveMatchRamble ?? '0'),
      double.tryParse(fourMatchRamble ?? '0'),
      double.tryParse(thirdMatchRamble ?? '0'),
      // Adding the new match chance fields
      double.tryParse(tenMatchChance ?? '0'),
      double.tryParse(nineMatchChance ?? '0'),
      double.tryParse(eightMatchChance ?? '0'),
      double.tryParse(secondMatchChance ?? '0'),
      double.tryParse(sixMatchChance ?? '0'),
      double.tryParse(fiveMatchChance ?? '0'),
      double.tryParse(fourMatchChance ?? '0'),
      double.tryParse(thirdMatchChance ?? '0'),
      double.tryParse(secondMatchChance ?? '0'),
      double.tryParse(firstMatchChance ?? '0'),
    ];

    // Filter out null values and find the maximum
    final validPrizes = prizes.whereType<double>().toList();
    if (validPrizes.isEmpty) return 0;
    return validPrizes.reduce((max, e) => e > max ? e : max);
  }
}