import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order.dart';

/// لون شارة حالة الطلب — مأخوذ من تصاميم Stitch:
///  • «قيد التجهيز» كهرماني `#F59E0B` (13_my_orders.html) → [AppColors.warning]
///  • «جديد/قيد الانتظار» أخضر حيوي (04_merchant_orders.html)
///  • «مكتمل» أخضر داكن، «ملغى» أحمر، «تم الشحن» رمادي-أزرق.
///
/// النصّ المعروض يبقى دائماً `status_label` القادم من الخادم؛ هذه
/// الدالة تحدّد اللون فقط، فلا نترجم الحالات محلياً.
Color orderStatusStyle(Order order) {
  return switch (OrderStatus.fromValue(order.status)) {
    OrderStatus.pending => AppColors.primaryContainer,
    OrderStatus.processing => AppColors.warning,
    OrderStatus.shipped => AppColors.secondary,
    OrderStatus.delivered => AppColors.onPrimaryFixedVariant,
    OrderStatus.completed => AppColors.primary,
    OrderStatus.canceled => AppColors.error,
    // حالة غير معروفة قادمة من الخادم: لون محايد بدل إخفاء الشارة.
    null => AppColors.onSurfaceVariant,
  };
}
