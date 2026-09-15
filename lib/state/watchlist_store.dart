import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/stock_source.dart';

/// 관심종목 정렬 기준.
enum WatchlistSort { price, changeRate, name }

extension WatchlistSortLabel on WatchlistSort {
  String get label {
    switch (this) {
      case WatchlistSort.price:
        return '현재가순';
      case WatchlistSort.changeRate:
        return '등락률순';
      case WatchlistSort.name:
        return '가나다순';
    }
  }
}

/// 관심종목 목록 + 각 종목의 시세/메타를 관리한다.
///
/// 이 저장소가 다음 세 화면에서 참조되는 단일 source of truth 다.
/// - 관심 화면: 여기 있는 [symbols] 를 그대로 보여준다.
/// - 검색 화면: [isFavorite] 로 별 아이콘 상태를 판정한다.
/// - 상세 화면: 같은 [isFavorite] 를 참조 + [toggleFavorite] 로 등록/해제.
///
/// 시세와 메타는 관심 등록 시점에 lazy 로 채워지고, 새로고침 버튼을 누르면
/// 관심종목 전체에 대해 한 번의 실시간 시세 요청으로 갱신한다.
class WatchlistStore extends ChangeNotifier {
  WatchlistStore({required StockSource source}) : _source = source;

  final StockSource _source;

  final List<String> _symbols = <String>[];
  final Map<String, StockMeta> _metas = <String, StockMeta>{};
  final Map<String, Quote> _quotes = <String, Quote>{};

  bool _refreshing = false;
  WatchlistSort _sort = WatchlistSort.changeRate;

  List<String> get symbols => List<String>.unmodifiable(_symbols);
  Map<String, StockMeta> get metas => Map<String, StockMeta>.unmodifiable(_metas);
  Map<String, Quote> get quotes => Map<String, Quote>.unmodifiable(_quotes);
  bool get refreshing => _refreshing;
  WatchlistSort get sort => _sort;

  bool isFavorite(String symbol) => _symbols.contains(symbol);

  StockMeta? metaOf(String symbol) => _metas[symbol];
  Quote? quoteOf(String symbol) => _quotes[symbol];

  /// 관심 등록/해제 토글. 등록될 때 true, 해제될 때 false 를 돌려준다.
  Future<bool> toggleFavorite(String symbol, {StockMeta? preloadedMeta}) async {
    if (_symbols.contains(symbol)) {
      _symbols.remove(symbol);
      notifyListeners();
      return false;
    }
    _symbols.add(symbol);
    if (preloadedMeta != null) {
      _metas[symbol] = preloadedMeta;
    }
    notifyListeners();
    // 새로 추가된 종목에 대한 메타/시세 채우기는 백그라운드로 진행.
    _hydrate(symbol);
    return true;
  }

  Future<void> _hydrate(String symbol) async {
    if (!_metas.containsKey(symbol)) {
      try {
        _metas[symbol] = await _source.fetchMeta(symbol);
        notifyListeners();
      } catch (_) {
        // 메타 실패 시 상세/목록에서 종목명 자리에 심볼만 노출됨. 무시.
      }
    }
    try {
      final Map<String, Quote> q = await _source.fetchQuotes(<String>[symbol]);
      final Quote? found = q[symbol];
      if (found != null) {
        _quotes[symbol] = found;
        notifyListeners();
      }
    } catch (_) {
      // 시세 실패 시 스켈레톤 상태 유지.
    }
  }

  Future<void> refresh() async {
    if (_symbols.isEmpty) return;
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    try {
      final Map<String, Quote> q = await _source.fetchQuotes(_symbols);
      _quotes
        ..clear()
        ..addAll(q);
    } catch (_) {
      // 실패해도 화면이 죽지 않게. UI 쪽에서 별도 에러 처리 여지가 있지만
      // 여기서는 조용히 넘어가고 이전 값을 유지한다.
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void setSort(WatchlistSort next) {
    if (_sort == next) return;
    _sort = next;
    notifyListeners();
  }

  /// 정렬된 심볼 순서를 반환.
  ///
  /// 시세를 아직 받지 못한 종목은 currentPrice/changeRate 기준으로는 뒤에 몰아둔다.
  /// (Figma 에 지정된 규칙이 없어 직접 판단한 부분. 시세가 없는 걸 상단에 두면
  ///  같은 값끼리 순서가 흔들려 보이는 게 부자연스러워서 아래로 뺐음.)
  List<String> sortedSymbols() {
    final List<String> out = List<String>.from(_symbols);
    switch (_sort) {
      case WatchlistSort.price:
        out.sort((String a, String b) {
          final Quote? qa = _quotes[a];
          final Quote? qb = _quotes[b];
          if (qa == null && qb == null) return 0;
          if (qa == null) return 1;
          if (qb == null) return -1;
          return qb.currentPrice.compareTo(qa.currentPrice);
        });
        break;
      case WatchlistSort.changeRate:
        out.sort((String a, String b) {
          final Quote? qa = _quotes[a];
          final Quote? qb = _quotes[b];
          if (qa == null && qb == null) return 0;
          if (qa == null) return 1;
          if (qb == null) return -1;
          return qb.changeRate.compareTo(qa.changeRate);
        });
        break;
      case WatchlistSort.name:
        out.sort((String a, String b) {
          final String na = _metas[a]?.name ?? a;
          final String nb = _metas[b]?.name ?? b;
          return na.compareTo(nb);
        });
        break;
    }
    return out;
  }
}
