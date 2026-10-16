import '../entities/cart.dart';

abstract class CartRepository {
  Future<Cart> fetch();

  /// يعيد عنصر السلة المضاف/المحدَّث كما يرجعه الخادم.
  /// ⚠️ الخادم يجمع الكمية على الموجود ولا يستبدلها.
  Future<CartItem> addItem({required int productId, required int quantity});

  /// يضبط الكمية بالضبط، ويعيد السلة كاملة.
  Future<Cart> updateItem({required int itemId, required int quantity});

  /// يحذف سطراً، ويعيد السلة كاملة.
  Future<Cart> removeItem(int itemId);

  /// يفرّغ السلة، ويعيد السلة (الفارغة) بعد التفريغ.
  Future<Cart> clear();
}
