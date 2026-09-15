import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/theme.dart';

/// 캔들 차트.
///
/// 시안의 렌더링 디테일(캔들 두께/간격, 축 눈금)까지 맞추기는 어려워서
/// 요구사항의 필수 항목 — 상승/하락 색상, 위아래 요소 배치가 어긋나지 않는 정도 —
/// 를 우선했다. `chartLineUp` / `chartLineDown` 만 사용.
///
/// 데이터는 최신이 리스트 앞쪽으로 오는 형태로 넘어온다. 화면상 오래된 캔들을
/// 왼쪽에 두려고 그리기 순서를 뒤집는다.
class CandleChart extends StatelessWidget {
  const CandleChart({
    super.key,
    required this.prices,
    this.height = 180,
  });

  final List<DailyPrice> prices;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.textTertiary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CandlePainter(
          prices: prices,
          up: context.colors.chartLineUp,
          down: context.colors.chartLineDown,
          baseline: context.colors.chartBaseline,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.prices,
    required this.up,
    required this.down,
    required this.baseline,
  });

  final List<DailyPrice> prices;
  final Color up;
  final Color down;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    // 최저가/최고가 계산.
    int minP = prices.first.lowPrice;
    int maxP = prices.first.highPrice;
    for (final DailyPrice p in prices) {
      if (p.lowPrice < minP) minP = p.lowPrice;
      if (p.highPrice > maxP) maxP = p.highPrice;
    }
    if (maxP == minP) {
      maxP = minP + 1;
    }
    final double range = (maxP - minP).toDouble();
    final double topPad = 6;
    final double bottomPad = 6;
    final double plotH = size.height - topPad - bottomPad;

    double yFor(num price) {
      final double t = (price - minP) / range;
      return topPad + (1 - t) * plotH;
    }

    // 오래된 → 최신 방향으로 그리기 위해 뒤집는다.
    final List<DailyPrice> ordered = prices.reversed.toList();
    final int n = ordered.length;
    final double slot = size.width / n;
    final double bodyW = (slot * 0.62).clamp(1.5, 8.0);

    final Paint wick = Paint()..strokeWidth = 1;
    final Paint body = Paint();

    for (int i = 0; i < n; i++) {
      final DailyPrice p = ordered[i];
      final double cx = slot * i + slot / 2;
      final Color c = p.closePrice >= p.openPrice ? up : down;

      // 심지
      wick.color = c;
      canvas.drawLine(
        Offset(cx, yFor(p.highPrice)),
        Offset(cx, yFor(p.lowPrice)),
        wick,
      );

      // 몸통
      body.color = c;
      final double yOpen = yFor(p.openPrice);
      final double yClose = yFor(p.closePrice);
      final double top = yOpen < yClose ? yOpen : yClose;
      final double h = (yOpen - yClose).abs().clamp(1.0, plotH);
      canvas.drawRect(
        Rect.fromLTWH(cx - bodyW / 2, top, bodyW, h),
        body,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) {
    return old.prices != prices ||
        old.up != up ||
        old.down != down ||
        old.baseline != baseline;
  }
}
