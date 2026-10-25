import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/api_product_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiProductRepository(ProductRemoteDataSource(dioClient));
});

/// نص البحث في السوق. يُنفَّذ **على الخادم** عبر `GET /products?search=`.
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// فلتر توافق السيارة (car_make + car_model [+ year]) — يضبطه المساعد الذكي
/// عند فتح السوق من بطاقة open_marketplace_search، ويمسحه المستخدم من الشريحة.
class CarFilter {
  final String make;
  final String model;
  final int? year;
  const CarFilter({required this.make, required this.model, this.year});

  String get label => [make, model, if (year != null) '$year'].join(' ');
}

final productCarFilterProvider = StateProvider<CarFilter?>((ref) => null);

/// قائمة منتجات السوق — GET /products (الصفحة الأولى + تحميل المزيد).
///
/// تعيد البناء تلقائياً عند تغيّر نص البحث، مع تأخير قصير حتى لا نرسل
/// طلباً لكل حرف يكتبه المستخدم.
final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(
  ProductListNotifier.new,
);

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  ProductRepository get _repo => ref.read(productRepositoryProvider);

  int _page = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  /// هل بقيت صفحات؟ يقرؤها مؤشّر «تحميل المزيد» أسفل الشبكة.
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// صفحة من الخادم بالبحث وفلتر السيارة الحاليين.
  Future<PaginatedList<Product>> _fetch(int page) {
    final car = ref.read(productCarFilterProvider);
    return _repo.list(
      page: page,
      search: ref.read(productSearchQueryProvider),
      carMake: car?.make,
      carModel: car?.model,
      year: car?.year,
    );
  }

  @override
  Future<List<Product>> build() async {
    final query = ref.watch(productSearchQueryProvider);
    ref.watch(productCarFilterProvider);

    // كتم الكتابة: ننتظر 400ms قبل إرسال البحث للخادم. إن غيّر المستخدم
    // النص خلالها أُلغيت هذه البناءة وبدأت أخرى، فلا يصل إلا آخر نص.
    if (query.trim().isNotEmpty) {
      final completer = Completer<void>();
      final timer = Timer(const Duration(milliseconds: 400), completer.complete);
      ref.onDispose(() {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    }

    _page = 1;
    final result = await _fetch(_page);
    _hasMore = result.hasMore;
    return result.items;
  }

  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      final result = await _fetch(_page);
      _hasMore = result.hasMore;
      return result.items;
    });
  }

  /// الصفحة التالية تُضاف للقائمة الحالية بدل استبدالها (تمرير لا نهائي).
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    final current = state.valueOrNull ?? const <Product>[];
    _isLoadingMore = true;
    try {
      final result = await _fetch(_page + 1);
      _page += 1;
      _hasMore = result.hasMore;
      state = AsyncValue.data([...current, ...result.items]);
    } catch (_) {
      // نُبقي القائمة الحالية كما هي عند فشل تحميل المزيد،
      // فلا نمسح ما يراه المستخدم بسبب صفحة واحدة فاشلة.
    } finally {
      _isLoadingMore = false;
    }
  }
}

/// تفاصيل منتج واحد — GET /products/{id} (يشمل merchant و reviews).
final productDetailsProvider =
    FutureProvider.family<Product, int>((ref, id) async {
  return ref.watch(productRepositoryProvider).show(id);
});

/// حالة إرسال تقييم لمنتج.
class ReviewSubmitState {
  final bool isLoading;
  final String? error;
  const ReviewSubmitState({this.isLoading = false, this.error});
}

final submitReviewProvider =
    StateNotifierProvider<SubmitReviewController, ReviewSubmitState>((ref) {
  return SubmitReviewController(ref);
});

class SubmitReviewController extends StateNotifier<ReviewSubmitState> {
  final Ref _ref;
  SubmitReviewController(this._ref) : super(const ReviewSubmitState());

  /// الخادم يستخدم updateOrCreate، فإرسال تقييم ثانٍ من نفس المستخدم
  /// يُحدّث تقييمه السابق بدل إضافة سطر جديد.
  Future<bool> submit({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    state = const ReviewSubmitState(isLoading: true);
    try {
      await _ref.read(productRepositoryProvider).addReview(
            productId: productId,
            rating: rating,
            comment: comment,
          );
      state = const ReviewSubmitState(isLoading: false);
      // نعيد تحميل التفاصيل ليظهر التقييم الجديد ضمن reviews[].
      _ref.invalidate(productDetailsProvider(productId));
      return true;
    } catch (e) {
      state = ReviewSubmitState(isLoading: false, error: e.toString());
      return false;
    }
  }
}
