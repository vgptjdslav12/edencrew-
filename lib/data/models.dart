import 'package:meta/meta.dart';

enum PriceDirection { up, down, flat }

@immutable
class SearchHit {
  const SearchHit({
    required this.symbol,
    required this.name,
    required this.market,
  });

  final String symbol; // 6자리 종목코드
  final String name;
  final String market; // 예: 코스피

  // 앱 내부 canonical id
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

  final num? listedShares; // 시가총액 계산용

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

  // 현재가 × 상장주식수
  num? get marketCap {
    if (listedShares == null) return null;
    return currentPrice * listedShares!;
  }
}

@immutable
class StockMeta {
  const StockMeta({
    required this.symbol,
    required this.name,
    required this.marketKor,
  });

  final String symbol;
  final String name;
  final String marketKor; // 예: 코스피
}

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

@immutable
class DailyPricePage {
  const DailyPricePage({
    required this.page,
    required this.prices,
    required this.lastPage,
  });

  final int page;
  final List<DailyPrice> prices;
  final int? lastPage; // "맨뒤" 링크에서 뽑음. 없으면 null
}
