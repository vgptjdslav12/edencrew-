import 'dart:convert';

import 'models.dart';

// 자동완성 응답 → SearchHit. category=stock, nationCode=KOR, code 6자리만 남김.
List<SearchHit> parseAutocomplete(String jsonText) {
  final dynamic decoded = json.decode(jsonText);
  if (decoded is! Map || decoded['items'] is! List) {
    return const <SearchHit>[];
  }

  final RegExp codePattern = RegExp(r'^\d{6}$');
  final List<SearchHit> out = <SearchHit>[];

  for (final dynamic raw in decoded['items'] as List<dynamic>) {
    if (raw is! Map) continue;
    final String? category = raw['category'] as String?;
    final String? nation = raw['nationCode'] as String?;
    final String? code = raw['code'] as String?;
    final String? name = raw['name'] as String?;
    final String? typeName = raw['typeName'] as String?;

    if (category != 'stock') continue;
    if (nation != 'KOR') continue;
    if (code == null || !codePattern.hasMatch(code)) continue;
    if (name == null || name.isEmpty) continue;

    out.add(SearchHit(
      symbol: code,
      name: name,
      market: typeName ?? '',
    ));
  }

  return out;
}

// 실시간 시세 응답 → symbol별 Quote 맵.
Map<String, Quote> parseRealtime(String jsonText) {
  final dynamic decoded = json.decode(jsonText);
  if (decoded is! Map) return const <String, Quote>{};

  final dynamic result = decoded['result'];
  if (result is! Map) return const <String, Quote>{};

  final dynamic areas = result['areas'];
  if (areas is! List) return const <String, Quote>{};

  final Map<String, Quote> out = <String, Quote>{};

  for (final dynamic area in areas) {
    if (area is! Map) continue;
    final dynamic datas = area['datas'];
    if (datas is! List) continue;

    for (final dynamic row in datas) {
      if (row is! Map) continue;
      final String? symbol = row['cd'] as String?;
      final num? nv = _num(row['nv']);
      final num? pcv = _num(row['pcv']);
      if (symbol == null || nv == null || pcv == null) continue;

      out[symbol] = Quote(
        symbol: symbol,
        currentPrice: nv,
        previousClose: pcv,
        open: _num(row['ov']) ?? nv,
        high: _num(row['hv']) ?? nv,
        low: _num(row['lv']) ?? nv,
        accumulatedVolume: _num(row['aq']) ?? 0,
        listedShares: _num(row['countOfListedStock']),
      );
    }
  }

  return out;
}

// 메타 응답 → StockMeta.
StockMeta parseMeta(String jsonText) {
  final dynamic decoded = json.decode(jsonText);
  if (decoded is! Map) {
    throw const FormatException('meta 응답이 JSON 객체가 아님');
  }
  final String? code = decoded['symbolCode'] as String?;
  final String? name = decoded['stockName'] as String?;
  final String? marketKor = decoded['stockExchangeNameKor'] as String?;
  if (code == null || name == null || marketKor == null) {
    throw const FormatException('meta 응답에 symbolCode/stockName/stockExchangeNameKor 누락');
  }
  return StockMeta(symbol: code, name: name, marketKor: marketKor);
}

num? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v.replaceAll(',', ''));
  return null;
}

// 일별 시세 HTML → DailyPricePage.
// 구조가 오래된 정적 테이블이라 html 패키지 없이 정규식으로 충분함.
// 각 tr 에서 날짜/종가/시가/고가/저가/거래량 뽑고, 하단 "맨뒤" 링크에서 lastPage 뽑음.
DailyPricePage parseDailyPage(String html, int page) {
  final int? lastPage = _extractLastPage(html);

  final RegExp trPattern = RegExp(
    r'<tr[^>]*>([\s\S]*?)</tr>',
    caseSensitive: false,
  );
  final RegExp datePattern = RegExp(r'(\d{4})\.(\d{2})\.(\d{2})');
  final RegExp numberInSpan = RegExp(
    r'<span[^>]*class="[^"]*tah p11[^"]*"[^>]*>\s*([\-\d,\.]+)\s*</span>',
    caseSensitive: false,
  );

  final List<DailyPrice> rows = <DailyPrice>[];

  for (final RegExpMatch m in trPattern.allMatches(html)) {
    final String inner = m.group(1) ?? '';
    // 빈/헤더 행 skip
    if (inner.contains('colspan=')) continue;

    final RegExpMatch? dm = datePattern.firstMatch(inner);
    if (dm == null) continue;

    // 숫자 순서: 종가, 전일비 절대값, 시가, 고가, 저가, 거래량
    final List<String> nums = numberInSpan
        .allMatches(inner)
        .map((RegExpMatch e) => e.group(1) ?? '')
        .toList();

    if (nums.length < 6) continue;

    final int? close = _parseInt(nums[0]);
    final int? open = _parseInt(nums[2]);
    final int? high = _parseInt(nums[3]);
    final int? low = _parseInt(nums[4]);
    final int? volume = _parseInt(nums[5]);

    if (close == null ||
        open == null ||
        high == null ||
        low == null ||
        volume == null) {
      continue;
    }

    final int year = int.parse(dm.group(1)!);
    final int month = int.parse(dm.group(2)!);
    final int day = int.parse(dm.group(3)!);

    rows.add(DailyPrice(
      date: DateTime(year, month, day),
      closePrice: close,
      openPrice: open,
      highPrice: high,
      lowPrice: low,
      volume: volume,
    ));
  }

  return DailyPricePage(page: page, prices: rows, lastPage: lastPage);
}

int? _extractLastPage(String html) {
  // <a href="...page=756">맨뒤 형태
  final RegExp lastPageInLink = RegExp(
    r'page=(\d+)[^>]*>[^<]*맨뒤',
    caseSensitive: false,
  );
  final RegExpMatch? m = lastPageInLink.firstMatch(html);
  if (m == null) return null;
  return int.tryParse(m.group(1) ?? '');
}

int? _parseInt(String raw) {
  final String cleaned = raw.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  return int.tryParse(cleaned);
}
