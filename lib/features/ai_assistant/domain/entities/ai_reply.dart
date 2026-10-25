/// نماذج ردّ المساعد الذكي — مطابقة لـ CONTRACTS.md §1 و§2.
///
/// `POST /ai/ask` → data:
/// ```json
/// { "conversation_id": "c_8f2a91", "answer": "...",
///   "followup": {"question": "...", "suggestions": ["2018"]} | null,
///   "products": [{ "id", "title", "price": "350.00", "currency", "image_url",
///                  "merchant_name", "city", "compatibility": "exact|partial" }],
///   "cards": [{ "type", "label", "payload": {...} }],
///   "usage": { "used_today": 3, "daily_limit": 10 | null } }
/// ```
/// الأسعار والصور والمتجر تأتي من قاعدة البيانات عبر Laravel، لا من النموذج.
class AiReply {
  final String conversationId;
  final String answer;
  final AiFollowup? followup;
  final List<AiProduct> products;
  final List<AiCard> cards;
  final AiUsage usage;

  const AiReply({
    required this.conversationId,
    required this.answer,
    required this.followup,
    required this.products,
    required this.cards,
    required this.usage,
  });

  factory AiReply.fromJson(Map<String, dynamic> json) => AiReply(
        conversationId: json['conversation_id']?.toString() ?? '',
        answer: json['answer']?.toString() ?? '',
        followup: json['followup'] is Map
            ? AiFollowup.fromJson(Map<String, dynamic>.from(json['followup'] as Map))
            : null,
        products: _list(json['products'], AiProduct.fromJson),
        // البطاقات غير المعروفة (مثل open_policy المؤجّلة) تُتجاهل بأمان.
        cards: _list(json['cards'], AiCard.tryParse).whereType<AiCard>().toList(),
        usage: json['usage'] is Map
            ? AiUsage.fromJson(Map<String, dynamic>.from(json['usage'] as Map))
            : const AiUsage(usedToday: 0, dailyLimit: null),
      );
}

class AiFollowup {
  final String question;
  final List<String> suggestions;

  const AiFollowup({required this.question, required this.suggestions});

  factory AiFollowup.fromJson(Map<String, dynamic> json) => AiFollowup(
        question: json['question']?.toString() ?? '',
        suggestions: (json['suggestions'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

enum AiCompatibility { exact, partial }

class AiProduct {
  final int id;
  final String title;

  /// نص بخانتين عشريتين كما يرسله الخادم ("350.00") — لا نحسب عليه.
  final String price;
  final String currency;
  final String? imageUrl;
  final String? merchantName;
  final String? city;
  final AiCompatibility compatibility;

  const AiProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.merchantName,
    required this.city,
    required this.compatibility,
  });

  factory AiProduct.fromJson(Map<String, dynamic> json) => AiProduct(
        id: _toInt(json['id']) ?? 0,
        title: json['title']?.toString() ?? '',
        price: json['price']?.toString() ?? '',
        currency: json['currency']?.toString() ?? '',
        imageUrl: json['image_url'] as String?,
        merchantName: json['merchant_name'] as String?,
        city: json['city'] as String?,
        compatibility: json['compatibility'] == 'exact'
            ? AiCompatibility.exact
            : AiCompatibility.partial,
      );
}

/// بطاقات الإجراء (CONTRACTS.md §2). كل نوع صنف مستقل بحقوله.
sealed class AiCard {
  final String label;
  const AiCard(this.label);

  /// يعيد null للأنواع غير المدعومة (open_policy مؤجّلة في v0).
  static AiCard? tryParse(Map<String, dynamic> json) {
    final label = json['label']?.toString() ?? '';
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : const <String, dynamic>{};

    switch (json['type']) {
      case 'open_product':
        final ids = (payload['product_ids'] as List? ?? const [])
            .map(_toInt)
            .whereType<int>()
            .toList();
        return ids.isEmpty ? null : OpenProductCard(label, productIds: ids);
      case 'open_marketplace_search':
        final filters = payload['filters'] is Map
            ? Map<String, dynamic>.from(payload['filters'] as Map)
            : const <String, dynamic>{};
        return OpenMarketplaceSearchCard(
          label,
          query: payload['query']?.toString() ?? '',
          carMake: filters['car_make']?.toString(),
          carModel: filters['car_model']?.toString(),
          year: _toInt(filters['year']),
        );
      case 'create_tender':
        final category = payload['category']?.toString();
        if (category == null || category.isEmpty) return null;
        return CreateTenderCard(
          label,
          category: category,
          title: payload['title']?.toString() ?? '',
          city: payload['city']?.toString(),
        );
      default:
        return null;
    }
  }
}

class OpenProductCard extends AiCard {
  final List<int> productIds;
  const OpenProductCard(super.label, {required this.productIds});
}

class OpenMarketplaceSearchCard extends AiCard {
  final String query;

  /// أسماء معاملات API السوق نفسها (car_make / car_model / year).
  final String? carMake;
  final String? carModel;
  final int? year;

  const OpenMarketplaceSearchCard(
    super.label, {
    required this.query,
    this.carMake,
    this.carModel,
    this.year,
  });
}

class CreateTenderCard extends AiCard {
  /// مفتاح TenderCategory في الـ Backend: mechanic | electric | paint_body.
  final String category;
  final String title;
  final String? city;

  const CreateTenderCard(
    super.label, {
    required this.category,
    required this.title,
    this.city,
  });
}

class AiUsage {
  final int usedToday;

  /// null = غير محدود (أو غير محدد). لا يُفرض الحد في v0.
  final int? dailyLimit;

  const AiUsage({required this.usedToday, required this.dailyLimit});

  factory AiUsage.fromJson(Map<String, dynamic> json) => AiUsage(
        usedToday: _toInt(json['used_today']) ?? 0,
        dailyLimit: _toInt(json['daily_limit']),
      );
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) =>
    (raw as List? ?? const [])
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();

int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
