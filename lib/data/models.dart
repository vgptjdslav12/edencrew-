import 'package:meta/meta.dart';

/// 상승/하락/보합.
enum PriceDirection { up, down, flat }

/// 검색 자동완성 결과 한 건.
@immutable
class SearchHit {
  const SearchHit({
    required this.symbol,
    required this.name,
    required this.market,
  });

  /// 6자리 종목코드. 예: `005930`.
  final String symbol;

  /// 종목명. 예: `삼성전자`.
  final String name;

  /// 시장 표기. 예: `코스피`.
  final String market;

  /// 앱 내부에서 종목을 식별하는 canonical id.
  String get canonicalId => 'domestic:$symbol';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHit &&
          other.symbol == symbol &&
          other.name == name &&
          other.market == market);

  @override
  int get hashCode => Object.hash(symbol, name, market);
}

/// 실시간 시세 한 건.
@immutable
class Quote {
  const Quote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.accumulatedVolume,
    this.listedShares,
  });

  final String symbol;
  final num currentPrice;
  final num previousClose;
  final num open;
  final num high;
  final num low;
  final num accumulatedVolume;

  /// 상장 주식 수. 시가총액 계산에 사용.
  final num? listedShares;

  num get changeAmount => currentPrice - previousClose;

  double get changeRate {
    if (previousClose == 0) return 0;
    return (currentPrice - previousClose) / previousClose;
  }

  PriceDirection get direction {
    final num d = changeAmount;
    if (d > 0) return PriceDirection.up;
    if (d < 0) return PriceDirection.down;
    return PriceDirection.flat;
  }

  /// 시가총액 = 현재가 × 상장 주식 수.
  num? get marketCap {
    if (listedShares == null) return null;
    return currentPrice * listedShares!;
  }
}

/// 종목 메타데이터.
@immutable
class StockMeta {
  const StockMeta({
    required this.symbol,
    required this.name,
    required this.marketKor,
  });

  final String symbol;
  final String name;

  /// 국내 거래소명 한글. 예: `코스피`.
  final String marketKor;
}

/// 일별 시세 한 행.
@immutable
class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
  });

  final DateTime date;
  final int closePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int volume;
}

/// 일별 시세 한 페이지.
@immutable
class DailyPricePage {
  const DailyPricePage({
    required this.page,
    required this.prices,
    required this.lastPage,
  });

  final int page;
  final List<DailyPrice> prices;

  /// HTML 페이지네이션 하단 `맨뒤` 링크에서 뽑아낸 마지막 페이지 번호.
  final int? lastPage;
}
