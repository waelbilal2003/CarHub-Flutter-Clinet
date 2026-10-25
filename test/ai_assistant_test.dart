import 'package:carhub/core/errors/failures.dart';
import 'package:carhub/core/network/dio_client.dart';
import 'package:carhub/core/router/app_routes.dart';
import 'package:carhub/core/storage/token_storage.dart';
import 'package:carhub/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:carhub/features/ai_assistant/domain/entities/ai_reply.dart';
import 'package:carhub/features/ai_assistant/presentation/providers/ai_chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// مثال الرد من CONTRACTS.md §1 (data) مع بطاقات §2.
Map<String, dynamic> contractReply({String conversationId = 'c_8f2a91'}) => {
      'conversation_id': conversationId,
      'answer': 'أكيد! شو سنة صنع سيارتك؟',
      'followup': {
        'question': 'شو سنة صنع السيارة؟',
        'suggestions': ['2016', '2017', '2018'],
      },
      'products': [
        {
          'id': 152,
          'title': 'مصباح أمامي',
          'price': '350.00',
          'currency': 'SAR',
          'image_url': null,
          'merchant_name': 'متجر الأمان',
          'city': 'الرياض',
          'compatibility': 'exact',
        }
      ],
      'cards': [
        {'type': 'open_product', 'label': 'عرض المصابيح المتوافقة', 'payload': {'product_ids': [152, 160]}},
        {
          'type': 'open_marketplace_search',
          'label': 'ابحث',
          'payload': {'query': 'فحمات فرامل', 'filters': {'car_make': 'Kia', 'car_model': 'Sportage', 'year': 2018}},
        },
        {
          'type': 'create_tender',
          'label': 'اطلب',
          'payload': {'category': 'paint_body', 'title': 'رش مصد أمامي', 'city': 'الرياض'},
        },
        {'type': 'open_policy', 'label': 'سياسة', 'payload': {}},
      ],
      'usage': {'used_today': 3, 'daily_limit': null},
    };

class FakeAiRemote extends AiRemoteDataSource {
  final List<Object> results; // AiReply أو Failure، بالترتيب
  final calls = <(String, String?)>[];

  FakeAiRemote(this.results) : super(DioClient(TokenStorage()));

  @override
  Future<AiReply> ask({required String message, String? conversationId, String? city}) async {
    calls.add((message, conversationId));
    final r = results.removeAt(0);
    if (r is Failure) throw r;
    return r as AiReply;
  }
}

void main() {
  group('AiReply.fromJson (CONTRACTS.md §1/§2)', () {
    test('parses products, followup, usage and all card types', () {
      final r = AiReply.fromJson(contractReply());

      expect(r.conversationId, 'c_8f2a91');
      expect(r.followup!.suggestions, ['2016', '2017', '2018']);
      expect(r.products.single.price, '350.00');
      expect(r.products.single.compatibility, AiCompatibility.exact);
      expect(r.usage.dailyLimit, isNull);

      // open_policy مؤجّلة: تُتجاهل بأمان.
      expect(r.cards, hasLength(3));
      final open = r.cards[0] as OpenProductCard;
      expect(open.productIds, [152, 160]);
      final search = r.cards[1] as OpenMarketplaceSearchCard;
      expect((search.query, search.carMake, search.carModel, search.year),
          ('فحمات فرامل', 'Kia', 'Sportage', 2018));
      final tender = r.cards[2] as CreateTenderCard;
      expect((tender.category, tender.title, tender.city),
          ('paint_body', 'رش مصد أمامي', 'الرياض'));
    });

    test('partial is the default compatibility and missing parts are tolerated', () {
      final r = AiReply.fromJson({
        'conversation_id': 'c_1',
        'answer': 'x',
        'followup': null,
        'products': [{'id': '7', 'title': 't', 'price': '1.00', 'currency': 'SAR'}],
      });
      expect(r.products.single.id, 7);
      expect(r.products.single.compatibility, AiCompatibility.partial);
      expect(r.cards, isEmpty);
      expect(r.usage.usedToday, 0);
    });
  });

  group('routes built from cards', () {
    test('marketplace search uses the marketplace API parameter names', () {
      expect(
        AppRoutes.marketplaceSearch(search: 'فحمات فرامل', carMake: 'Kia', carModel: 'Sportage', year: 2018),
        Uri(path: '/market', queryParameters: {
          'search': 'فحمات فرامل', 'car_make': 'Kia', 'car_model': 'Sportage', 'year': '2018',
        }).toString(),
      );
    });

    test('tender form prefill', () {
      final uri = Uri.parse(AppRoutes.createTenderPrefilled(category: 'paint_body', title: 'رش مصد', city: null));
      expect(uri.path, '/tenders/create');
      expect(uri.queryParameters, {'category': 'paint_body', 'title': 'رش مصد'});
    });
  });

  group('AiChatController', () {
    test('keeps conversation_id across messages', () async {
      final remote = FakeAiRemote([
        AiReply.fromJson(contractReply()),
        AiReply.fromJson(contractReply()),
      ]);
      final c = AiChatController(remote);

      await c.send('بدي ضو لكيا سبورتاج');
      await c.send('2018');

      expect(remote.calls, [('بدي ضو لكيا سبورتاج', null), ('2018', 'c_8f2a91')]);
      expect(c.state.conversationId, 'c_8f2a91');
      expect(c.state.isSending, isFalse);
      // ترحيب + (مستخدم + مساعد) × 2
      expect(c.state.entries, hasLength(5));
    });

    test('503 shows a retryable error; retry resends without a duplicate bubble', () async {
      final remote = FakeAiRemote([
        const ServerFailure(AiRemoteDataSource.unavailableMessage),
        AiReply.fromJson(contractReply()),
      ]);
      final c = AiChatController(remote);

      await c.send('مرحبا');
      final err = c.state.entries.last as ErrorEntry;
      expect(err.message, AiRemoteDataSource.unavailableMessage);
      expect(err.retryable, isTrue);

      await c.retry();
      expect(remote.calls.map((e) => e.$1), ['مرحبا', 'مرحبا']);
      expect(c.state.entries.whereType<UserEntry>(), hasLength(1));
      expect(c.state.entries.whereType<ErrorEntry>(), isEmpty);
      expect(c.state.entries.last, isA<AssistantEntry>());
    });

    test('422 is not retryable; empty and too-long messages are not sent', () async {
      final remote = FakeAiRemote([const ValidationFailure('الرسالة غير صالحة')]);
      final c = AiChatController(remote);

      await c.send('   ');
      await c.send('ا' * (aiMaxMessageLength + 1));
      expect(remote.calls, isEmpty);

      await c.send('x');
      expect((c.state.entries.last as ErrorEntry).retryable, isFalse);
    });

    test('new conversation clears messages and conversation_id', () async {
      final c = AiChatController(FakeAiRemote([AiReply.fromJson(contractReply())]));
      await c.send('مرحبا');
      c.newConversation();

      expect(c.state.conversationId, isNull);
      expect(c.state.entries, hasLength(1));
      expect((c.state.entries.single as AssistantEntry).text, aiWelcomeMessage);
    });
  });
}
