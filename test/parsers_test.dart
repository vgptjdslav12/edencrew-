import 'dart:io';

import 'package:edencrew_assignment_starter/data/models.dart';
import 'package:edencrew_assignment_starter/data/parsers.dart';
import 'package:flutter_test/flutter_test.dart';

String _readMock(String name) {
  return File('assets/mock/$name').readAsStringSync();
}

void main() {
  group('parseAutocomplete', () {
    test('삼성 응답에서 국내 stock 항목만 남긴다', () {
      final List<SearchHit> hits =
          parseAutocomplete(_readMock('autocomplete_samsung.json'));

      expect(hits, isNotEmpty);
      // 6자리 종목코드만
      for (final SearchHit h in hits) {
        expect(RegExp(r'^\d{6}$').hasMatch(h.symbol), isTrue);
        expect(h.market.isNotEmpty, isTrue);
      }
      // 삼성전자 포함
      expect(hits.any((SearchHit h) => h.symbol == '005930'), isTrue);
    });

    test('빈 결과 응답은 빈 리스트를 돌려준다', () {
      final List<SearchHit> hits =
          parseAutocomplete(_readMock('autocomplete_empty.json'));
      expect(hits, isEmpty);
    });
  });

  group('parseRealtime', () {
    test('symbol → Quote 맵으로 변환된다', () {
      final Map<String, Quote> map =
          parseRealtime(_readMock('realtime_quotes.json'));
      expect(map, isNotEmpty);
      expect(map['005930'], isNotNull);
      final Quote q = map['005930']!;
      // 등락액 = nv - pcv
      expect(q.changeAmount, q.currentPrice - q.previousClose);
      // 등락률 = (nv - pcv) / pcv
      expect(
        q.changeRate,
        closeTo((q.currentPrice - q.previousClose) / q.previousClose, 1e-9),
      );
      // 시가총액 = nv × 상장주식수
      expect(q.marketCap, q.currentPrice * (q.listedShares ?? 0));
    });
  });

  group('parseMeta', () {
    test('symbolCode/stockName/stockExchangeNameKor 를 뽑는다', () {
      final StockMeta m = parseMeta(_readMock('meta_005930.json'));
      expect(m.symbol, '005930');
      expect(m.name, '삼성전자');
      expect(m.marketKor, '코스피');
    });
  });

  group('parseDailyPage', () {
    test('삼성 1페이지에서 최소 몇 개의 일자를 뽑는다', () {
      final DailyPricePage page = parseDailyPage(
        _readMock('sise_day_005930_p1.html'),
        1,
      );
      expect(page.prices, isNotEmpty);
      // 각 행에 필요한 값들이 정상 파싱됐는지
      for (final DailyPrice p in page.prices) {
        expect(p.closePrice, greaterThan(0));
        expect(p.openPrice, greaterThan(0));
        expect(p.highPrice, greaterThan(0));
        expect(p.lowPrice, greaterThan(0));
        expect(p.volume, greaterThan(0));
      }
      // 하단 페이지 네비게이션에서 lastPage 추출
      expect(page.lastPage, isNotNull);
      expect(page.lastPage!, greaterThan(1));
    });
  });
}
