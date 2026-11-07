import 'package:carhub/features/ai_assistant/data/vin_scanner.dart';
import 'package:carhub/features/ai_assistant/presentation/providers/ai_chat_provider.dart';
import 'package:carhub/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai_assistant_test.dart' show FakeAiRemote;

/// No camera, no ML Kit: returns what the test says and records the source asked for.
class FakeVinScanner implements VinScanner {
  final List<String>? result;
  VinImageSource? asked;

  FakeVinScanner(this.result);

  @override
  Future<List<String>?> scan(VinImageSource source) async {
    asked = source;
    return result;
  }
}

Future<FakeAiRemote> _pump(WidgetTester tester, FakeVinScanner scanner) async {
  tester.view.physicalSize = const Size(1400, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final remote = FakeAiRemote(const []);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      aiChatProvider.overrideWith((ref) => AiChatController(remote)),
      vinScannerProvider.overrideWithValue(scanner),
    ],
    child: MaterialApp(
      home: const AiAssistantScreen(),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
  ));
  await tester.pumpAndSettle();
  return remote;
}

String _input(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;

void main() {
  const vin = '1M8GDM9AXKP042788';

  testWidgets('photo -> VIN shown for confirmation -> placed in the input, nothing sent', (tester) async {
    final scanner = FakeVinScanner([vin]);
    final remote = await _pump(tester, scanner);

    await tester.tap(find.byKey(const Key('scanVinButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التقط صورة لرقم الشاسيه'));
    await tester.pumpAndSettle();

    expect(scanner.asked, VinImageSource.camera);
    expect(find.text('رقم الشاسيه'), findsOneWidget); // the confirm dialog
    await tester.tap(find.text('استخدم الرقم'));
    await tester.pumpAndSettle();

    expect(_input(tester), 'رقم الشاسيه: $vin');
    expect(remote.calls, isEmpty); // the customer sends it, not the scanner
  });

  testWidgets('the customer can correct a misread character before using it', (tester) async {
    await _pump(tester, FakeVinScanner([vin]));
    await tester.tap(find.byKey(const Key('scanVinButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اختر صورة من المعرض'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('vinField')), '1M8GDM9AXKP04278'); // 16 chars
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull); // not a VIN

    await tester.enterText(find.byKey(const Key('vinField')), 'WVWZZZ1KZ6W123456');
    await tester.pump();
    await tester.tap(find.text('استخدم الرقم'));
    await tester.pumpAndSettle();
    expect(_input(tester), 'رقم الشاسيه: WVWZZZ1KZ6W123456');
  });

  testWidgets('no VIN found -> a hint, no dialog', (tester) async {
    await _pump(tester, FakeVinScanner(const []));
    await tester.tap(find.byKey(const Key('scanVinButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التقط صورة لرقم الشاسيه'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ما قدرت أقرأ رقم شاسيه واضح'), findsOneWidget);
    expect(find.text('استخدم الرقم'), findsNothing);
    expect(_input(tester), isEmpty);
  });

  testWidgets('cancelled photo -> nothing happens', (tester) async {
    await _pump(tester, FakeVinScanner(null));
    await tester.tap(find.byKey(const Key('scanVinButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التقط صورة لرقم الشاسيه'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(_input(tester), isEmpty);
  });
}
