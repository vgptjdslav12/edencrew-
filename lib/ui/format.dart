import '../data/models.dart';

/// 사람이 읽기 좋은 숫자 포맷 헬퍼.

/// 정수/실수를 천 단위 구분자로 포맷. 소수부는 소수점 아래 자리수 만큼 유지.
String formatPrice(num v, {int fractionDigits = 0}) {
  final String sign = v < 0 ? '-' : '';
  final double abs = v.abs().toDouble();
  final String s = fractionDigits == 0
      ? abs.round().toString()
      : abs.toStringAsFixed(fractionDigits);
  final List<String> parts = s.split('.');
  final String intPart = parts[0];
  final StringBuffer buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    final int fromRight = intPart.length - i;
    buf.write(intPart[i]);
    if (fromRight > 1 && fromRight % 3 == 1) buf.write(',');
  }
  final String result = parts.length == 2 ? '${buf.toString()}.${parts[1]}' : buf.toString();
  return '$sign$result';
}

/// 등락액 문자열. 부호 포함. 상승 +400, 하락 -400, 보합 0.
String formatChangeAmount(num v) {
  if (v == 0) return '0';
  final String sign = v > 0 ? '+' : '-';
  return '$sign${formatPrice(v.abs())}';
}

/// 등락률 문자열. 부호 + 소수 둘째까지.
String formatChangeRate(double rate) {
  final double pct = rate * 100;
  if (pct == 0) return '0.00%';
  final String sign = pct > 0 ? '+' : '-';
  final String body = pct.abs().toStringAsFixed(2);
  return '$sign$body%';
}

/// 시가총액을 조/억 단위로 축약. 예: 1,063조 / 29,113천.
///
/// 거래량과 시가총액 둘 다에 쓴다.
String formatAbbrevKor(num v) {
  if (v.abs() >= 1e12) {
    // 조
    final num inTrillion = (v / 1e12);
    return '${formatPrice(inTrillion, fractionDigits: 0)}조';
  }
  if (v.abs() >= 1e8) {
    return '${formatPrice(v / 1e8, fractionDigits: 0)}억';
  }
  if (v.abs() >= 1e4) {
    return '${formatPrice(v / 1e3, fractionDigits: 0)}천';
  }
  return formatPrice(v);
}

/// `종목코드 · 시장` 표기.
String formatCodeAndMarket(String symbol, String market) {
  if (market.isEmpty) return symbol;
  return '$symbol · $market';
}

/// 등락 방향을 아이콘 문자로 (▲ / ▼ / -).
String directionArrow(PriceDirection d) {
  switch (d) {
    case PriceDirection.up:
      return '▲';
    case PriceDirection.down:
      return '▼';
    case PriceDirection.flat:
      return '-';
  }
}
