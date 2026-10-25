import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/tender_remote_datasource.dart';
import '../../data/repositories/api_tender_repository.dart';
import '../../domain/entities/tender.dart';
import '../../domain/repositories/tender_repository.dart';

final tenderRepositoryProvider = Provider<TenderRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiTenderRepository(TenderRemoteDataSource(dioClient));
});

/// قائمة المناقصات (الصفحة الأولى + تحميل المزيد).
final tenderListProvider =
    AsyncNotifierProvider<TenderListNotifier, List<Tender>>(
  TenderListNotifier.new,
);

class TenderListNotifier extends AsyncNotifier<List<Tender>> {
  TenderRepository get _repo => ref.read(tenderRepositoryProvider);

  int _page = 1;
  bool _hasMore = false;
  bool get hasMore => _hasMore;

  @override
  Future<List<Tender>> build() async {
    _page = 1;
    final result = await _repo.list(page: _page);
    _hasMore = result.hasMore;
    return result.items;
  }

  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      final result = await _repo.list(page: _page);
      _hasMore = result.hasMore;
      return result.items;
    });
  }

  /// تحميل الصفحة التالية وإضافتها للقائمة الحالية.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? const <Tender>[];
    try {
      final result = await _repo.list(page: _page + 1);
      _page += 1;
      _hasMore = result.hasMore;
      state = AsyncValue.data([...current, ...result.items]);
    } catch (_) {
      // نُبقي القائمة الحالية كما هي عند فشل تحميل المزيد.
    }
  }
}

/// تفاصيل مناقصة واحدة.
final tenderDetailsProvider =
    FutureProvider.family<Tender, int>((ref, id) async {
  return ref.watch(tenderRepositoryProvider).show(id);
});

/// حالة إنشاء مناقصة.
class CreateTenderState {
  final bool isLoading;
  final String? error;
  const CreateTenderState({this.isLoading = false, this.error});
}

final createTenderProvider =
    StateNotifierProvider<CreateTenderController, CreateTenderState>((ref) {
  return CreateTenderController(ref);
});

class CreateTenderController extends StateNotifier<CreateTenderState> {
  final Ref _ref;
  CreateTenderController(this._ref) : super(const CreateTenderState());

  /// [deadline] يُرسل بصيغة "yyyy-MM-dd HH:mm:ss" كما في ملف Postman.
  Future<Tender?> create({
    required String title,
    required String category,
    required String city,
    required String description,
    required double budget,
    required DateTime deadline,
  }) async {
    state = const CreateTenderState(isLoading: true);
    try {
      final tender = await _ref.read(tenderRepositoryProvider).create(
            title: title,
            category: category,
            city: city,
            description: description,
            budget: budget,
            deadline: _formatDeadline(deadline),
          );
      state = const CreateTenderState(isLoading: false);
      // نحدّث القائمة لتظهر المناقصة الجديدة فوراً.
      await _ref.read(tenderListProvider.notifier).refreshList();
      return tender;
    } catch (e) {
      state = CreateTenderState(isLoading: false, error: e.toString());
      return null;
    }
  }

  static String _formatDeadline(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}
