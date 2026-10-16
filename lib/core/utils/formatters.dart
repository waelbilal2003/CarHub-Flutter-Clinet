import 'package:intl/intl.dart';

/// تنسيق الأرقام والتواريخ المعروضة للمستخدم.
///
/// سبب وجود هذا الملف: الـ Backend يعيد المبالغ **نصاً** ("1200.00")،
/// وتصاميم Stitch تعرضها بفواصل آلاف وبدون كسور عندما تكون صحيحة
/// ("1,250 ر.س"). التحويل يتم مرة واحدة هنا لا في كل شاشة.
class Formatters {
  Formatters._();

  /// أرقام لاتينية (1,250) لا عربية-هندية — كما في تصاميم Stitch،
  /// حيث تُعرض الأسعار وأرقام الطلبات بأرقام لاتينية داخل نص عربي.
  static final NumberFormat _integer = NumberFormat('#,##0', 'en');
  static final NumberFormat _decimal = NumberFormat('#,##0.00', 'en');

  /// مبلغ بالريال كما في التصميم: «1,250 ر.س».
  /// يحذف الكسور عندما تكون صفراً (1200.00 → «1,200 ر.س»).
  static String price(double value) => '${number(value)} ر.س';

  /// الرقم وحده بلا عملة — للحالات التي يُعرض فيها السعر والعملة
  /// بحجمين مختلفين (بطاقة المنتج في 07_marketplace).
  static String number(double value) {
    final isWhole = value == value.roundToDouble();
    return isWhole ? _integer.format(value) : _decimal.format(value);
  }

  /// تاريخ مختصر بالعربية كما في بطاقة الطلب: «12 أكتوبر 2023».
  static String date(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('d MMMM y', 'ar').format(value.toLocal());
  }

  /// تاريخ ووقت — لتفاصيل الطلب.
  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('d MMMM y • h:mm a', 'ar').format(value.toLocal());
  }

  /// صيغة عربية سليمة للعدّ: «قطعة واحدة / قطعتان / 3 قطع».
  /// التصميم (13_my_orders) يكتب «3 عناصر» و«1 عنصر»، والصيغة الصحيحة
  /// في العربية تتغيّر مع العدد، لذلك نضبطها هنا مركزياً.
  static String itemCount(int count) => switch (count) {
        0 => 'لا عناصر',
        1 => 'عنصر واحد',
        2 => 'عنصران',
        >= 3 && <= 10 => '$count عناصر',
        _ => '$count عنصراً',
      };
}
