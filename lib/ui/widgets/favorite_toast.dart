import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

// 관심 등록/해제 시 잠깐 뜨는 토스트.
// 시안 미지정: 1.8초 노출, 220ms fade + 4px slide (직접 판단, README).
class FavoriteToast extends StatelessWidget {
  const FavoriteToast({
    super.key,
    required this.registered,
  });

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

// 하단 토스트 컨트롤러. 화면이 하나 들고 있다가 별 탭 시 show().
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

// 하단에 fade/slide 로 토스트 얹는 위젯.
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
