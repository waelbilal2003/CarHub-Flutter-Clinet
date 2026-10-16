import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/cart_remote_datasource.dart';
import '../../data/repositories/api_cart_repository.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiCartRepository(CartRemoteDataSource(dioClient));
});

/// سلة المستخدم الحالي — GET /cart.
///
/// تُقرأ في شاشة السلة وفي شارة العدّاد أعلى شاشة السوق، لذلك هي
/// [AsyncNotifierProvider] واحد مشترك لا نداء مستقل لكل شاشة.
final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(
  CartNotifier.new,
);

class CartNotifier extends AsyncNotifier<Cart> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() => _repo.fetch();

  Future<void> refreshCart() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.fetch);
  }

  /// يضيف منتجاً للسلة ثم يعيد جلبها لتحديث الإجمالي.
  ///
  /// سبب إعادة الجلب: POST /cart/items يعيد **عنصر السلة** فقط لا السلة،
  /// فلا يصلنا `total_amount` المحدَّث منه.
  ///
  /// يعيد رسالة الخطأ عند الفشل، و null عند النجاح — حتى تعرض الشاشة
  /// سبب الرفض الحقيقي من الخادم (نفاد المخزون مثلاً) لا رسالة عامة.
  Future<String?> addItem({
    required int productId,
    required int quantity,
  }) async {
    try {
      await _repo.addItem(productId: productId, quantity: quantity);
      state = await AsyncValue.guard(_repo.fetch);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// يضبط كمية سطر بالضبط. الخادم يعيد السلة كاملة فنكتفي بنداء واحد.
  /// يعيد رسالة الخطأ عند الفشل و null عند النجاح.
  Future<String?> setQuantity({
    required int itemId,
    required int quantity,
  }) async {
    // كمية صفر تعني الحذف — الخادم يشترط min:1 في UpdateCartItemRequest.
    if (quantity < 1) return removeItem(itemId);
    try {
      state = AsyncValue.data(
        await _repo.updateItem(itemId: itemId, quantity: quantity),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeItem(int itemId) async {
    try {
      state = AsyncValue.data(await _repo.removeItem(itemId));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> clear() async {
    try {
      state = AsyncValue.data(await _repo.clear());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// تُستدعى بعد إتمام الشراء: الخادم يفرّغ السلة بتحويلها إلى طلبات،
  /// فنعيد الجلب ليعكس التطبيق الحالة الجديدة بدل إبقاء سلة قديمة.
  Future<void> reloadAfterCheckout() async {
    state = await AsyncValue.guard(_repo.fetch);
  }
}

/// عدد القطع في السلة — لشارة العدّاد في شريط السوق.
/// يعود 0 أثناء التحميل أو عند الخطأ فلا تُظهر الشارة رقماً مضللاً.
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).valueOrNull?.totalQuantity ?? 0;
});
