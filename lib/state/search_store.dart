import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/stock_source.dart';

/// 검색 화면 상태.
///
/// 관심 등록 여부는 여기서 관리하지 않는다. `WatchlistStore` 를 함께 구독해서
/// 화면에서 판정한다. 이렇게 나눠 둔 이유는 한 종목의 관심 상태가 세 화면에서
/// 어긋나지 않도록 하기 위함.
class SearchStore extends ChangeNotifier {
  SearchStore({required StockSource source}) : _source = source;

  final StockSource _source;

  String _query = '';
  List<SearchHit> _results = const <SearchHit>[];
  bool _loading = false;
  Timer? _debounce;
  int _reqSeq = 0;

  String get query => _query;
  List<SearchHit> get results => _results;
  bool get loading => _loading;

  /// 사용자의 입력이 있을 때 호출.
  ///
  /// 200ms 디바운스 후 요청. 요청이 겹치면 마지막 요청 결과만 반영된다.
  void updateQuery(String next) {
    _query = next;
    _debounce?.cancel();
    if (next.trim().isEmpty) {
      _results = const <SearchHit>[];
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 200), _run);
  }

  Future<void> _run() async {
    final int mySeq = ++_reqSeq;
    final String q = _query;
    try {
      final List<SearchHit> hits = await _source.searchAutocomplete(q);
      if (mySeq != _reqSeq) return; // 더 최근 요청이 있음. 결과 버림.
      _results = hits;
      _loading = false;
      notifyListeners();
    } catch (_) {
      if (mySeq != _reqSeq) return;
      _results = const <SearchHit>[];
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _debounce?.cancel();
    _query = '';
    _results = const <SearchHit>[];
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
