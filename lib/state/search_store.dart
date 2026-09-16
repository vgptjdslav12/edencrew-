import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/stock_source.dart';

// 검색 상태. 관심 여부는 WatchlistStore 를 화면에서 같이 구독해 판정.
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

  // 200ms 디바운스, 겹치면 마지막 요청 결과만 반영.
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
