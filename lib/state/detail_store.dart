import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/stock_source.dart';

enum DetailPeriod { month1, month3, month6, year1 }

extension DetailPeriodLabel on DetailPeriod {
  String get label {
    switch (this) {
      case DetailPeriod.month1:
        return '1개월';
      case DetailPeriod.month3:
        return '3개월';
      case DetailPeriod.month6:
        return '6개월';
      case DetailPeriod.year1:
        return '1년';
    }
  }

  // 1 페이지 = 10 거래일 기준.
  int get pageCount {
    switch (this) {
      case DetailPeriod.month1:
        return 2;
      case DetailPeriod.month3:
        return 6;
      case DetailPeriod.month6:
        return 12;
      case DetailPeriod.year1:
        return 25;
    }
  }
}

// 상세 한 화면 분량의 상태.
// 메타/시세 fallback 로드 + 기간 탭 전환 + 일별 페이지 캐싱/이어받기.
class DetailStore extends ChangeNotifier {
  DetailStore({required this.symbol, required StockSource source})
      : _source = source;

  final String symbol;
  final StockSource _source;

  StockMeta? _meta;
  Quote? _quote;
  DetailPeriod _period = DetailPeriod.month1;
  final Map<int, DailyPricePage> _pages = <int, DailyPricePage>{};
  int? _knownLastPage;
  bool _loading = false;

  StockMeta? get meta => _meta;
  Quote? get quote => _quote;
  DetailPeriod get period => _period;
  bool get loading => _loading;

  // 현재 기간 일별 시세 (최신→과거). 페이지에 구멍 있으면 거기까지만.
  List<DailyPrice> get dailyPrices {
    final int need = _period.pageCount;
    final List<DailyPrice> out = <DailyPrice>[];
    for (int i = 1; i <= need; i++) {
      final DailyPricePage? p = _pages[i];
      if (p == null) break;
      out.addAll(p.prices);
    }
    return out;
  }

  bool get isPeriodFullyLoaded {
    final int need = _period.pageCount;
    final int last = _knownLastPage ?? need;
    final int cap = need < last ? need : last;
    for (int i = 1; i <= cap; i++) {
      if (_pages[i] == null) return false;
    }
    return true;
  }

  Future<void> init({StockMeta? preloadedMeta, Quote? preloadedQuote}) async {
    _meta = preloadedMeta;
    _quote = preloadedQuote;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      _ensureMeta(),
      _ensureQuote(),
      _loadForPeriod(),
    ]);
  }

  Future<void> _ensureMeta() async {
    if (_meta != null) return;
    try {
      _meta = await _source.fetchMeta(symbol);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _ensureQuote() async {
    if (_quote != null) return;
    try {
      final Map<String, Quote> q =
          await _source.fetchQuotes(<String>[symbol]);
      _quote = q[symbol];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectPeriod(DetailPeriod next) async {
    if (_period == next) return;
    _period = next;
    notifyListeners();
    await _loadForPeriod();
  }

  // 현재 _period 를 채울 페이지들 병렬 로드.
  // 캐시된 페이지는 skip. page 1 응답의 lastPage 로 상한 잡음.
  Future<void> _loadForPeriod() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      // page 1 이 lastPage 알아낼 유일한 소스라 먼저.
      if (_pages[1] == null) {
        try {
          final DailyPricePage first =
              await _source.fetchDailyPage(symbol, 1);
          _pages[1] = first;
          _knownLastPage = first.lastPage;
          notifyListeners();
        } catch (_) {
          // 실패하면 나머지도 의미 없음. 종료.
          return;
        }
      } else {
        _knownLastPage ??= _pages[1]!.lastPage;
      }

      final int need = _period.pageCount;
      final int last = _knownLastPage ?? need;
      final int cap = need < last ? need : last;

      final List<Future<void>> jobs = <Future<void>>[];
      for (int i = 2; i <= cap; i++) {
        if (_pages[i] != null) continue;
        jobs.add(_fetchPage(i));
      }
      await Future.wait<void>(jobs);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPage(int page) async {
    try {
      final DailyPricePage p = await _source.fetchDailyPage(symbol, page);
      _pages[page] = p;
      // lastPage 아직 못 잡았으면 여기서 갱신.
      if (_knownLastPage == null && p.lastPage != null) {
        _knownLastPage = p.lastPage;
      }
      notifyListeners();
    } catch (_) {}
  }
}
