import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 검색 화면에서 관심 등록/해제 시 잠깐 뜨는 토스트.
///
/// 시안에 정의되지 않은 사항 (직접 판단 · README 에 기록):
/// - 노출 시간: 1.8초. 사용자가 뭐라고 뜬 건지 읽을 수 있으면서 화면을 오래
///   가리지 않도록 잡음.
/// - 등장/퇴장 방식: 220ms fade + 4px 상방향 slide. 시안에 애니메이션 지정이
///   없어서 감각적으로만.
class FavoriteToast extends StatelessWidget {
  const FavoriteToast({
    super.key,
    required this.registered,
  });

  /// true 이면 `관심이 등록되었습니다` + 채워진 별, false 면 반대.
  final bool registered;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            registered ? Icons.star : Icons.star_outline,
            color: registered ? colors.favoriteActive : colors.favoriteInactive,
            size: dimens.iconMd,
          ),
          SizedBox(width: dimens.space2),
          Text(
            registered ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 토스트를 화면 하단에 잠깐 띄우는 컨트롤러.
///
/// 검색 화면이 이 컨트롤러 하나를 갖고 있으면서, 별 아이콘 탭 시 `show(...)` 를 부른다.
class ToastController extends ChangeNotifier {
  Widget? _current;
  Timer? _timer;

  Widget? get current => _current;

  void show(Widget child, {Duration duration = const Duration(milliseconds: 1800)}) {
    _timer?.cancel();
    _current = child;
    notifyListeners();
    _timer = Timer(duration, () {
      _current = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 화면 하단에 토스트를 fade/slide 로 얹어주는 위젯.
class ToastOverlay extends StatelessWidget {
  const ToastOverlay({super.key, required this.controller, required this.child});

  final ToastController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, _) {
            final Widget? toast = controller.current;
            return Positioned(
              left: 0,
              right: 0,
              bottom: context.dimens.space6 + MediaQuery.of(context).padding.bottom,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget c, Animation<double> a) {
                    return FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(a),
                        child: c,
                      ),
                    );
                  },
                  child: toast == null
                      ? const SizedBox.shrink(key: ValueKey<String>('empty'))
                      : Center(
                          key: const ValueKey<String>('toast'),
                          child: toast,
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
