import 'package:flutter/material.dart';

import '../../state/watchlist_store.dart';
import '../../theme/theme.dart';

/// 정렬 기준 바텀시트. 헤더 우측 칩을 눌렀을 때 열린다.
///
/// `showModalBottomSheet` 에 감싸서 쓴다.
Future<WatchlistSort?> showSortSheet(
  BuildContext context, {
  required WatchlistSort current,
}) {
  return showModalBottomSheet<WatchlistSort>(
    context: context,
    backgroundColor: context.colors.surfaceRaised,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.dimens.radiusLg),
      ),
    ),
    builder: (BuildContext ctx) => _SortSheet(current: current),
  );
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});
  final WatchlistSort current;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dimens.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: dimens.space3),
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            for (final WatchlistSort s in WatchlistSort.values)
              InkWell(
                onTap: () => Navigator.of(context).pop(s),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: dimens.space5,
                    vertical: dimens.space4,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          s.label,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: s == current
                                ? AppTypography.medium
                                : AppTypography.regular,
                          ),
                        ),
                      ),
                      if (s == current)
                        Icon(
                          Icons.check,
                          size: dimens.iconMd,
                          color: colors.accentDefault,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
