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
    // 실제 Naver endpoint 로 붙는다. 네트워크 없이 띄우려면 `MockStockSource()` 로.
    final StockSource source = NaverStockSource();

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
