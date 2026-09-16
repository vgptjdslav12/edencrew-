import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';
import 'widgets/bottom_tab_bar.dart';
import 'widgets/favorite_toast.dart';

// 관심/검색 두 탭. IndexedStack 으로 탭 전환 시 상태 유지 (스크롤, 검색어 등).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeTab _current = HomeTab.watchlist;
  final ToastController _toast = ToastController();

  @override
  void dispose() {
    _toast.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: ToastOverlay(
          controller: _toast,
          child: IndexedStack(
            index: _current.index,
            children: <Widget>[
              const WatchlistScreen(),
              SearchScreen(toast: _toast),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomTabBar(
        current: _current,
        onSelect: (HomeTab t) => setState(() => _current = t),
      ),
    );
  }
}
