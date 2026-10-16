import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/tender.dart';

/// مصدر بيانات المناقصات.
///
/// من ملف Postman:
///   GET  /tenders      → data.data[] + data.meta   (مصفّحة)
///   POST /tenders      → الكائن مباشرة داخل data   (multipart)
///   GET  /tenders/{id} → الكائن مباشرة داخل data
class TenderRemoteDataSource {
  final DioClient _client;
  TenderRemoteDataSource(this._client);

  Future<PaginatedList<Tender>> list({int page = 1}) async {
    final res = await _client.dio.get(
      ApiEndpoints.tenders,
      queryParameters: {'page': page},
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Tender.fromJson);
  }

  Future<Tender> show(int id) async {
    final res = await _client.dio.get(ApiEndpoints.tender(id));
    final envelope = ApiEnvelope.from(res.data);
    // هنا الكائن يعود مباشرة داخل data (وليس data.tender).
    return Tender.fromJson(envelope.object);
  }

  /// [deadline] يجب أن يُرسل بصيغة "yyyy-MM-dd HH:mm:ss" كما في المجموعة.
  Future<Tender> create({
    required String title,
    required String description,
    required double budget,
    required String deadline,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'budget': budget.toString(),
      'deadline': deadline,
    });

    final res = await _client.dio.post(ApiEndpoints.tenders, data: formData);
    final envelope = ApiEnvelope.from(res.data);
    return Tender.fromJson(envelope.object);
  }
}
