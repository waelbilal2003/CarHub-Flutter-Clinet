// اختبار بسيط للتأكد أن التطبيق يقلع دون أخطاء.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carhub/main.dart';

void main() {
  testWidgets('التطبيق يقلع ويعرض شاشة البداية', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CarHubApp()));
    await tester.pump();
    // شاشة البداية تحتوي اسم التطبيق.
    expect(find.text('CarHub'), findsWidgets);
  });
}
