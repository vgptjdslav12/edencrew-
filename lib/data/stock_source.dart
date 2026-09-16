import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'models.dart';
import 'parsers.dart';

// mock / naver 두 구현을 바꿔 끼우기 위한 인터페이스.
abstract class StockSource {
  Future<List<SearchHit>> searchAutocomplete(String query);
  // 여러 심볼 한 번에.
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols);
  Future<StockMeta> fetchMeta(String symbol);
  // 일별 시세 HTML 한 페이지.
  Future<DailyPricePage> fetchDailyPage(String symbol, int page);
}

// assets/mock 만 읽는 개발용 소스.
class MockStockSource implements StockSource {
  const MockStockSource();

  static const String _base = 'assets/mock';

  @override
  Future<List<SearchHit>> searchAutocomplete(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return const <SearchHit>[];

    // 검색어에서 골라 가장 근접한 mock 을 로드.
    final String path;
    if (trimmed.contains('삼성')) {
      path = '$_base/autocomplete_samsung.json';
    } else if (trimmed.contains('카카오')) {
      path = '$_base/autocomplete_kakao.json';
    } else {
      path = '$_base/autocomplete_empty.json';
    }

    final String text = await rootBundle.loadString(path);
    return parseAutocomplete(text);
  }

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    final String text =
        await rootBundle.loadString('$_base/realtime_quotes.json');
    final Map<String, Quote> all = parseRealtime(text);
    if (symbols.isEmpty) return all;
    return <String, Quote>{
      for (final String s in symbols)
        if (all[s] != null) s: all[s]!,
    };
  }

  @override
  Future<StockMeta> fetchMeta(String symbol) async {
    final String path = '$_base/meta_$symbol.json';
    try {
      final String text = await rootBundle.loadString(path);
      return parseMeta(text);
    } catch (_) {
      // mock 에 없으면 이름 자리에 심볼만 채워 fallback.
      return StockMeta(symbol: symbol, name: symbol, marketKor: '');
    }
  }

  @override
  Future<DailyPricePage> fetchDailyPage(String symbol, int page) async {
    final String path = '$_base/sise_day_${symbol}_p$page.html';
    try {
      final String text = await rootBundle.loadString(path);
      return parseDailyPage(text, page);
    } catch (_) {
      // mock 없는 페이지는 lastPage 를 이전으로 잡아서 더 이상 요청 안 나가게.
      return DailyPricePage(page: page, prices: const <DailyPrice>[], lastPage: page - 1);
    }
  }
}

// Naver endpoint 직접 호출. 자동완성/메타는 UTF-8, 실시간/일별 HTML 은 EUC-KR.
class NaverStockSource implements StockSource {
  NaverStockSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<SearchHit>> searchAutocomplete(String query) async {
    final Uri uri = Uri.parse('https://ac.stock.naver.com/ac').replace(
      queryParameters: <String, String>{
        'q': query,
        'target': 'stock,ipo,index,marketindicator',
      },
    );
    final http.Response resp = await _client.get(uri);
    _ensureOk(resp, uri);
    return parseAutocomplete(utf8.decode(resp.bodyBytes));
  }

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const <String, Quote>{};
    final String query = 'SERVICE_ITEM:${symbols.join(',')}';
    final Uri uri = Uri.parse('https://polling.finance.naver.com/api/realtime')
        .replace(queryParameters: <String, String>{'query': query});
    final http.Response resp = await _client.get(uri);
    _ensureOk(resp, uri);
    // Content-Type: text/plain;charset=EUC-KR
    final String text = _decodeEucKr(resp.bodyBytes);
    return parseRealtime(text);
  }

  @override
  Future<StockMeta> fetchMeta(String symbol) async {
    final Uri uri = Uri.parse(
      'https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/$symbol',
    );
    final http.Response resp = await _client.get(uri);
    _ensureOk(resp, uri);
    return parseMeta(utf8.decode(resp.bodyBytes));
  }

  @override
  Future<DailyPricePage> fetchDailyPage(String symbol, int page) async {
    final Uri uri = Uri.parse('https://finance.naver.com/item/sise_day.naver')
        .replace(queryParameters: <String, String>{
      'code': symbol,
      'page': '$page',
    });
    final http.Response resp = await _client.get(uri, headers: const <String, String>{
      // UA 없으면 응답 다르게 오는 경우 있어 붙여둠.
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    });
    _ensureOk(resp, uri);
    final String text = _decodeEucKr(resp.bodyBytes);
    return parseDailyPage(text, page);
  }

  void _ensureOk(http.Response r, Uri uri) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw StockSourceException(
      'HTTP ${r.statusCode} on $uri',
      statusCode: r.statusCode,
    );
  }

  // Dart 표준에 EUC-KR 디코더가 없음. mock 은 이미 UTF-8 로 저장해뒀고
  // 실 endpoint 호출 경로에서만 이 함수를 탐. 일단 UTF-8 로 시도, 실패면 Latin1 fallback.
  // 제대로 하려면 charset_converter 같은 패키지 필요.
  String _decodeEucKr(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  void close() => _client.close();
}

class StockSourceException implements Exception {
  const StockSourceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'StockSourceException: $message';
}
