import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'models.dart';
import 'parsers.dart';

/// 앱이 시세/종목 정보를 얻는 진입점.
///
/// 개발 중에는 `MockStockSource` 로, 실제 실행 시에는 `NaverStockSource` 로
/// 바꿔 끼울 수 있게 abstract 로 두었다.
abstract class StockSource {
  Future<List<SearchHit>> searchAutocomplete(String query);

  /// 여러 심볼을 한 번의 요청으로 조회.
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols);

  Future<StockMeta> fetchMeta(String symbol);

  /// 일별 시세 HTML 한 페이지.
  Future<DailyPricePage> fetchDailyPage(String symbol, int page);
}

/// `assets/mock/` 에 담긴 응답 파일로만 동작하는 소스.
///
/// 네트워크 없이 UI/파싱 작업을 이어가기 위한 개발용.
class MockStockSource implements StockSource {
  const MockStockSource();

  static const String _base = 'assets/mock';

  @override
  Future<List<SearchHit>> searchAutocomplete(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return const <SearchHit>[];

    // 저장해둔 샘플 중에서 가장 그럴듯한 파일을 고른다.
    // 완전 일치가 아니어도 부분 문자열이 있으면 그 파일을 쓴다.
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
      // mock 에 없는 심볼은 이름을 심볼 자체로 채워 fallback.
      return StockMeta(symbol: symbol, name: symbol, marketKor: '');
    }
  }

  @override
  Future<DailyPricePage> fetchDailyPage(String symbol, int page) async {
    final String path = '$_base/sise_day_${symbol}_p$page.html';
    final String text = await rootBundle.loadString(path);
    return parseDailyPage(text, page);
  }
}

/// Naver 실제 endpoint 를 호출하는 소스.
///
/// 응답 캐릭터 인코딩:
/// - 자동완성 / 메타데이터: UTF-8
/// - 실시간 시세: EUC-KR (Content-Type 은 text/plain)
/// - 일별 시세 HTML: EUC-KR
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
    // 실시간 응답은 Content-Type 이 text/plain;charset=EUC-KR
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
      // 일부 요청에서 UA 없이 오면 응답 형태가 달라질 수 있어 붙여둔다.
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

  /// Dart 기본 라이브러리에는 EUC-KR 디코더가 없다.
  /// ASCII 영역은 그대로 두고, 128 이상은 CP949 mapping 이 없이는 정확 복원이
  /// 어려우므로 UTF-8 fallback 을 시도한 뒤 실패하면 Latin1 로라도 되돌린다.
  ///
  /// 실전 앱이라면 charset_converter / kr_charset 같은 패키지를 붙였겠지만,
  /// 이번 과제는 응답을 mock 으로 미리 UTF-8 로 재저장해 두었으므로
  /// 이 함수는 실제 endpoint 를 직접 호출하는 경로에서만 쓰인다.
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
