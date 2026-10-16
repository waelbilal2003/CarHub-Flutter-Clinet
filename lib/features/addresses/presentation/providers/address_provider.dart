import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/address_remote_datasource.dart';
import '../../data/repositories/api_address_repository.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiAddressRepository(AddressRemoteDataSource(dioClient));
});

/// قائمة العناوين — تُحمّل من GET /addresses.
final addressListProvider =
    AsyncNotifierProvider<AddressListNotifier, List<Address>>(
  AddressListNotifier.new,
);

class AddressListNotifier extends AsyncNotifier<List<Address>> {
  AddressRepository get _repo => ref.read(addressRepositoryProvider);

  @override
  Future<List<Address>> build() => _repo.list();

  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  Future<bool> add(Address address) async {
    try {
      await _repo.create(address);
      await refreshList();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> edit(int id, Address address) async {
    try {
      await _repo.update(id, address);
      await refreshList();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// الخادم يلغي الافتراضي عن باقي العناوين تلقائياً، لذا نعيد تحميل القائمة.
  Future<bool> makeDefault(int id) async {
    try {
      await _repo.setDefault(id);
      await refreshList();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int id) async {
    try {
      await _repo.delete(id);
      await refreshList();
      return true;
    } catch (_) {
      return false;
    }
  }
}
