import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/bid.dart';
import '../../domain/repositories/bid_repository.dart';
import '../datasources/bid_remote_datasource.dart';

class ApiBidRepository implements BidRepository {
  final BidRemoteDataSource _remote;
  ApiBidRepository(this._remote);

  @override
  Future<PaginatedList<Bid>> list({
    int page = 1,
    int? tenderId,
    int? merchantId,
  }) async {
    try {
      return await _remote.list(
        page: page,
        tenderId: tenderId,
        merchantId: merchantId,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Bid> submit({
    required int tenderId,
    required double price,
    String? notes,
  }) async {
    try {
      return await _remote.submit(
        tenderId: tenderId,
        price: price,
        notes: notes,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Bid> accept(int bidId) async {
    try {
      return await _remote.accept(bidId);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
