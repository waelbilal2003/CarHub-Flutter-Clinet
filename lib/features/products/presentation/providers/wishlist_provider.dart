import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/wishlist_remote_datasource.dart';
import '../../domain/entities/product.dart';

final wishlistDataSourceProvider = Provider<WishlistRemoteDataSource>((ref) {
  return WishlistRemoteDataSource(ref.watch(dioClientProvider));
});

/// حالة المفضّلة.
///
/// [isAvailable] موجود لأن مسار `/wishlists` معطّل حالياً في الـ Backend
/// (يردّ 500 من `WishlistResource`). عندما يفشل التحميل لهذا السبب
/// نُسقِط الميزة بهدوء: نُخفي زرّ القلب بدل عرض زرٍّ يبدو معطوباً كلما
/// ضُغط. يعود الزرّ وحده فور إصلاح المسار — بلا أي تغيير في الكود.
class WishlistState {
  final List<Product> products;
  final bool isAvailable;

  const WishlistState({this.products = const [], this.isAvailable = true});

  bool contains(int productId) => products.any((p) => p.id == productId);
}

final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, WishlistState>(
  WishlistNotifier.new,
);

class WishlistNotifier extends AsyncNotifier<WishlistState> {
  WishlistRemoteDataSource get _remote => ref.read(wishlistDataSourceProvider);

  @override
  Future<WishlistState> build() async {
    try {
      return WishlistState(products: await _remote.list());
    } catch (_) {
      // لا نرمي الخطأ: فشل المفضّلة يجب ألّا يُسقط شاشة السوق كلها.
      return const WishlistState(isAvailable: false);
    }
  }

  /// يقلب حالة المفضّلة لمنتج.
  ///
  /// نحدّث الحالة **تفاؤلياً** أولاً ليستجيب القلب فوراً، ثم نتراجع عن
  /// التغيير إن فشل النداء — الشبكة هنا خلف نفق بطيء، وانتظار الردّ
  /// قبل تلوين القلب يجعل الضغط يبدو معطوباً.
  ///
  /// يعيد رسالة الخطأ عند الفشل و null عند النجاح.
  Future<String?> toggle(Product product) async {
    final current = state.valueOrNull ?? const WishlistState();
    if (!current.isAvailable) return null;

    final wasInList = current.contains(product.id);
    state = AsyncValue.data(WishlistState(
      products: wasInList
          ? current.products.where((p) => p.id != product.id).toList()
          : [product, ...current.products],
    ));

    try {
      if (wasInList) {
        await _remote.remove(product.id);
      } else {
        await _remote.add(product.id);
      }
      return null;
    } catch (e) {
      state = AsyncValue.data(current);
      return DioClient.mapError(e).message;
    }
  }
}

/// هل نعرض زرّ المفضّلة أصلاً؟ نخفيه ما دام المسار معطّلاً في الخادم.
final isWishlistAvailableProvider = Provider<bool>((ref) {
  return ref.watch(wishlistProvider).valueOrNull?.isAvailable ?? false;
});

/// هل هذا المنتج في المفضّلة؟
final isFavoriteProvider = Provider.family<bool, int>((ref, productId) {
  final state = ref.watch(wishlistProvider).valueOrNull;
  return state?.contains(productId) ?? false;
});
