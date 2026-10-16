import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../tenders/presentation/providers/tender_provider.dart';
import '../../data/datasources/bid_remote_datasource.dart';
import '../../data/repositories/api_bid_repository.dart';
import '../../domain/entities/bid.dart';
import '../../domain/repositories/bid_repository.dart';

final bidRepositoryProvider = Provider<BidRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiBidRepository(BidRemoteDataSource(dioClient));
});

/// عروض مناقصة محددة — GET /bids?tender_id=
final tenderBidsProvider =
    FutureProvider.family<List<Bid>, int>((ref, tenderId) async {
  final result =
      await ref.watch(bidRepositoryProvider).list(tenderId: tenderId);
  return result.items;
});

/// كل العروض (أو عروض تاجر محدد عبر merchantId).
final bidsProvider =
    FutureProvider.family<List<Bid>, int?>((ref, merchantId) async {
  final result =
      await ref.watch(bidRepositoryProvider).list(merchantId: merchantId);
  return result.items;
});

class BidActionState {
  final bool isLoading;
  final String? error;
  const BidActionState({this.isLoading = false, this.error});
}

final bidActionProvider =
    StateNotifierProvider<BidActionController, BidActionState>((ref) {
  return BidActionController(ref);
});

class BidActionController extends StateNotifier<BidActionState> {
  final Ref _ref;
  BidActionController(this._ref) : super(const BidActionState());

  BidRepository get _repo => _ref.read(bidRepositoryProvider);

  Future<bool> submit({
    required int tenderId,
    required double price,
    String? notes,
  }) async {
    state = const BidActionState(isLoading: true);
    try {
      await _repo.submit(tenderId: tenderId, price: price, notes: notes);
      state = const BidActionState(isLoading: false);
      _ref.invalidate(tenderBidsProvider(tenderId));
      return true;
    } catch (e) {
      state = BidActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// قبول عرض.
  ///
  /// مهم: الخادم يُغلق المناقصة ويرفض باقي العروض تلقائياً، لذلك نُبطل
  /// كاش المناقصة وعروضها معاً حتى تعكس الواجهة الحالة الجديدة فوراً.
  Future<bool> accept({required int bidId, required int tenderId}) async {
    state = const BidActionState(isLoading: true);
    try {
      await _repo.accept(bidId);
      state = const BidActionState(isLoading: false);
      _ref.invalidate(tenderBidsProvider(tenderId));
      _ref.invalidate(tenderDetailsProvider(tenderId));
      await _ref.read(tenderListProvider.notifier).refreshList();
      return true;
    } catch (e) {
      state = BidActionState(isLoading: false, error: e.toString());
      return false;
    }
  }
}
