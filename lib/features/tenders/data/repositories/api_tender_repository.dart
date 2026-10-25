import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/tender.dart';
import '../../domain/repositories/tender_repository.dart';
import '../datasources/tender_remote_datasource.dart';

class ApiTenderRepository implements TenderRepository {
  final TenderRemoteDataSource _remote;
  ApiTenderRepository(this._remote);

  @override
  Future<PaginatedList<Tender>> list({int page = 1}) async {
    try {
      return await _remote.list(page: page);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Tender> show(int id) async {
    try {
      return await _remote.show(id);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Tender> create({
    required String title,
    required String category,
    required String city,
    required String description,
    required double budget,
    required String deadline,
  }) async {
    try {
      return await _remote.create(
        title: title,
        category: category,
        city: city,
        description: description,
        budget: budget,
        deadline: deadline,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
