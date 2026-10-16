import '../../../../core/network/dio_client.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_datasource.dart';

class ApiAddressRepository implements AddressRepository {
  final AddressRemoteDataSource _remote;
  ApiAddressRepository(this._remote);

  @override
  Future<List<Address>> list() async {
    try {
      return await _remote.list();
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Address> show(int id) async {
    try {
      return await _remote.show(id);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Address> create(Address address) async {
    try {
      return await _remote.create(address);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Address> update(int id, Address address) async {
    try {
      return await _remote.update(id, address);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Address> setDefault(int id) async {
    try {
      return await _remote.setDefault(id);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _remote.delete(id);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
