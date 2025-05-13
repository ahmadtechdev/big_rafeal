import 'package:flutter/material.dart';
import '../models/lottery_model.dart';
import '../utils/app_colors.dart';

class PrizeDetailsExpansion extends StatefulWidget {
  final Lottery lottery;

  const PrizeDetailsExpansion({
    super.key,
    required this.lottery,
  });

  @override
  State<PrizeDetailsExpansion> createState() => _PrizeDetailsExpansionState();
}

class _PrizeDetailsExpansionState extends State<PrizeDetailsExpansion>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  List<Map<String, dynamic>> _getPrizeData() {
    final List<Map<String, dynamic>> prizeData = [];
    final category = int.tryParse(widget.lottery.lotteryCategory) ?? 0;

    // Helper function to add rewards to prizeData
    void addRewards(String type, Map<String, String> rewards) {
      rewards.forEach((matches, amount) {
        final amountValue = double.tryParse(amount) ?? 0;
        if (amountValue > 0) {
          prizeData.add({
            'type': type,
            'matches': matches,
            'amount': amountValue,
          });
        }
      });
    }

    // Determine which rewards to show based on category
    switch (category) {
      case 0: // Sequence only
        addRewards('Sequence', widget.lottery.sequenceRewards);
        break;
      case 1: // Ramble only
        addRewards('Ramble', widget.lottery.rumbleRewards);
        break;
      case 2: // Sequence + Ramble
        addRewards('Sequence', widget.lottery.sequenceRewards);
        addRewards('Ramble', widget.lottery.rumbleRewards);
        break;
      case 3: // Chance only
        addRewards('Chance', widget.lottery.chanceRewards);
        break;
      case 4: // Sequence + Chance
        addRewards('Sequence', widget.lottery.sequenceRewards);
        addRewards('Chance', widget.lottery.chanceRewards);
        break;
      case 5: // Ramble + Chance
        addRewards('Ramble', widget.lottery.rumbleRewards);
        addRewards('Chance', widget.lottery.chanceRewards);
        break;
      case 6: // Sequence + Ramble + Chance
        addRewards('Sequence', widget.lottery.sequenceRewards);
        addRewards('Ramble', widget.lottery.rumbleRewards);
        addRewards('Chance', widget.lottery.chanceRewards);
        break;
      default: // Default to Sequence only
        addRewards('Sequence', widget.lottery.sequenceRewards);
    }

    // Sort by match count (convert to int for proper numeric sorting)
    prizeData.sort((a, b) {
      final aMatches = int.tryParse(a['matches']) ?? 0;
      final bMatches = int.tryParse(b['matches']) ?? 0;
      return aMatches.compareTo(bMatches);
    });

    return prizeData;
  }

  @override
  Widget build(BuildContext context) {
    final prizeData = _getPrizeData();

    // If no prize data, don't show the section
    if (prizeData.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        // Header row with expansion icon
        InkWell(
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prize Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputFieldBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Prize Type',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Matches',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Prize (AED)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table rows with scrollable content if more than 5 items
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: prizeData.length > 5 ? 200 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: prizeData.map((prize) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    prize['type'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    prize['matches'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'AED ${prize['amount'].toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}