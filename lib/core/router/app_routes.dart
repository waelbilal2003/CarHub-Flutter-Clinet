/// أسماء ومسارات التنقّل الموحّدة — تُستخدم بدل كتابة النصوص يدوياً.
class AppRoutes {
  AppRoutes._();

  // المصادقة
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // ملاحظة: لا يوجد مسار لاستعادة كلمة المرور في الـ Backend،
  // ولا مسار OTP — لذلك لا شاشة لهما.

  // الحساب
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String addresses = '/profile/addresses';

  // المناقصات والعروض
  static const String tenders = '/tenders';
  static const String createTender = '/tenders/create';
  static String tenderDetails(int id) => '/tenders/$id';
  static const String tenderDetailsPattern = '/tenders/:id';

  /// شاشة العرض المقبول بعد PATCH /bids/{id}/accept.
  static String acceptedOffer(int tenderId, int bidId) =>
      '/tenders/$tenderId/accepted/$bidId';
  static const String acceptedOfferPattern = '/tenders/:id/accepted/:bidId';

  // المحادثات
  static const String chats = '/chats';
  static String chat(int id) => '/chats/$id';
  static const String chatPattern = '/chats/:id';

  // ── السوق والمتجر (المرحلة 3) ──
  static const String marketplace = '/market';
  static String productDetails(int id) => '/market/product/$id';
  static const String productDetailsPattern = '/market/product/:id';

  static const String cart = '/cart';
  static const String checkout = '/checkout';

  /// شاشة نجاح الشراء. لا تحمل معرّفاً في المسار لأن الخادم يعيد
  /// **عدة طلبات** (تقسيم حسب التاجر)، وتُقرأ من
  /// `lastCheckoutOrdersProvider`.
  static const String orderSuccess = '/checkout/success';

  static const String myOrders = '/orders';

  // ── لوحة التاجر (تطبيق الأعمال) ──
  static const String merchantDashboard = '/merchant';
  static const String merchantOrders = '/merchant/orders';
  static const String inventory = '/merchant/inventory';
  static const String addProduct = '/merchant/inventory/add';

  // ملاحظة: لا مسارات للفاتورة ولا للإرجاع ولا لتفاصيل طلب واحد،
  // لأن الـ Backend لا يوفّر أي endpoint لها (فجوات مسجّلة لإسراء).
}
