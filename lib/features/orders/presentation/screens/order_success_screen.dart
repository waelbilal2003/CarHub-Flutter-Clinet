import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';

/// شاشة نجاح الطلب — تعرض نتيجة POST /checkout.
///
/// مطابقة لـ 12_order_success.html في: خلفية كحلية داكنة، هالة خضراء
/// خلف دائرة صح كبيرة، عنوان أبيض، شارة رقم الطلب بشكل حبّة، نص
/// توضيحي، ثم زرّان بشكل حبّة (متابعة الطلبات / العودة للرئيسية).
///
/// الفرق الجوهري عن التصميم — وهو سلوك الـ Backend لا خطأ في التصميم:
/// التصميم يفترض **رقم طلب واحد** (#CH-8829)، بينما الخادم يقسّم
/// الشراء تلقائياً إلى **طلب مستقل لكل تاجر** ويعيد مصفوفة. لذلك عند
/// وجود أكثر من طلب نعرض شارة لكل رقم ونشرح للعميل سبب التقسيم.
class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(lastCheckoutOrdersProvider);
    final isSplit = orders.length > 1;

    return Scaffold(
      backgroundColor: AppColors.onSecondaryFixed,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // الهالة الخضراء المضيئة خلف الأيقونة.
            Positioned(
              top: 40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.28),
                      AppColors.onSecondaryFixed.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.all(AppDimensions.containerPadding),
              children: [
                const SizedBox(height: AppDimensions.spaceXL),
                const _SuccessIcon(),
                const SizedBox(height: AppDimensions.spaceL),
                Text(
                  'تم إرسال طلبك بنجاح!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppDimensions.spaceM),

                if (orders.isEmpty)
                  Text(
                    'تعذّر قراءة تفاصيل الطلب، لكن عملية الشراء تمّت. '
                    'راجع «طلباتي» للاطّلاع عليها.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.tertiaryFixedDim),
                  )
                else ...[
                  if (isSplit)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDimensions.spaceM),
                      child: Text(
                        'سلتك ضمّت قطعاً من ${orders.length} متاجر، '
                        'فقُسّم طلبك تلقائياً إلى ${orders.length} طلبات '
                        '— طلب مستقل لكل متجر:',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.tertiaryFixedDim),
                      ),
                    ),
                  for (final order in orders)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.spaceS),
                      child: _OrderBadge(order: order, detailed: isSplit),
                    ),
                ],

                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'سيتواصل معك التاجر مباشرة لتنسيق الاستلام/التوصيل.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.tertiaryFixedDim),
                ),

                const SizedBox(height: AppDimensions.spaceXL),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.myOrders),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('متابعة الطلبات'),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.home),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.tertiaryFixedDim,
                      side: BorderSide(
                        color: AppColors.outline.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('العودة للرئيسية'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// دائرة النجاح الكبيرة بحلقتين كما في التصميم.
class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryContainer.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 56,
            color: AppColors.primaryContainer,
          ),
        ),
      ),
    );
  }
}

/// شارة رقم الطلب — حبّة داكنة شفافة بحدّ رفيع كما في التصميم.
/// عند التقسيم تُظهر أيضاً اسم التاجر والمبلغ حتى يعرف العميل
/// أيّ طلب يخصّ أيّ متجر.
class _OrderBadge extends StatelessWidget {
  final Order order;
  final bool detailed;

  const _OrderBadge({required this.order, required this.detailed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.onSecondaryFixedVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long,
              size: 18, color: AppColors.inversePrimary),
          const SizedBox(width: AppDimensions.spaceS),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'رقم الطلب: ${order.orderNumber}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.tertiaryFixedDim),
                ),
                if (detailed)
                  Text(
                    '${order.merchant?.name ?? 'متجر'} • '
                    '${Formatters.price(order.totalAmount)}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.tertiaryFixedDim),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
