import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 시세를 아직 받지 못한 행에서 쓰는 스켈레톤 블록.
///
/// `feedbackSkeleton` 색으로 단색 블록만 그린다. 애니메이션은 붙이지 않았음.
/// 시안에도 shimmer 가 없고, 실제 앱에서 잠깐만 노출되기 때문에 단색으로 충분.
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
