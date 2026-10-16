import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../products/domain/entities/product.dart';
import '../../data/datasources/merchant_remote_datasource.dart';
import '../../data/repositories/api_merchant_repository.dart';
import '../../domain/repositories/merchant_repository.dart';

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiMerchantRepository(MerchantRemoteDataSource(dioClient));
});

// ─────────────────── المخزون ───────────────────

/// منتجات التاجر — GET /merchant/products (مصفّحة).
///
/// تعرض منتجاته بكل الحالات، بخلاف GET /products الذي يقتصر على
/// `status = active` — لذلك هذه هي المصدر الصحيح لشاشة المخزون.
final merchantProductsProvider =
    AsyncNotifierProvider<MerchantProductsNotifier, List<Product>>(
  MerchantProductsNotifier.new,
);

class MerchantProductsNotifier extends AsyncNotifier<List<Product>> {
  MerchantRepository get _repo => ref.read(merchantRepositoryProvider);

  int _page = 1;
  bool _hasMore = false;
  bool get hasMore => _hasMore;

  @override
  Future<List<Product>> build() async {
    _page = 1;
    final result = await _repo.products(page: _page);
    _hasMore = result.hasMore;
    return result.items;
  }

  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      final result = await _repo.products(page: _page);
      _hasMore = result.hasMore;
      return result.items;
    });
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? const <Product>[];
    try {
      final result = await _repo.products(page: _page + 1);
      _page += 1;
      _hasMore = result.hasMore;
      state = AsyncValue.data([...current, ...result.items]);
    } catch (_) {
      // نُبقي القائمة الحالية عند فشل صفحة إضافية.
    }
  }

  /// يحذف منتجاً ويزيله من القائمة فوراً بلا إعادة تحميل الصفحة كلها.
  /// يعيد رسالة الخطأ عند الفشل و null عند النجاح.
  Future<String?> remove(int id) async {
    try {
      await _repo.deleteProduct(id);
      final current = state.valueOrNull ?? const <Product>[];
      state = AsyncValue.data(current.where((p) => p.id != id).toList());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// يستبدل المنتج المعدَّل في مكانه (يحافظ على موضع التمرير).
  void replace(Product updated) {
    final current = state.valueOrNull ?? const <Product>[];
    state = AsyncValue.data([
      for (final p in current)
        if (p.id == updated.id) updated else p,
    ]);
  }
}

// ─────────────────── الطلبات ───────────────────

/// الطلبات الواردة للتاجر — GET /merchant/orders (مصفّحة).
final merchantOrdersProvider =
    AsyncNotifierProvider<MerchantOrdersNotifier, List<Order>>(
  MerchantOrdersNotifier.new,
);

class MerchantOrdersNotifier extends AsyncNotifier<List<Order>> {
  MerchantRepository get _repo => ref.read(merchantRepositoryProvider);

  int _page = 1;
  bool _hasMore = false;
  bool get hasMore => _hasMore;

  @override
  Future<List<Order>> build() async {
    _page = 1;
    final result = await _repo.orders(page: _page);
    _hasMore = result.hasMore;
    return result.items;
  }

  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      final result = await _repo.orders(page: _page);
      _hasMore = result.hasMore;
      return result.items;
    });
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? const <Order>[];
    try {
      final result = await _repo.orders(page: _page + 1);
      _page += 1;
      _hasMore = result.hasMore;
      state = AsyncValue.data([...current, ...result.items]);
    } catch (_) {
      // نُبقي القائمة الحالية عند فشل صفحة إضافية.
    }
  }

  /// تحديث حالة طلب — PATCH /merchant/orders/{id}/status.
  ///
  /// الخادم يعيد الطلب المحدَّث كاملاً، فنستبدل العنصر في مكانه بدل
  /// إعادة تحميل الصفحة كلها (يحافظ على موضع التمرير والصفحات المحمّلة).
  /// يعيد رسالة الخطأ عند الفشل و null عند النجاح.
  Future<String?> updateStatus(int orderId, OrderStatus status) async {
    try {
      final updated =
          await _repo.updateOrderStatus(orderId: orderId, status: status.value);
      final current = state.valueOrNull ?? const <Order>[];
      state = AsyncValue.data([
        for (final order in current)
          if (order.id == updated.id) updated else order,
      ]);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

/// التبويب المختار في شاشة طلبات التاجر (null = الكل).
/// تصفية محلية — لا معامل `?status=` في `Merchant\OrderController::index`.
final merchantOrdersFilterProvider = StateProvider<OrderStatus?>((ref) => null);

// ─────────────────── إضافة منتج ───────────────────

class AddProductState {
  final bool isLoading;
  final String? error;
  const AddProductState({this.isLoading = false, this.error});
}

final addProductProvider =
    StateNotifierProvider<AddProductController, AddProductState>((ref) {
  return AddProductController(ref);
});

class AddProductController extends StateNotifier<AddProductState> {
  final Ref _ref;
  AddProductController(this._ref) : super(const AddProductState());

  /// [imagePaths] لا يجوز أن تكون فارغة — الخادم يشترط صورة واحدة على
  /// الأقل ويردّ 422 بدونها. الشاشة تمنع الإرسال قبل اختيار صورة.
  Future<bool> submit({
    required String title,
    required String description,
    required double price,
    required int stock,
    required List<String> imagePaths,
  }) async {
    state = const AddProductState(isLoading: true);
    try {
      await _ref.read(merchantRepositoryProvider).addProduct(
            title: title,
            description: description,
            price: price,
            stock: stock,
            imagePaths: imagePaths,
          );
      state = const AddProductState(isLoading: false);
      return true;
    } catch (e) {
      state = AddProductState(isLoading: false, error: e.toString());
      return false;
    }
  }
}
