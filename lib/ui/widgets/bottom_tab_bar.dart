import 'package:flutter/material.dart';

import '../../theme/theme.dart';

enum HomeTab { watchlist, search }

/// 관심 / 검색 두 개짜리 하단 탭 바.
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final HomeTab current;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      height: dimens.tabBarHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          _TabItem(
            icon: Icons.star_outline,
            activeIcon: Icons.star,
            label: '관심',
            selected: current == HomeTab.watchlist,
            onTap: () => onSelect(HomeTab.watchlist),
          ),
          _TabItem(
            icon: Icons.search,
            label: '검색',
            selected: current == HomeTab.search,
            onTap: () => onSelect(HomeTab.search),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color c = selected ? colors.navActive : colors.navInactive;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(selected ? (activeIcon ?? icon) : icon, color: c, size: context.dimens.iconMd),
            SizedBox(height: context.dimens.space1),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: selected ? AppTypography.medium : AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
