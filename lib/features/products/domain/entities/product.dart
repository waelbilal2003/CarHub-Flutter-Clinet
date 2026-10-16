import '../../../../shared/models/json_utils.dart';
import '../../../../shared/models/user_brief.dart';
import 'review.dart';

/// صورة منتج كما تعود داخل `product.images[]`:
/// ```json
/// { "id": 1, "image_url": "http://.../storage/products/xxx.png",
///   "is_primary": true, "sort_order": 0 }
/// ```
/// لا تظهر أبداً وحدها في الـ API، لذلك تعيش مع [Product] في نفس الملف.
class ProductImage {
  final int id;
  final String imageUrl;
  final bool isPrimary;
  final int sortOrder;

  const ProductImage({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        id: asInt(json['id']),
        imageUrl: asString(json['image_url']),
        isPrimary: asBool(json['is_primary']),
        sortOrder: asInt(json['sort_order']),
      );
}

/// منتج في السوق — الحقول مطابقة لاستجابة GET /products و GET /products/{id}:
/// ```json
/// { "id": 1, "title": "إطارات ميشلان", "description": "...",
///   "price": "1200.00", "stock": 50, "status": "active",
///   "status_label": "نشط", "merchant": { ... }, "category": null,
///   "brand": null, "images": [ ... ], "reviews": [ ... ],
///   "created_at": "2026-09-12T13:02:20.000000Z" }
/// ```
///
/// ملاحظات مهمة على الشكل الفعلي:
///  • [price] يعود **نصاً** ("1200.00") لا رقماً — نحوّله بـ asDouble.
///  • [merchant] غائب في نسختين من نفس الكائن: داخل `cart.items[].product`
///    وداخل `order.items[].product` وفي ردّ POST /merchant/products —
///    لذلك هو nullable هنا ولا تعتمد عليه أي شاشة إلا بعد فحصه.
///  • [reviews] تعود فقط في GET /products/{id}، وتكون فارغة في القائمة.
///  • [category] و[brand] يعودان null في كل أمثلة إسراء، فلم نبنِ عليهما
///    فلترة ولا تصنيفات (فجوة مسجّلة).
class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final int stock;
  final String? status;
  final String? statusLabel;
  final UserBrief? merchant;
  final String? category;
  final String? brand;
  final List<ProductImage> images;
  final List<Review> reviews;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.stock,
    this.status,
    this.statusLabel,
    this.merchant,
    this.category,
    this.brand,
    this.images = const [],
    this.reviews = const [],
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: asInt(json['id']),
        title: asString(json['title']),
        description: asString(json['description']),
        price: asDouble(json['price']),
        stock: asInt(json['stock']),
        status: asStringOrNull(json['status']),
        statusLabel: asStringOrNull(json['status_label']),
        merchant: UserBrief.fromNullable(json['merchant']),
        category: asStringOrNull(json['category']),
        brand: asStringOrNull(json['brand']),
        images: (json['images'] is List)
            ? (json['images'] as List)
                .whereType<Map>()
                .map((e) => ProductImage.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        reviews: (json['reviews'] is List)
            ? (json['reviews'] as List)
                .whereType<Map>()
                .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        createdAt: asDateOrNull(json['created_at']),
      );

  /// الصورة المعروضة في البطاقة: الأساسية إن وُجدت، وإلا أول صورة،
  /// وإلا null فتعرض الشاشة العنصر النائب.
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary);
    return (primary.isNotEmpty ? primary.first : images.first).imageUrl;
  }

  bool get isOutOfStock => stock <= 0;

  /// مخزون منخفض — العتبة من تصميم لوحة التاجر (تنبيه عند 5 أو أقل).
  /// ⚠️ ليست قاعدة من الـ Backend؛ لا يوجد حقل عتبة في الـ API.
  bool get isLowStock => stock > 0 && stock <= 5;

  /// متوسط التقييمات المحمّلة (شاشة التفاصيل فقط).
  /// يعود null عندما لا توجد تقييمات فلا نعرض «0 من 5» زوراً.
  double? get averageRating {
    if (reviews.isEmpty) return null;
    final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / reviews.length;
  }

  /// نستخدم [statusLabel] العربي القادم من الخادم مباشرة عند توفّره،
  /// ولا نترجم نحن — حتى تبقى التسميات مصدرها الـ Backend وحده.
  String get displayStatus => statusLabel ?? (isOutOfStock ? 'غير متوفّر' : '');
}
