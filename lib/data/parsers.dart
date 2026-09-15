import 'dart:convert';

import 'models.dart';

/// Naver 자동완성 응답 JSON 을 `SearchHit` 목록으로 변환.
///
/// 다음 조건을 통과한 항목만 남긴다.
/// - `category == 'stock'`
/// - `nationCode == 'KOR'` (국내 주식)
/// - `code` 가 정확히 숫자 6자리 (우선주, 리츠 포함)
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

/// Naver 실시간 시세 응답 JSON 을 symbol → Quote 맵으로 변환.
///
/// 여러 심볼을 한 번의 요청으로 조회한 응답을 그대로 넘기면 된다.
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

/// 종목 메타데이터 응답 JSON 을 `StockMeta` 로 변환.
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

/// 일별 시세 HTML 파서.
///
/// finance.naver.com/item/sise_day.naver 응답을 파싱해 [DailyPricePage] 를 만든다.
///
/// - 표의 각 행에서 날짜, 종가, 시가, 고가, 저가, 거래량을 뽑는다.
/// - 상단 헤더 행이나 빈 tr, colspan 만 있는 tr 은 건너뛴다.
/// - 하단 페이지 네비게이션의 `맨뒤` 링크에서 마지막 페이지 번호를 뽑는다.
///   (해당 링크가 없다면 = 이미 마지막 페이지에 도달한 경우)
///
/// 이 파일은 `html` 패키지 없이 정규식만 사용한다. HTML 구조가 매우 단순하고
/// 오랫동안 유지된 형태라 정규식 파싱으로 충분하다고 판단.
DailyPricePage parseDailyPage(String html, int page) {
  final int? lastPage = _extractLastPage(html);

  // <tr> ... </tr> 블록을 하나씩 잡아낸다.
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
    // 빈 tr, colspan 뿐인 tr 제외
    if (inner.contains('colspan=')) continue;

    final RegExpMatch? dm = datePattern.firstMatch(inner);
    if (dm == null) continue;

    // 이 tr 에 나타나는 tah p11 숫자들을 순서대로 뽑는다.
    // 순서: 종가, 전일비(±)의 절대값, 시가, 고가, 저가, 거래량
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
  // 예: <a href="/item/sise_day.naver?code=005930&amp;page=756"  >맨뒤
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
