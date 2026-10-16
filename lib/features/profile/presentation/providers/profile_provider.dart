import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/api_profile_repository.dart';
import '../../domain/repositories/profile_repository.dart';

/// مستودع الملف الشخصي — API حقيقي فقط.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiProfileRepository(ProfileRemoteDataSource(dioClient));
});

/// حالة عملية تحديث الملف (تحميل + خطأ).
class ProfileActionState {
  final bool isLoading;
  final String? error;
  const ProfileActionState({this.isLoading = false, this.error});
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileActionState>((ref) {
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<ProfileActionState> {
  final Ref _ref;
  ProfileController(this._ref) : super(const ProfileActionState());

  ProfileRepository get _repo => _ref.read(profileRepositoryProvider);

  /// يحدّث البيانات و/أو الصورة عبر نداء واحد (POST /auth/profile)
  /// ثم يزامن المستخدم في حالة المصادقة.
  Future<bool> updateProfile({
    required String name,
    String? email,
    String? phone,
    String? avatarPath,
  }) async {
    state = const ProfileActionState(isLoading: true);
    try {
      final user = await _repo.updateProfile(
        name: name,
        email: email,
        phone: phone,
        avatarPath: avatarPath,
      );
      _ref.read(authProvider.notifier).updateUser(user);
      state = const ProfileActionState(isLoading: false);
      return true;
    } on Failure catch (f) {
      state = ProfileActionState(isLoading: false, error: f.message);
      return false;
    }
  }

  /// رفع صورة فقط — يستخدم نفس المسار مع الاسم الحالي (الخادم يتطلبه).
  Future<bool> uploadAvatar(String filePath) async {
    final current = _ref.read(authProvider).user;
    return updateProfile(
      name: current?.name ?? '',
      phone: current?.phone,
      avatarPath: filePath,
    );
  }
}
