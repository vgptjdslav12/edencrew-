import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/stock_source.dart';
import '../state/search_store.dart';
import '../state/watchlist_store.dart';
import '../theme/theme.dart';
import 'detail_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/favorite_toast.dart';
import 'widgets/search_row.dart';

/// 검색 화면 (`02 · 검색`).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.toast});

  final ToastController toast;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SearchStore>().query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _SearchField(controller: _controller),
        Expanded(child: _SearchBody(toast: widget.toast)),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final SearchStore store = context.watch<SearchStore>();

    return Container(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.space3,
        dimens.space4,
        dimens.space3,
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
          Icon(Icons.search, size: dimens.iconMd, color: colors.textTertiary),
          SizedBox(width: dimens.space2),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: AppTypography.regular,
              ),
              cursorColor: colors.accentDefault,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '종목명 또는 종목코드',
                hintStyle: TextStyle(
                  color: colors.textDisabled,
                  fontSize: 15,
                  fontWeight: AppTypography.regular,
                ),
              ),
              onChanged: store.updateQuery,
            ),
          ),
          if (store.query.isNotEmpty)
            InkWell(
              onTap: () {
                controller.clear();
                store.clear();
              },
              child: Padding(
                padding: EdgeInsets.all(dimens.space1),
                child: Icon(
                  Icons.cancel,
                  size: dimens.iconSm,
                  color: colors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.toast});
  final ToastController toast;

  @override
  Widget build(BuildContext context) {
    final SearchStore search = context.watch<SearchStore>();
    final WatchlistStore watch = context.watch<WatchlistStore>();

    if (search.query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: '종목을 검색해 보세요',
        description: '관심 있는 종목명이나 종목코드를 입력해 주세요.',
      );
    }

    if (search.loading && search.results.isEmpty) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.textSecondary,
          ),
        ),
      );
    }

    if (search.results.isEmpty) {
      // 검색어가 매우 길 때 그대로 노출하면 안내 문구가 두 줄을 넘어갈 수 있어
      // 24자에서 잘라 `...` 를 붙였다. (직접 판단 사항 · README 기록)
      final String shown = search.query.length > 24
          ? '${search.query.substring(0, 24)}…'
          : search.query;
      return EmptyState(
        icon: Icons.search_off,
        title: '검색 결과가 없어요',
        description: "'$shown'와 일치하는 검색 결과를 찾지 못했습니다.",
      );
    }

    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return ListView.separated(
      itemCount: search.results.length,
      separatorBuilder: (BuildContext context, int _) => Divider(
        height: dimens.borderHairline,
        thickness: dimens.borderHairline,
        color: colors.borderSubtle,
        indent: dimens.space4,
        endIndent: dimens.space4,
      ),
      itemBuilder: (BuildContext context, int i) {
        final SearchHit hit = search.results[i];
        final bool fav = watch.isFavorite(hit.symbol);
        return SearchRow(
          hit: hit,
          query: search.query,
          isFavorite: fav,
          onToggle: () async {
            final bool nowFav = await watch.toggleFavorite(
              hit.symbol,
              preloadedMeta: StockMeta(
                symbol: hit.symbol,
                name: hit.name,
                marketKor: hit.market,
              ),
            );
            toast.show(FavoriteToast(registered: nowFav));
          },
          onTap: () {
            final StockSource source = context.read<StockSource>();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DetailScreen(
                  symbol: hit.symbol,
                  source: source,
                  preloadedMeta: StockMeta(
                    symbol: hit.symbol,
                    name: hit.name,
                    marketKor: hit.market,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
