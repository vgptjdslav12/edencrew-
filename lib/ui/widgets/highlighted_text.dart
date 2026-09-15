import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// `text` 안에서 `query` 와 일치하는 구간에 `searchHighlight` 색을 입힌다.
///
/// - 대소문자 구분 없이 매칭.
/// - `query` 가 빈 문자열이면 원문 그대로 출력.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.baseStyle,
  });

  final String text;
  final String query;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = <TextSpan>[];
    int cursor = 0;

    while (cursor < text.length) {
      final int idx = lowerText.indexOf(lowerQuery, cursor);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }
      if (idx > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + lowerQuery.length),
        style: baseStyle.copyWith(color: context.colors.searchHighlight),
      ));
      cursor = idx + lowerQuery.length;
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
