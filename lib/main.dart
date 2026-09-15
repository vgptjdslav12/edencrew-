import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/stock_source.dart';
import 'state/search_store.dart';
import 'state/watchlist_store.dart';
import 'theme/theme.dart';
import 'ui/home_shell.dart';

void main() {
  runApp(const EdencrewAssignmentApp());
}

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 개발/제출 시엔 assets/mock 을 그대로 쓴다. 실제 네트워크로 붙이려면
    // 여기 한 줄만 `NaverStockSource()` 로 바꿔주면 된다.
    final StockSource source = const MockStockSource();

    return MultiProvider(
      providers: [
        Provider<StockSource>.value(value: source),
        ChangeNotifierProvider<WatchlistStore>(
          create: (_) => WatchlistStore(source: source),
        ),
        ChangeNotifierProvider<SearchStore>(
          create: (_) => SearchStore(source: source),
        ),
      ],
      child: MaterialApp(
        title: '이든크루 평가 과제',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const HomeShell(),
      ),
    );
  }
}
