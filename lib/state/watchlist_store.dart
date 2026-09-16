import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/stock_source.dart';

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

// 세 화면(관심/검색/상세)의 관심 상태 single source of truth.
// 시세/메타는 등록 시점에 lazy hydrate, refresh() 로 일괄 갱신.
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

  // 등록되면 true, 해제되면 false.
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
    // 메타/시세 채우기는 백그라운드로.
    _hydrate(symbol);
    return true;
  }

  Future<void> _hydrate(String symbol) async {
    if (!_metas.containsKey(symbol)) {
      try {
        _metas[symbol] = await _source.fetchMeta(symbol);
        notifyListeners();
      } catch (_) {
        // 메타 실패면 이름 자리에 심볼만 뜸. 그냥 넘김.
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
      // 실패면 스켈레톤 유지.
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
      // 실패해도 화면 죽지 않게 이전 값 유지. 에러 UI 는 안 띄움.
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

  // 시세 없는 종목은 현재가/등락률 정렬 시 뒤로 뺌 (직접 판단, README 기록).
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
