import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/theme.dart';
import '../format.dart';
import 'highlighted_text.dart';

/// 검색 결과 한 행.
///
/// 종목명 안에서 [query] 와 일치하는 부분이 하이라이트된다.
/// 우측 별 아이콘은 [isFavorite] 상태에 따라 색이 다르고, 탭 시 [onToggle] 이 불린다.
class SearchRow extends StatelessWidget {
  const SearchRow({
    super.key,
    required this.hit,
    required this.query,
    required this.isFavorite,
    required this.onToggle,
    this.onTap,
  });

  final SearchHit hit;
  final String query;
  final bool isFavorite;
  final VoidCallback onToggle;
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
                  HighlightedText(
                    text: hit.name,
                    query: query,
                    baseStyle: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  SizedBox(height: dimens.space1),
                  Text(
                    formatCodeAndMarket(hit.symbol, hit.market),
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_outline,
                color: isFavorite ? colors.favoriteActive : colors.favoriteInactive,
                size: dimens.iconMd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
