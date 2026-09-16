import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/theme.dart';

// 캔들 차트. 축 눈금/거래량 등은 스킵, 상승/하락 색과 위아래 배치만 지킴.
// 데이터는 최신이 앞으로 옴 → 화면상 왼쪽=오래된 순서 되게 뒤집어 그림.
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
    // Y축 범위
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

    // 오래된 → 최신 순으로 그리려고 뒤집음
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
