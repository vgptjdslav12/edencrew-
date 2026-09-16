import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/stock_source.dart';
import '../state/watchlist_store.dart';
import '../theme/theme.dart';
import 'detail_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/sort_sheet.dart';
import 'widgets/watchlist_row.dart';

// 관심 화면 (01 · 관심).
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Column(
      children: <Widget>[
        _Header(),
        Expanded(
          child: Consumer<WatchlistStore>(
            builder: (BuildContext context, WatchlistStore store, _) {
              if (store.symbols.isEmpty) {
                return const EmptyState(
                  icon: Icons.star_outline,
                  title: '관심 종목이 없습니다',
                  description: '검색 화면에서 관심 있는 종목을 찾아 별을 눌러보세요.',
                );
              }
              final List<String> sorted = store.sortedSymbols();
              return RefreshIndicator(
                color: colors.accentDefault,
                backgroundColor: colors.surfaceRaised,
                onRefresh: () => store.refresh(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: dimens.space2),
                  itemCount: sorted.length,
                  separatorBuilder: (BuildContext context, int _) => Divider(
                    height: dimens.borderHairline,
                    thickness: dimens.borderHairline,
                    color: colors.borderSubtle,
                    indent: dimens.space4,
                    endIndent: dimens.space4,
                  ),
                  itemBuilder: (BuildContext context, int i) {
                    final String s = sorted[i];
                    return WatchlistRow(
                      symbol: s,
                      meta: store.metaOf(s),
                      quote: store.quoteOf(s),
                      onTap: () {
                        final StockSource source = context.read<StockSource>();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DetailScreen(
                              symbol: s,
                              source: source,
                              preloadedMeta: store.metaOf(s),
                              preloadedQuote: store.quoteOf(s),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final WatchlistStore store = context.watch<WatchlistStore>();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
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
            child: Text(
              '관심',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: store.refreshing ? null : () => store.refresh(),
            icon: store.refreshing
                ? SizedBox(
                    width: dimens.iconMd,
                    height: dimens.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textSecondary,
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: colors.textSecondary,
                    size: dimens.iconMd,
                  ),
          ),
          _SortChip(),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final WatchlistStore store = context.watch<WatchlistStore>();

    return InkWell(
      onTap: () async {
        final WatchlistSort? next = await showSortSheet(
          context,
          current: store.sort,
        );
        if (next != null) store.setSort(next);
      },
      borderRadius: BorderRadius.circular(dimens.radiusLg),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space3,
          vertical: dimens.space2,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(dimens.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              store.sort.label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: dimens.iconSm,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
