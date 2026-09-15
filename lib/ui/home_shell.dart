import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';
import 'widgets/bottom_tab_bar.dart';
import 'widgets/favorite_toast.dart';

/// 관심 / 검색 두 탭을 유지하는 최상위 화면.
///
/// IndexedStack 을 써서 탭 전환 시 각 화면의 상태(스크롤 위치, 검색어 등)가
/// 유지되게 했다. 상태관리 스토어는 상위(`main.dart`)에서 provider 로 이미
/// 주입되어 있으므로 여기서는 순수 UI 조립만.
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
