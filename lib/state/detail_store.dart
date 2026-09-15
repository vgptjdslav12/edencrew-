import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/stock_source.dart';

/// 상세 화면의 기간 탭.
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

  /// 이 기간을 채우는 데 필요한 페이지 수. (한 페이지 = 10 거래일)
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

/// 상세 화면 한 화면분의 상태.
///
/// - 종목 메타/시세 로드 (관심 스토어에서 아직 못 받아온 경우 대비)
/// - 기간 탭 전환 처리
/// - 일별 시세 페이지 캐싱 + 필요한 만큼만 이어받기
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

  /// 현재 기간에 해당하는 일별 시세를 최신 → 과거 순으로 이어붙여 반환.
  ///
  /// 페이지에 구멍이 있으면 그 시점까지만 채워서 반환한다. (스크롤/차트가
  /// 부분적으로라도 뜨는 편이 자연스러움.)
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

  /// 기간 요구치 대비 페이지 로드가 다 끝났는지.
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

  /// 현재 [_period] 를 채우는 데 필요한 페이지들을 병렬로 받는다.
  ///
  /// 이미 캐시에 있는 페이지는 재요청하지 않는다.
  /// page 1 응답에서 [_knownLastPage] 를 얻으면 그 이상은 요청하지 않는다.
  Future<void> _loadForPeriod() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      // page 1 은 lastPage 를 알아낼 유일한 근거라 먼저 보장.
      if (_pages[1] == null) {
        try {
          final DailyPricePage first =
              await _source.fetchDailyPage(symbol, 1);
          _pages[1] = first;
          _knownLastPage = first.lastPage;
          notifyListeners();
        } catch (_) {
          // page 1 실패면 나머지도 못 받음. 조용히 종료.
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
      // 처음 마주친 lastPage 정보가 있으면 갱신.
      if (_knownLastPage == null && p.lastPage != null) {
        _knownLastPage = p.lastPage;
      }
      notifyListeners();
    } catch (_) {}
  }
}
