import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/theme.dart';
import '../format.dart';

// 일별 시세 표. 날짜(MM.DD)/종가/등락/거래량.
// 등락은 이전 행 종가로 diff 재계산 (파서가 전일비 컬럼은 안 뽑았음).
class DailyPricesTable extends StatelessWidget {
  const DailyPricesTable({super.key, required this.prices});

  final List<DailyPrice> prices;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space4,
            vertical: dimens.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.borderSubtle,
                width: dimens.borderHairline,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(flex: 2, child: _headerCell(context, '날짜')),
              Expanded(flex: 3, child: _headerCell(context, '종가', end: true)),
              Expanded(flex: 3, child: _headerCell(context, '등락', end: true)),
              Expanded(flex: 3, child: _headerCell(context, '거래량', end: true)),
            ],
          ),
        ),
        for (int i = 0; i < prices.length; i++)
          _Row(
            price: prices[i],
            previousClose: i + 1 < prices.length ? prices[i + 1].closePrice : null,
          ),
      ],
    );
  }

  Widget _headerCell(BuildContext context, String label, {bool end = false}) {
    return Text(
      label,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: TextStyle(
        color: context.colors.textTertiary,
        fontSize: 12,
        fontWeight: AppTypography.medium,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.price, required this.previousClose});
  final DailyPrice price;
  final int? previousClose;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    Color changeColor;
    String changeText;
    if (previousClose == null) {
      changeColor = colors.priceFlatText;
      changeText = '-';
    } else {
      final int diff = price.closePrice - previousClose!;
      if (diff > 0) {
        changeColor = colors.priceUpText;
        changeText = '+${formatPrice(diff)}';
      } else if (diff < 0) {
        changeColor = colors.priceDownText;
        changeText = '-${formatPrice(diff.abs())}';
      } else {
        changeColor = colors.priceFlatText;
        changeText = '0';
      }
    }

    final String date =
        '${price.date.month.toString().padLeft(2, '0')}.${price.date.day.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formatPrice(price.closePrice),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              changeText,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: changeColor,
                fontSize: 13,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formatPrice(price.volume),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
