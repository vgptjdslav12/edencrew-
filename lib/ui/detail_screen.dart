import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/stock_source.dart';
import '../state/detail_store.dart';
import '../state/watchlist_store.dart';
import '../theme/theme.dart';
import 'format.dart';
import 'widgets/candle_chart.dart';
import 'widgets/daily_prices_table.dart';
import 'widgets/period_tabs.dart';
import 'widgets/summary_card.dart';

/// 종목 상세 화면 (`03 · 종목상세`).
class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.symbol,
    required this.source,
    this.preloadedMeta,
    this.preloadedQuote,
  });

  final String symbol;
  final StockSource source;
  final StockMeta? preloadedMeta;
  final Quote? preloadedQuote;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final DetailStore _store;

  @override
  void initState() {
    super.initState();
    _store = DetailStore(symbol: widget.symbol, source: widget.source);
    _store.init(
      preloadedMeta: widget.preloadedMeta,
      preloadedQuote: widget.preloadedQuote,
    );
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DetailStore>.value(
      value: _store,
      child: Scaffold(
        backgroundColor: context.colors.surfaceBase,
        body: SafeArea(child: _Body()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DetailStore store = context.watch<DetailStore>();
    final WatchlistStore watch = context.watch<WatchlistStore>();
    final AppDimens dimens = context.dimens;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(child: _TopBar(store: store, watch: watch)),
        SliverToBoxAdapter(child: _PriceHeader(store: store)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              dimens.space4,
              dimens.space3,
              dimens.space4,
              dimens.space2,
            ),
            child: PeriodTabs(
              current: store.period,
              onChanged: (DetailPeriod p) => store.selectPeriod(p),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space4,
              vertical: dimens.space3,
            ),
            child: CandleChart(prices: store.dailyPrices),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space4,
              vertical: dimens.space3,
            ),
            child: SummaryCard(quote: store.quote),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              dimens.space4,
              dimens.space4,
              dimens.space4,
              dimens.space2,
            ),
            child: Text(
              '일별 시세',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 15,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: DailyPricesTable(prices: store.dailyPrices),
        ),
        SliverToBoxAdapter(child: SizedBox(height: dimens.space6)),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.store, required this.watch});
  final DetailStore store;
  final WatchlistStore watch;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final bool fav = watch.isFavorite(store.symbol);
    final StockMeta? meta = store.meta;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space2,
        vertical: dimens.space2,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  meta?.name ?? store.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  formatCodeAndMarket(store.symbol, meta?.marketKor ?? ''),
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
            icon: Icon(
              fav ? Icons.star : Icons.star_outline,
              color: fav ? colors.favoriteActive : colors.favoriteInactive,
              size: dimens.iconMd,
            ),
            onPressed: () => watch.toggleFavorite(
              store.symbol,
              preloadedMeta: meta,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({required this.store});
  final DetailStore store;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final Quote? q = store.quote;

    if (q == null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space3,
        ),
        child: Text(
          '-',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 30,
            fontWeight: AppTypography.bold,
          ),
        ),
      );
    }

    Color deltaColor;
    switch (q.direction) {
      case PriceDirection.up:
        deltaColor = colors.priceUpText;
        break;
      case PriceDirection.down:
        deltaColor = colors.priceDownText;
        break;
      case PriceDirection.flat:
        deltaColor = colors.priceFlatText;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            formatPrice(q.currentPrice),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 30,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space1),
          Row(
            children: <Widget>[
              Text(
                directionArrow(q.direction),
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                ),
              ),
              SizedBox(width: dimens.space1),
              Text(
                '${formatPrice(q.changeAmount.abs())} (${formatChangeRate(q.changeRate)})',
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 14,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
