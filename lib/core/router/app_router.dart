import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/presentation/screens/addresses_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/bids/presentation/screens/accepted_offer_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/merchant/presentation/screens/add_product_screen.dart';
import '../../features/merchant/presentation/screens/inventory_screen.dart';
import '../../features/merchant/presentation/screens/merchant_dashboard_screen.dart';
import '../../features/merchant/presentation/screens/merchant_orders_screen.dart';
import '../../features/messages/presentation/screens/chat_screen.dart';
import '../../features/messages/presentation/screens/chats_list_screen.dart';
import '../../features/orders/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/my_orders_screen.dart';
import '../../features/orders/presentation/screens/order_success_screen.dart';
import '../../features/products/presentation/screens/marketplace_screen.dart';
import '../../features/products/presentation/screens/product_details_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/tenders/presentation/screens/create_tender_screen.dart';
import '../../features/tenders/presentation/screens/tender_details_screen.dart';
import '../../features/tenders/presentation/screens/tenders_list_screen.dart';
import 'app_routes.dart';

/// مزوّد الراوتر. يستمع لحالة المصادقة ويعيد التوجيه تلقائياً:
///  - المستخدم غير المسجّل يُمنع من الشاشات الداخلية.
///  - المستخدم المسجّل يُمنع من العودة لشاشات الدخول.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final status = authState.status;
      final loc = state.matchedLocation;

      // أثناء التحقّق الأولي (GET /auth/me) نبقى في شاشة البداية.
      if (status == AuthStatus.unknown) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final loggingIn = loc == AppRoutes.login || loc == AppRoutes.register;
      final onSplash = loc == AppRoutes.splash;

      if (status == AuthStatus.unauthenticated) {
        return loggingIn ? null : AppRoutes.login;
      }

      if (status == AuthStatus.authenticated && (loggingIn || onSplash)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),

      // الحساب
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (_, __) => const AddressesScreen(),
      ),

      // المناقصات — ترتيب مهم: create قبل :id حتى لا يبتلعها المسار المتغيّر.
      GoRoute(
        path: AppRoutes.createTender,
        builder: (_, __) => const CreateTenderScreen(),
      ),
      GoRoute(
        path: AppRoutes.tenders,
        builder: (_, __) => const TendersListScreen(),
      ),
      GoRoute(
        path: AppRoutes.acceptedOfferPattern,
        builder: (_, state) => AcceptedOfferScreen(
          tenderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          bidId: int.tryParse(state.pathParameters['bidId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.tenderDetailsPattern,
        builder: (_, state) => TenderDetailsScreen(
          tenderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),

      // المحادثات
      GoRoute(path: AppRoutes.chats, builder: (_, __) => const ChatsListScreen()),
      GoRoute(
        path: AppRoutes.chatPattern,
        builder: (_, state) => ChatScreen(
          chatId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),

      // ── السوق والمتجر (المرحلة 3) ──
      GoRoute(
        path: AppRoutes.marketplace,
        builder: (_, __) => const MarketplaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetailsPattern,
        builder: (_, state) => ProductDetailsScreen(
          productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),

      // ترتيب مهم: success قبل checkout ليس ضرورياً هنا لأنهما مساران
      // كاملان لا نمطان متغيّران، لكن نبقيهما متجاورين للوضوح.
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        builder: (_, __) => const OrderSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.myOrders,
        builder: (_, __) => const MyOrdersScreen(),
      ),

      // ── لوحة التاجر ──
      // addProduct و inventory و orders قبل merchantDashboard في القراءة
      // لا يهم هنا لأن كلها مسارات ثابتة لا أنماط متغيّرة.
      GoRoute(
        path: AppRoutes.merchantDashboard,
        builder: (_, __) => const MerchantDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.merchantOrders,
        builder: (_, __) => const MerchantOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (_, __) => const InventoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        builder: (_, __) => const AddProductScreen(),
      ),
    ],
  );
});

/// جسر يجعل go_router يعيد تقييم redirect عند تغيّر حالة المصادقة.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
