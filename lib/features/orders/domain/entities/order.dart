import '../../../../shared/models/json_utils.dart';
import '../../../../shared/models/user_brief.dart';
import '../../../products/domain/entities/product.dart';

/// سطر داخل الطلب — من `order.items[]`:
/// ```json
/// { "id": 1, "quantity": 4, "unit_price": "1200.00",
///   "subtotal": "4800.00", "product": { ... } }
/// ```
/// خلافاً لعنصر السلة، هنا الخادم يعيد [unitPrice] و[subtotal] جاهزين
/// (نصّين) — وهما سعر لحظة الشراء، فلا نحسبهما من سعر المنتج الحالي.
class OrderItem {
  final int id;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final Product product;

  const OrderItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: asInt(json['id']),
        quantity: asInt(json['quantity']),
        unitPrice: asDouble(json['unit_price']),
        subtotal: asDouble(json['subtotal']),
        product: json['product'] is Map
            ? Product.fromJson(Map<String, dynamic>.from(json['product'] as Map))
            : const Product(
                id: 0,
                title: 'منتج محذوف',
                description: '',
                price: 0,
                stock: 0,
              ),
      );
}

/// طلب شراء — الحقول مطابقة لاستجابات POST /checkout و GET /orders
/// و GET /merchant/orders و PATCH /merchant/orders/{id}/status:
/// ```json
/// { "id": 1, "order_number": "ORD-R6IUNIVWSN", "total_amount": "4800.00",
///   "status": "pending", "status_label": "قيد الانتظار",
///   "shipping_address": "home - israamunawwar, دبي, AL Malleha (0501234567)",
///   "notes": "...", "merchant": { ... } | "buyer": { ... },
///   "items": [ ... ], "created_at": "..." }
/// ```
///
/// ملاحظات على الشكل الفعلي:
///  • [shippingAddress] يعود **نصاً جاهزاً للعرض** لا كائن عنوان.
///  • الطرف الآخر يختلف حسب المسار: في طلبات العميل يعود `merchant`،
///    وفي طلبات التاجر يعود `buyer`. نقرأ كليهما في [counterparty]
///    ونحتفظ بكلٍّ منهما منفصلاً حتى تعرف كل شاشة من تخاطب.
///  • [totalAmount] نص ("4800.00") لا رقم.
class Order {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String? status;
  final String? statusLabel;
  final String? shippingAddress;
  final String? notes;

  /// التاجر البائع — يعود في مسارات العميل (/checkout و /orders).
  final UserBrief? merchant;

  /// المشتري — يعود في مسارات التاجر (/merchant/orders).
  final UserBrief? buyer;

  final List<OrderItem> items;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    this.status,
    this.statusLabel,
    this.shippingAddress,
    this.notes,
    this.merchant,
    this.buyer,
    this.items = const [],
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: asInt(json['id']),
        orderNumber: asString(json['order_number']),
        totalAmount: asDouble(json['total_amount']),
        status: asStringOrNull(json['status']),
        statusLabel: asStringOrNull(json['status_label']),
        shippingAddress: asStringOrNull(json['shipping_address']),
        notes: asStringOrNull(json['notes']),
        merchant: UserBrief.fromNullable(json['merchant']),
        buyer: UserBrief.fromNullable(json['buyer']),
        items: (json['items'] is List)
            ? (json['items'] as List)
                .whereType<Map>()
                .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        createdAt: asDateOrNull(json['created_at']),
      );

  /// الطرف الآخر في الطلب أياً كان المسار — للعرض في رأس البطاقة.
  UserBrief? get counterparty => merchant ?? buyer;

  /// عدد القطع الفعلي (مجموع الكميات) لا عدد الأسطر.
  int get totalQuantity =>
      items.fold<int>(0, (acc, item) => acc + item.quantity);

  /// التسمية العربية مصدرها الخادم (`status_label`)، ولا نترجم محلياً
  /// إلا عند غيابها تماماً.
  String get displayStatus => statusLabel ?? status ?? '—';
}

/// حالات الطلب — مطابقة حرفياً لـ `App\Enums\OrderStatus` في الـ Backend.
///
/// ⚠️ انتبه للإملاء: الخادم يستخدم `canceled` **بلام واحدة** لا
/// `cancelled`. أي قيمة خارج هذه الستة يرفضها `Rule::enum` بـ 422.
///
/// التسميات هنا مطابقة لدالة `label()` في الـ enum، لكنها احتياط فقط:
/// الشاشات تعرض `status_label` القادم من الخادم متى توفّر.
enum OrderStatus {
  pending('pending', 'قيد الانتظار'),
  processing('processing', 'قيد التجهيز'),
  shipped('shipped', 'تم الشحن'),
  delivered('delivered', 'تم التوصيل'),
  completed('completed', 'مكتمل'),
  canceled('canceled', 'ملغي');

  final String value;
  final String label;
  const OrderStatus(this.value, this.label);

  static OrderStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final status in OrderStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}
