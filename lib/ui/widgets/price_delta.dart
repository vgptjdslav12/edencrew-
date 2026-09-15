import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/theme.dart';
import '../format.dart';

/// 등락액/등락률 텍스트. 방향에 따라 색이 바뀐다.
///
/// 예: `-400 (-0.22%)`
class PriceDeltaText extends StatelessWidget {
  const PriceDeltaText({
    super.key,
    required this.direction,
    required this.changeAmount,
    required this.changeRate,
    this.fontSize = 13,
    this.fontWeight = AppTypography.medium,
  });

  final PriceDirection direction;
  final num changeAmount;
  final double changeRate;
  final double fontSize;
  final FontWeight fontWeight;

  Color _color(BuildContext context) {
    switch (direction) {
      case PriceDirection.up:
        return context.colors.priceUpText;
      case PriceDirection.down:
        return context.colors.priceDownText;
      case PriceDirection.flat:
        return context.colors.priceFlatText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String amount = formatChangeAmount(changeAmount);
    final String rate = formatChangeRate(changeRate);
    return Text(
      '$amount ($rate)',
      style: TextStyle(
        color: _color(context),
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
