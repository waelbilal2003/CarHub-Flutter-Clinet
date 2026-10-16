import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/api_order_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiOrderRepository(OrderRemoteDataSource(dioClient));
});

/// طلباتي — GET /orders (مصفّحة، مع تحميل المزيد).
final myOrdersProvider = AsyncNotifierProvider<MyOrdersNotifier, List<Order>>(
  MyOrdersNotifier.new,
);

class MyOrdersNotifier extends AsyncNotifier<List<Order>> {
  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  int _page = 1;
  bool _hasMore = false;
  bool get hasMore => _hasMore;

  @override
  Future<List<Order>> build() async {
    _page = 1;
    final result = await _repo.myOrders(page: _page);
    _hasMore = result.hasMore;
    return result.items;
  }

  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      final result = await _repo.myOrders(page: _page);
      _hasMore = result.hasMore;
      return result.items;
    });
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? const <Order>[];
    try {
      final result = await _repo.myOrders(page: _page + 1);
      _page += 1;
      _hasMore = result.hasMore;
      state = AsyncValue.data([...current, ...result.items]);
    } catch (_) {
      // نُبقي القائمة الحالية عند فشل صفحة إضافية.
    }
  }
}

/// التبويب المختار في شاشة «طلباتي» (null = الكل).
///
/// ⚠️ التصفية تتم **محلياً** على الصفحات المحمّلة: لا يوثّق ملف Postman
/// معامل `?status=` في GET /orders. يعني التبويب قد يبدو فارغاً بينما
/// توجد طلبات مطابقة في صفحات لم تُحمَّل بعد.
final myOrdersFilterProvider = StateProvider<OrderStatus?>((ref) => null);

/// حالة إتمام الشراء.
class CheckoutState {
  final bool isLoading;
  final String? error;
  const CheckoutState({this.isLoading = false, this.error});
}

final checkoutProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  return CheckoutController(ref);
});

class CheckoutController extends StateNotifier<CheckoutState> {
  final Ref _ref;
  CheckoutController(this._ref) : super(const CheckoutState());

  /// ينفّذ POST /checkout ويعيد **قائمة** الطلبات الناتجة.
  ///
  /// الخادم يقسّم السلة إلى طلب لكل تاجر، لذلك شاشة النجاح تتلقّى
  /// قائمة وتعرض أرقام كل الطلبات لا رقماً واحداً.
  Future<List<Order>?> submit({
    required int addressId,
    String? notes,
  }) async {
    state = const CheckoutState(isLoading: true);
    try {
      final orders = await _ref.read(orderRepositoryProvider).checkout(
            addressId: addressId,
            notes: notes,
          );
      state = const CheckoutState(isLoading: false);

      // السلة أصبحت فارغة على الخادم، والطلبات الجديدة يجب أن تظهر.
      await _ref.read(cartProvider.notifier).reloadAfterCheckout();
      _ref.invalidate(myOrdersProvider);

      return orders;
    } catch (e) {
      state = CheckoutState(isLoading: false, error: e.toString());
      return null;
    }
  }
}

/// نتيجة آخر عملية شراء — تقرأها شاشة النجاح.
///
/// نمرّرها عبر مزوّد لا عبر معاملات المسار لأن الطلبات الناتجة قد تكون
/// عدة، ولأن `go_router` لا يحمل كائنات في المسار النصي.
final lastCheckoutOrdersProvider = StateProvider<List<Order>>((ref) => const []);
