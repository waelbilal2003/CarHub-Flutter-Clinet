/// كل مسارات الـ API معرّفة مرة واحدة هنا (نسبية إلى AppConfig.apiBaseUrl).
///
/// مصدر الحقيقة: ملف Postman «CarHub Laravel API».
/// لا تكتب أي مسار نصياً داخل الـ datasources — استخدم هذه الثوابت.
class ApiEndpoints {
  ApiEndpoints._();

  // ── المصادقة والحساب ──
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  /// تحديث البيانات والصورة معاً — POST بصيغة multipart/form-data.
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';

  // ── عناوين الشحن ──
  static const String addresses = '/addresses';
  static String address(int id) => '/addresses/$id';
  static String addressDefault(int id) => '/addresses/$id/default';

  // ── المناقصات ──
  static const String tenders = '/tenders';
  static String tender(int id) => '/tenders/$id';

  // ── العروض ──
  static const String bids = '/bids';
  static String acceptBid(int id) => '/bids/$id/accept';

  // ── المحادثات ──
  static const String messages = '/messages';

  /// محادثة محدّدة. ⚠️ يحتاج تأكيداً من إسراء: هل [id] هو معرّف المحادثة
  /// (conversation_id) أم معرّف الطرف الآخر؟ في مثال Postman كان الطلب
  /// /messages/2 وأعاد رسائل conversation_id = 1.
  static String chat(int id) => '/messages/$id';

  // ─────────────── المرحلة 3: السوق والمتجر ───────────────

  // ⚠️ تنبيه مهم: مجموعة Postman **ناقصة** مقارنةً بـ routes/api.php
  // الفعلي في الـ Backend. المسارات أدناه مأخوذة من ملف المسارات نفسه
  // (مصدر الحقيقة الحقيقي)، لا من المجموعة — وقد تحقّقنا منها بالتشغيل.

  // ── المنتجات (تطبيق العميل) ──
  /// قائمة مصفّحة: data.data[] + data.links + data.meta.
  /// تدعم الفلترة: search, category_id, brand_id, min_price, max_price.
  /// تعيد المنتجات النشطة فقط (status = active).
  static const String products = '/products';

  /// تفاصيل منتج — الكائن مباشرة داخل data، ويضيف merchant و reviews[].
  static String product(int id) => '/products/$id';

  /// إضافة تقييم لمنتج. الخادم يستخدم updateOrCreate لكل مستخدم،
  /// فإعادة التقييم تُحدّث تقييمه السابق ولا تنشئ سطراً جديداً.
  static String productReviews(int id) => '/products/$id/reviews';

  /// التصنيفات والماركات — لفلترة السوق.
  static const String categories = '/categories';
  static const String brands = '/brands';

  // ── السلة ──
  /// سلة المستخدم الحالي — data = { id, user_id, items[], total_amount }.
  static const String cart = '/cart';

  /// إضافة منتج للسلة — body: { product_id, quantity }.
  /// ⚠️ الخادم **يجمع** الكمية على الموجود (increment) لا يستبدلها.
  static const String cartItems = '/cart/items';

  /// تعديل كمية سطر — PUT، body: { quantity } (تعيين لا جمع).
  /// يعيد **السلة كاملة** بعد التعديل.
  static String cartItem(int id) => '/cart/items/$id';

  /// تفريغ السلة — DELETE /cart. يعيد رسالة فقط بلا data.
  static const String clearCart = '/cart';

  /// المفضّلة — index / store { product_id } / destroy.
  static const String wishlists = '/wishlists';
  static String wishlist(int id) => '/wishlists/$id';

  // ── الدفع والطلبات (تطبيق العميل) ──
  /// إتمام الشراء — body: { address_id, notes }.
  /// ⚠️ مهم: الاستجابة تعيد **مصفوفة طلبات** لأن الخادم يقسّم الطلب
  /// تلقائياً حسب كل تاجر (CheckoutAction يجمّع حسب product.user_id).
  static const String checkout = '/checkout';

  /// طلباتي — قائمة مصفّحة.
  static const String orders = '/orders';

  /// تفاصيل طلب واحد (يتحقّق الخادم أنه يخصّ المستخدم الحالي).
  static String order(int id) => '/orders/$id';

  // ⚠️ فجوات مؤكّدة بعد مراجعة routes/api.php: لا مسار فاتورة،
  // ولا مسار إرجاع، ولا إلغاء طلب من العميل، ولا إحصائيات للتاجر.

  // ── تطبيق الأعمال (التاجر) ──
  /// apiResource كامل: index / store / show / update / destroy.
  ///
  /// ⚠️ عند الإضافة الحقل `images` **مطلوب** (array، صورة واحدة على
  /// الأقل، jpeg/png/jpg/gif/webp، بحد 2MB للصورة) — ملف Postman لا
  /// يذكره إطلاقاً، فمثاله فيه يفشل بـ 422.
  static const String merchantProducts = '/merchant/products';
  static String merchantProduct(int id) => '/merchant/products/$id';

  /// الطلبات الواردة للتاجر — قائمة مصفّحة (تحوي buyer بدل merchant).
  static const String merchantOrders = '/merchant/orders';
  static String merchantOrder(int id) => '/merchant/orders/$id';

  /// تحديث حالة طلب — PATCH، body: { status } من قيم OrderStatus فقط.
  static String merchantOrderStatus(int id) => '/merchant/orders/$id/status';
}
