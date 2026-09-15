import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/theme.dart';
import '../format.dart';
import 'price_delta.dart';
import 'skeleton.dart';

/// 관심 화면 목록 한 행.
///
/// [meta] 가 없으면 이름/시장이 스켈레톤이 되고, [quote] 가 없으면 가격/등락이
/// 스켈레톤이 된다. 이 두 상태가 따로 채워지는 걸 그대로 반영한다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({
    super.key,
    required this.symbol,
    this.meta,
    this.quote,
    this.onTap,
  });

  final String symbol;
  final StockMeta? meta;
  final Quote? quote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 종목명
                  meta == null
                      ? const SkeletonBox(width: 96, height: 16)
                      : Text(
                          meta!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                  SizedBox(height: dimens.space1),
                  // 코드 · 시장
                  Text(
                    formatCodeAndMarket(symbol, meta?.marketKor ?? ''),
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                quote == null
                    ? const SkeletonBox(width: 72, height: 16)
                    : Text(
                        formatPrice(quote!.currentPrice),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                SizedBox(height: dimens.space1),
                quote == null
                    ? const SkeletonBox(width: 88, height: 14)
                    : PriceDeltaText(
                        direction: quote!.direction,
                        changeAmount: quote!.changeAmount,
                        changeRate: quote!.changeRate,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
