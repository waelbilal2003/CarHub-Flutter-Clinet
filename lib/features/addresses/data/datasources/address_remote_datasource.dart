import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/address.dart';

/// مصدر بيانات العناوين.
///
/// أشكال الاستجابة (من ملف Postman):
///   GET    /addresses            → data.data[]   (بلا meta)
///   POST   /addresses            → data.address
///   GET    /addresses/{id}       → data.address
///   PUT    /addresses/{id}       → data.address
///   PATCH  /addresses/{id}/default → data.address
///   DELETE /addresses/{id}       → data = null
class AddressRemoteDataSource {
  final DioClient _client;
  AddressRemoteDataSource(this._client);

  Future<List<Address>> list() async {
    final res = await _client.dio.get(ApiEndpoints.addresses);
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Address.fromJson).items;
  }

  Future<Address> show(int id) async {
    final res = await _client.dio.get(ApiEndpoints.address(id));
    final envelope = ApiEnvelope.from(res.data);
    return Address.fromJson(envelope.objectAt('address'));
  }

  Future<Address> create(Address address) async {
    final res = await _client.dio.post(
      ApiEndpoints.addresses,
      data: address.toRequestJson(),
    );
    final envelope = ApiEnvelope.from(res.data);
    return Address.fromJson(envelope.objectAt('address'));
  }

  Future<Address> update(int id, Address address) async {
    final res = await _client.dio.put(
      ApiEndpoints.address(id),
      data: address.toRequestJson(),
    );
    final envelope = ApiEnvelope.from(res.data);
    return Address.fromJson(envelope.objectAt('address'));
  }

  Future<Address> setDefault(int id) async {
    final res = await _client.dio.patch(ApiEndpoints.addressDefault(id));
    final envelope = ApiEnvelope.from(res.data);
    return Address.fromJson(envelope.objectAt('address'));
  }

  Future<void> delete(int id) async {
    final res = await _client.dio.delete(ApiEndpoints.address(id));
    ApiEnvelope.from(res.data);
  }
}
