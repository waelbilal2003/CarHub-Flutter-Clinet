import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../storage/token_storage.dart';

/// مزوّدات البنية التحتية المشتركة بين كل الميزات.
/// تُنشأ مرة واحدة وتُحقن حيثما لزم.

/// التخزين الآمن للتوكن.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// عميل الشبكة Dio (يعتمد على التخزين لإرفاق التوكن).
final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return DioClient(tokenStorage);
});
