import '../entities/address.dart';

/// عقد عناوين الشحن — يغطّي المسارات الستة في الـ Backend.
abstract interface class AddressRepository {
  Future<List<Address>> list();
  Future<Address> show(int id);
  Future<Address> create(Address address);
  Future<Address> update(int id, Address address);

  /// PATCH /addresses/{id}/default — الخادم يلغي الافتراضي عن الباقي.
  Future<Address> setDefault(int id);

  Future<void> delete(int id);
}
