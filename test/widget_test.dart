import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/main.dart';

void main() {
  testWidgets('앱이 뜨면 관심 탭 빈 상태가 노출된다', (WidgetTester tester) async {
    await tester.pumpWidget(const EdencrewAssignmentApp());
    await tester.pumpAndSettle();

    // 헤더 + 하단 탭 라벨 두 곳에서 노출
    expect(find.text('관심'), findsNWidgets(2));
    // 빈 상태 문구
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    // 하단 탭 바
    expect(find.text('검색'), findsOneWidget);
  });
}
