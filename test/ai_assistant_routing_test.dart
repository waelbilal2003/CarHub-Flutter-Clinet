import 'package:carhub/core/errors/failures.dart';
import 'package:carhub/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:carhub/features/ai_assistant/domain/entities/ai_reply.dart';
import 'package:carhub/features/ai_assistant/presentation/providers/ai_chat_provider.dart';
import 'package:carhub/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'ai_assistant_test.dart' show FakeAiRemote, contractReply;

/// Destination screens are stubs that print the location they were opened with.
GoRouter _router() => GoRouter(initialLocation: '/assistant', routes: [
      GoRoute(path: '/assistant', builder: (_, __) => const AiAssistantScreen()),
      GoRoute(path: '/market', builder: (_, s) => Scaffold(body: Text('MARKET ${s.uri}'))),
      GoRoute(
          path: '/market/product/:id',
          builder: (_, s) => Scaffold(body: Text('PRODUCT ${s.pathParameters['id']}'))),
      GoRoute(path: '/tenders/create', builder: (_, s) => Scaffold(body: Text('TENDER ${s.uri}'))),
    ]);

/// Opens the assistant after one exchange whose answer is [result] (AiReply or Failure).
Future<void> _pumpAfter(WidgetTester tester, Object result) async {
  tester.view.physicalSize = const Size(1400, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = AiChatController(FakeAiRemote([result]));
  await controller.send('سؤال');
  final router = _router();
  await tester.pumpWidget(ProviderScope(
    overrides: [aiChatProvider.overrideWith((ref) => controller)],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
  ));
  await tester.pumpAndSettle();
}

AiReply _replyWithCards(List<Map<String, dynamic>> cards, {List<Map<String, dynamic>>? products}) {
  final json = contractReply();
  json['cards'] = cards;
  json['followup'] = null;
  if (products != null) json['products'] = products;
  return AiReply.fromJson(json);
}

Map<String, dynamic> _product(int id, String title) => {
      'id': id, 'title': title, 'price': '420.00', 'currency': 'SAR', 'image_url': null,
      'merchant_name': 'متجر الأمان', 'city': 'الرياض', 'compatibility': 'exact',
    };

DioException _dio({int? status, Object? data, DioExceptionType type = DioExceptionType.badResponse}) {
  final req = RequestOptions(path: '/ai/ask');
  return DioException(
    requestOptions: req,
    type: type,
    response: status == null ? null : Response(requestOptions: req, statusCode: status, data: data),
  );
}

/// The location the pushed stub screen was opened with ("MARKET <uri>", "PRODUCT <id>", "TENDER <uri>").
Uri _opened(WidgetTester tester, String prefix) {
  final text = tester.widget<Text>(find.textContaining('$prefix ')).data!;
  return Uri.parse(text.substring(prefix.length + 1));
}

void main() {
  // Cards are opened with their button ('تسوق الآن' / 'ابحث في السوق' / 'اطلب عروض أسعار'), as on the phone.
  group('card routing (tap -> screen)', () {
    testWidgets('open_product with one id opens product details', (tester) async {
      await _pumpAfter(tester, _replyWithCards([
        {'type': 'open_product', 'label': 'عرض المنتج', 'payload': {'product_ids': [16]}},
      ], products: [_product(16, 'مصباح أمامي يمين')]));

      await tester.tap(find.text('تسوق الآن'));
      await tester.pumpAndSettle();
      expect(find.text('PRODUCT 16'), findsOneWidget);
    });

    testWidgets('open_product with several ids lists them; tapping one opens its details', (tester) async {
      await _pumpAfter(tester, _replyWithCards([
        {'type': 'open_product', 'label': 'عرض المصابيح المتوافقة', 'payload': {'product_ids': [16, 17]}},
      ], products: [_product(16, 'مصباح يمين'), _product(17, 'مصباح يسار')]));

      await tester.tap(find.text('تسوق الآن'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('مصباح يسار')));
      await tester.pumpAndSettle();
      expect(find.text('PRODUCT 17'), findsOneWidget);
    });

    testWidgets('a product card opens product details', (tester) async {
      await _pumpAfter(tester, _replyWithCards([], products: [_product(19, 'مصباح خلفي')]));
      await tester.tap(find.text('مصباح خلفي'));
      await tester.pumpAndSettle();
      expect(find.text('PRODUCT 19'), findsOneWidget);
    });

    testWidgets('open_marketplace_search passes query and filters as given', (tester) async {
      await _pumpAfter(tester, _replyWithCards([
        {
          'type': 'open_marketplace_search',
          'label': 'ابحث عن فحمات فرامل',
          'payload': {'query': 'فحمات فرامل', 'filters': {'car_make': 'Kia', 'car_model': 'Sportage', 'year': 2018}},
        },
      ]));

      await tester.tap(find.text('ابحث في السوق'));
      await tester.pumpAndSettle();
      final uri = _opened(tester, 'MARKET');
      expect(uri.path, '/market');
      expect(uri.queryParameters,
          {'search': 'فحمات فرامل', 'car_make': 'Kia', 'car_model': 'Sportage', 'year': '2018'});
    });

    testWidgets('open_marketplace_search with empty filters sends the query only', (tester) async {
      await _pumpAfter(tester, _replyWithCards([
        {'type': 'open_marketplace_search', 'label': 'ابحث عن فحمات', 'payload': {'query': 'فحمات فرامل', 'filters': {}}},
      ]));
      await tester.tap(find.text('ابحث في السوق'));
      await tester.pumpAndSettle();
      expect(_opened(tester, 'MARKET').queryParameters, {'search': 'فحمات فرامل'});
    });

    testWidgets('create_tender opens the tender form prefilled', (tester) async {
      await _pumpAfter(tester, _replyWithCards([
        {
          'type': 'create_tender',
          'label': 'اطلب عروض',
          'payload': {'category': 'paint_body', 'title': 'رش المصد', 'city': 'الرياض'},
        },
      ]));

      await tester.tap(find.text('اطلب عروض أسعار'));
      await tester.pumpAndSettle();
      final uri = _opened(tester, 'TENDER');
      expect(uri.path, '/tenders/create');
      expect(uri.queryParameters, {'category': 'paint_body', 'title': 'رش المصد', 'city': 'الرياض'});
    });

    testWidgets('create_tender with the car and VIN prefills the description too', (tester) async {
      const desc = 'السيارة: كيا سبورتاج 2019\nرقم الشاسيه (VIN): KNAPB81ABK7123456\nوصف المشكلة: بدي ارش المصد';
      await _pumpAfter(tester, _replyWithCards([
        {
          'type': 'create_tender',
          'label': 'اطلب عروض',
          'payload': {'category': 'paint_body', 'title': 'رش المصد', 'city': 'برلين', 'description': desc},
        },
      ]));

      await tester.tap(find.text('اطلب عروض أسعار'));
      await tester.pumpAndSettle();
      final uri = _opened(tester, 'TENDER');
      expect(uri.queryParameters['description'], desc);              // line breaks survive the route
    });

    testWidgets('open_policy and unknown card types are ignored safely', (tester) async {
      await _pumpAfter(tester, _replyWithCards([
        {'type': 'open_policy', 'label': 'سياسة الإرجاع', 'payload': {}},
        {'type': 'something_new', 'label': 'نوع جديد', 'payload': {'x': 1}},
      ]));
      expect(find.text('سياسة الإرجاع'), findsNothing);
      expect(find.text('نوع جديد'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('error states (mapAiError)', () {
    test('503 -> gentle unavailable message, retryable kind', () {
      final f = AiRemoteDataSource.mapAiError(_dio(status: 503, data: {
        'success': false, 'message': 'المساعد غير متاح حالياً', 'errors': {'code': ['AI_UNAVAILABLE']},
      }));
      expect(f, isA<ServerFailure>());
      expect(f.message, AiRemoteDataSource.unavailableMessage);
    });

    test('403 -> clients only', () {
      final f = AiRemoteDataSource.mapAiError(_dio(status: 403, data: {
        'success': false, 'message': 'لا تملك الصلاحية المخصصة لهذا النوع من المستخدمين',
      }));
      expect(f, isA<AuthFailure>());
      expect(f.message, AiRemoteDataSource.clientsOnlyMessage);
    });

    test('422 never shows untranslated server keys', () {
      Failure f422(Map errors) => AiRemoteDataSource.mapAiError(_dio(status: 422, data: {
            'success': false, 'message': 'بيانات المدخلات غير صالحة', 'errors': errors,
          }));
      expect(f422({'message': ['validation.required']}).message, AiRemoteDataSource.invalidMessageText);
      expect(f422({'message': ['validation.max.string']}).message, AiRemoteDataSource.invalidMessageText);
      expect(f422({'conversation_id': ['validation.exists']}).message,
          AiRemoteDataSource.conversationGoneMessage);
      expect(f422({}).message, AiRemoteDataSource.invalidRequestMessage);
      expect(f422({'message': ['validation.required']}), isA<ValidationFailure>());
    });

    test('429 from throttle (not in the project envelope) -> its message only', () {
      final f = AiRemoteDataSource.mapAiError(_dio(status: 429, data: {'message': 'Too Many Attempts.'}));
      expect(f, isA<ValidationFailure>());
      expect(f.message, AiRemoteDataSource.tooManyMessage);
    });

    test('429 AI_TOO_FAST -> "wait a moment" (not counted, not the limit)', () {
      final f = AiRemoteDataSource.mapAiError(_dio(status: 429, data: {
        'success': false, 'message': 'انتظر لحظة', 'errors': {'code': ['AI_TOO_FAST']}, 'data': {'retry_after_s': 2},
      }));
      expect(f, isA<ValidationFailure>());
      expect(f.message, AiRemoteDataSource.tooFastMessage);
      expect(AiRemoteDataSource.limitReached(_dio(status: 429, data: {'errors': {'code': ['AI_TOO_FAST']}})), isNull);
    });

    test('429 AI_LIMIT_REACHED daily / monthly -> limit with ad option', () {
      AiLimitReached? limit(Map<String, dynamic> data) => AiRemoteDataSource.limitReached(_dio(status: 429, data: {
            'success': false, 'message': 'x', 'errors': {'code': ['AI_LIMIT_REACHED']}, 'data': data,
          }));
      final daily = limit({'limit': 'daily', 'can_watch_ad': true, 'ads_remaining_today': 4})!;
      expect((daily.limit, daily.canWatchAd, daily.adsRemainingToday, daily.message),
          ('daily', true, 4, AiRemoteDataSource.dailyLimitMessage));
      final monthly = limit({'limit': 'monthly', 'can_watch_ad': false, 'ads_remaining_today': 5})!;
      expect((monthly.limit, monthly.canWatchAd, monthly.message), ('monthly', false, AiRemoteDataSource.monthlyLimitMessage));
      expect(AiRemoteDataSource.limitReached(_dio(status: 503, data: {})), isNull);
    });

    test('receive timeout -> timeout message', () {
      final f = AiRemoteDataSource.mapAiError(_dio(type: DioExceptionType.receiveTimeout));
      expect(f, isA<NetworkFailure>());
      expect(f.message, AiRemoteDataSource.timeoutMessage);
    });

    test('no network -> network failure', () {
      expect(AiRemoteDataSource.mapAiError(_dio(type: DioExceptionType.connectionError)), isA<NetworkFailure>());
    });
  });

  group('error states on screen', () {
    Future<void> expectError(WidgetTester tester, Failure failure, {required bool retry}) async {
      await _pumpAfter(tester, failure);
      expect(find.text(failure.message), findsOneWidget);
      expect(find.text('إعادة المحاولة'), retry ? findsOneWidget : findsNothing);
    }

    testWidgets('503 -> message + retry', (t) =>
        expectError(t, const ServerFailure(AiRemoteDataSource.unavailableMessage), retry: true));
    testWidgets('network loss -> message + retry', (t) =>
        expectError(t, const NetworkFailure(), retry: true));
    testWidgets('timeout -> message + retry', (t) =>
        expectError(t, const NetworkFailure(AiRemoteDataSource.timeoutMessage), retry: true));
    testWidgets('403 -> message, no retry', (t) =>
        expectError(t, const AuthFailure(AiRemoteDataSource.clientsOnlyMessage), retry: false));
    testWidgets('422 -> message, no retry', (t) =>
        expectError(t, const ValidationFailure(AiRemoteDataSource.invalidMessageText), retry: false));
    testWidgets('daily limit with ad option -> disabled "watch an ad" button, no retry', (t) async {
      await _pumpAfter(t, const AiLimitReached(AiRemoteDataSource.dailyLimitMessage,
          limit: 'daily', canWatchAd: true, adsRemainingToday: 5));
      expect(find.text(AiRemoteDataSource.dailyLimitMessage), findsOneWidget);
      final ad = find.widgetWithText(TextButton, 'شاهد إعلاناً واحصل على 3 أسئلة (قريباً)');
      expect(ad, findsOneWidget);
      expect(t.widget<TextButton>(ad).onPressed, isNull);         // until the client's AdMob ids arrive
      expect(find.text('إعادة المحاولة'), findsNothing);
    });

    testWidgets('monthly limit without ad option -> message only', (t) async {
      await _pumpAfter(t, const AiLimitReached(AiRemoteDataSource.monthlyLimitMessage, limit: 'monthly'));
      expect(find.text(AiRemoteDataSource.monthlyLimitMessage), findsOneWidget);
      expect(find.textContaining('شاهد إعلاناً'), findsNothing);
    });

    testWidgets('too fast -> message, no retry', (t) =>
        expectError(t, const ValidationFailure(AiRemoteDataSource.tooFastMessage), retry: false));

    testWidgets('input shows a 300-character counter and is disabled while sending', (t) async {
      await _pumpAfter(t, AiReply.fromJson(contractReply()));
      expect(find.text('0/300'), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).maxLength, 300);
    });

    testWidgets('429 -> message only, no retry, no upgrade button', (t) async {
      await expectError(t, const ValidationFailure(AiRemoteDataSource.tooManyMessage), retry: false);
      expect(find.textContaining('ترقية'), findsNothing);
    });
  });
}
