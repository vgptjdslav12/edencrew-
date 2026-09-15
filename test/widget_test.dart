import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/main.dart';

void main() {
  testWidgets('앱이 뜨면 관심 탭 빈 상태가 노출된다', (WidgetTester tester) async {
    await tester.pumpWidget(const EdencrewAssignmentApp());
    await tester.pumpAndSettle();

    // 상단 헤더
    expect(find.text('관심'), findsOneWidget);
    // 빈 상태 문구
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    // 하단 탭 바
    expect(find.text('검색'), findsOneWidget);
  });
}
