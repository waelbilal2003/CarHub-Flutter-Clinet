import '../../../../core/network/api_response.dart';
import '../entities/bid.dart';

abstract interface class BidRepository {
  Future<PaginatedList<Bid>> list({int page, int? tenderId, int? merchantId});

  Future<Bid> submit({
    required int tenderId,
    required double price,
    String? notes,
  });

  /// PATCH /bids/{id}/accept — يُغلق المناقصة ويرفض باقي العروض في الخادم.
  Future<Bid> accept(int bidId);
}
