import 'package:flutter/material.dart';

import '../../theme/theme.dart';

// 스켈레톤 블록. shimmer 없이 단색만 (시안에도 없고 짧게 뜨니 이걸로 충분).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(context.dimens.radiusSm),
      ),
    );
  }
}
