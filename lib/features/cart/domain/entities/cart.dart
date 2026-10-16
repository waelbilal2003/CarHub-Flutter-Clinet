import '../../../../shared/models/json_utils.dart';
import '../../../products/domain/entities/product.dart';

/// عنصر داخل السلة — الحقول مطابقة لاستجابة POST /cart/items
/// ولعناصر `cart.items[]` في GET /cart:
/// ```json
/// { "id": 1, "quantity": 4, "product": { "id": 1, "title": "...",
///   "price": "1200.00", "stock": 50, "status": "active", ... } }
/// ```
///
/// ⚠️ ملاحظة مسجّلة كفجوة: كائن [product] هنا **لا يحوي merchant**،
/// بينما تصميم 10_cart.html يجمّع عناصر السلة حسب المتجر مع مجموع
/// فرعي لكل متجر. لذلك لا يمكن تنفيذ التجميع حتى تضيف إسراء التاجر
/// داخل عنصر السلة.
class CartItem {
  final int id;
  final int quantity;
  final Product product;

  const CartItem({
    required this.id,
    required this.quantity,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: asInt(json['id']),
        quantity: asInt(json['quantity']),
        product: json['product'] is Map
            ? Product.fromJson(Map<String, dynamic>.from(json['product'] as Map))
            : const Product(
                id: 0,
                title: 'منتج غير متاح',
                description: '',
                price: 0,
                stock: 0,
              ),
      );

  /// المجموع الفرعي للسطر. يُحسب محلياً لأن الـ API لا يعيده لعناصر
  /// السلة (يعيده لعناصر الطلب فقط عبر `subtotal`).
  double get subtotal => product.price * quantity;
}

/// سلة المستخدم الحالي — GET /cart:
/// ```json
/// { "id": 2, "user_id": 2, "items": [], "total_amount": 0,
///   "created_at": "2026-09-12T14:27:27.000000Z" }
/// ```
/// [totalAmount] يعود رقماً (0) عند الفراغ ونصاً ("4800.00") عند الامتلاء،
/// لذلك نقرأه بـ asDouble المتسامح مع النوعين.
class Cart {
  final int id;
  final int? userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime? createdAt;

  const Cart({
    required this.id,
    this.userId,
    this.items = const [],
    this.totalAmount = 0,
    this.createdAt,
  });

  /// سلة فارغة تُعرض قبل وصول أول استجابة أو بعد إتمام الشراء.
  static const Cart empty = Cart(id: 0);

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        id: asInt(json['id']),
        userId: asIntOrNull(json['user_id']),
        items: (json['items'] is List)
            ? (json['items'] as List)
                .whereType<Map>()
                .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        totalAmount: asDouble(json['total_amount']),
        createdAt: asDateOrNull(json['created_at']),
      );

  bool get isEmpty => items.isEmpty;

  /// مجموع القطع لا مجموع الأسطر — «3 قطع» لا «سطران».
  int get totalQuantity =>
      items.fold<int>(0, (acc, item) => acc + item.quantity);

  /// الإجمالي المعروض. نفضّل قيمة الخادم، ونسقط إلى الحساب المحلي
  /// إن عادت صفراً والسلة غير فارغة (يحدث إن تغيّر شكل الحقل لاحقاً).
  double get displayTotal {
    if (totalAmount > 0 || items.isEmpty) return totalAmount;
    return items.fold<double>(0, (acc, item) => acc + item.subtotal);
  }
}
