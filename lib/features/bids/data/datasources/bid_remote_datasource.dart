import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/bid.dart';

/// مصدر بيانات العروض.
///
/// من ملف Postman:
///   GET   /bids                  → data.data[] + data.meta
///   GET   /bids?tender_id=1      → نفس الشكل مفلتراً
///   GET   /bids?merchant_id=2    → نفس الشكل مفلتراً
///   POST  /bids                  → الكائن مباشرة داخل data (multipart)
///   PATCH /bids/{id}/accept      → الكائن مباشرة داخل data
class BidRemoteDataSource {
  final DioClient _client;
  BidRemoteDataSource(this._client);

  Future<PaginatedList<Bid>> list({
    int page = 1,
    int? tenderId,
    int? merchantId,
  }) async {
    final res = await _client.dio.get(
      ApiEndpoints.bids,
      queryParameters: {
        'page': page,
        if (tenderId != null) 'tender_id': tenderId,
        if (merchantId != null) 'merchant_id': merchantId,
      },
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Bid.fromJson);
  }

  Future<Bid> submit({
    required int tenderId,
    required double price,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'tender_id': tenderId.toString(),
      'price': price.toString(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    final res = await _client.dio.post(ApiEndpoints.bids, data: formData);
    final envelope = ApiEnvelope.from(res.data);
    return Bid.fromJson(envelope.object);
  }

  /// قبول عرض. الخادم يغلق المناقصة ويرفض باقي العروض تلقائياً،
  /// لذلك يجب إعادة تحميل المناقصة وقائمة العروض بعد النجاح.
  Future<Bid> accept(int bidId) async {
    final res = await _client.dio.patch(ApiEndpoints.acceptBid(bidId));
    final envelope = ApiEnvelope.from(res.data);
    return Bid.fromJson(envelope.object);
  }
}
