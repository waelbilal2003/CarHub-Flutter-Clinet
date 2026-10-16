import '../../../../core/network/api_response.dart';
import '../entities/tender.dart';

abstract interface class TenderRepository {
  Future<PaginatedList<Tender>> list({int page});
  Future<Tender> show(int id);
  Future<Tender> create({
    required String title,
    required String description,
    required double budget,
    required String deadline,
  });
}
