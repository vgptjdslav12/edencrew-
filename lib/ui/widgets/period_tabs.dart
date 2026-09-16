import 'package:flutter/material.dart';

import '../../state/detail_store.dart';
import '../../theme/theme.dart';

// 1개월/3개월/6개월/1년 세그먼트.
class PeriodTabs extends StatelessWidget {
  const PeriodTabs({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final DetailPeriod current;
  final ValueChanged<DetailPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Row(
      children: <Widget>[
        for (final DetailPeriod p in DetailPeriod.values)
          Padding(
            padding: EdgeInsets.only(right: dimens.space2),
            child: InkWell(
              borderRadius: BorderRadius.circular(dimens.radiusMd),
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: EdgeInsets.symmetric(
                  horizontal: dimens.space3,
                  vertical: dimens.space2,
                ),
                decoration: BoxDecoration(
                  color: p == current ? colors.accentBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(dimens.radiusMd),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: p == current
                        ? AppTypography.medium
                        : AppTypography.regular,
                    color: p == current
                        ? colors.accentDefault
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
