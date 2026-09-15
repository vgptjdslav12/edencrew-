import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/theme.dart';
import '../format.dart';

/// 시가 / 고가 / 저가 / 거래량 / 시가총액 요약 카드.
///
/// 시세를 아직 못 받은 경우엔 자리만 잡고 값은 `-` 로.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.quote});

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
      ),
      child: Column(
        children: <Widget>[
          _row(context, '시가', _fmt(quote?.open)),
          _row(context, '고가', _fmt(quote?.high)),
          _row(context, '저가', _fmt(quote?.low)),
          _row(
            context,
            '거래량',
            quote == null ? '-' : formatAbbrevKor(quote!.accumulatedVolume),
          ),
          _row(
            context,
            '시가총액',
            quote?.marketCap == null ? '-' : formatAbbrevKor(quote!.marketCap!),
            last: true,
          ),
        ],
      ),
    );
  }

  String _fmt(num? v) => v == null ? '-' : formatPrice(v);

  Widget _row(BuildContext context, String label, String value,
      {bool last = false}) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : dimens.space2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}
