import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/widgets/order_status_style.dart';
import '../providers/merchant_provider.dart';
import '../widgets/merchant_scaffold.dart';

/// لوحة تحكم التاجر — 02_merchant_dashboard.html.
///
/// مطابقة للتصميم في: عنوان «لوحة التحكم» ونص ترحيبي، شبكة بطاقات
/// ملخّص (رقم كبير + تسمية + أيقونة في مربّع ملوّن)، ثم قائمة «أحدث
/// الطلبات» ببطاقة بيضاء وأسطر فيها أيقونة إيصال ورقم الطلب والمبلغ
/// وشارة الحالة.
///
/// ⚠️ فجوة مؤكّدة: لا يوجد endpoint لإحصائيات لوحة التاجر. التصميم
/// يعرض «المبيعات اليومية» و«تنبيهات المخزون المنخفض» و«المناقصات
/// النشطة» — ولا مصدر لأيٍّ منها.
/// ما فعلناه بدل اختراع أرقام: اشتققنا الأرقام القابلة للاشتقاق فعلاً
/// من GET /merchant/orders (عدد الطلبات المعلّقة، وقيمة مبيعات اليوم
/// من طلبات اليوم المحمّلة)، ووضعنا بطاقة رابعة تشرح صراحةً أن
/// إحصائية المخزون تنتظر مساراً من الـ Backend.
///
/// انتبهي: هذه الأرقام محسوبة من **الصفحة الأولى فقط** من الطلبات
/// (15 طلباً)، فهي مؤشّر لا تقرير محاسبي — والنص في الشاشة يقول ذلك.
class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(merchantOrdersProvider);
    final user = ref.watch(authProvider).user;

    return MerchantScaffold(
      navIndex: 0,
      title: 'CarHub للأعمال',
      body: RefreshIndicator(
        onRefresh: () => ref.read(merchantOrdersProvider.notifier).refreshList(),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.cloud_off, size: 56, color: AppColors.textHint),
              const SizedBox(height: AppDimensions.spaceM),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceXL),
                child: Text(e.toString(),
                    textAlign: TextAlign.center, style: AppTextStyles.bodySm),
              ),
              Center(
                child: TextButton(
                  onPressed: () =>
                      ref.read(merchantOrdersProvider.notifier).refreshList(),
                  child: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
          data: (orders) => _Dashboard(orders: orders, merchantName: user?.name),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final List<Order> orders;
  final String? merchantName;

  const _Dashboard({required this.orders, required this.merchantName});

  /// عدد الطلبات التي تنتظر تصرّفاً من التاجر.
  int get _pendingCount =>
      orders.where((o) => o.status == OrderStatus.pending.value).length;

  /// مبيعات اليوم من الطلبات المحمّلة (نستثني الملغاة).
  double get _todaySales {
    final now = DateTime.now();
    return orders
        .where((o) {
          final date = o.createdAt?.toLocal();
          if (date == null) return false;
          if (o.status == OrderStatus.canceled.value) return false;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<double>(0, (acc, o) => acc + o.totalAmount);
  }

  /// إجمالي قيمة كل الطلبات المحمّلة (غير الملغاة).
  double get _totalValue => orders
      .where((o) => o.status != OrderStatus.canceled.value)
      .fold<double>(0, (acc, o) => acc + o.totalAmount);

  @override
  Widget build(BuildContext context) {
    final recent = orders.take(5).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.containerPadding,
        AppDimensions.spaceL,
        AppDimensions.containerPadding,
        120,
      ),
      children: [
        const Text('لوحة التحكم', style: AppTextStyles.headlineXl),
        const SizedBox(height: AppDimensions.spaceXS),
        Text(
          merchantName == null
              ? 'نظرة عامة على نشاطك في CarHub.'
              : 'مرحباً $merchantName، إليك نظرة عامة على نشاطك.',
          style: AppTextStyles.bodyLg
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppDimensions.spaceL),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppDimensions.cardGap,
          crossAxisSpacing: AppDimensions.cardGap,
          childAspectRatio: 1.15,
          children: [
            _SummaryCard(
              label: 'مبيعات اليوم',
              value: Formatters.price(_todaySales),
              hint: 'من الطلبات المحمّلة',
              icon: Icons.payments_outlined,
              color: AppColors.primaryContainer,
            ),
            _SummaryCard(
              label: 'طلبات قيد الانتظار',
              value: '$_pendingCount',
              hint: 'تحتاج لمعالجة',
              icon: Icons.local_shipping_outlined,
              color: AppColors.warning,
            ),
            _SummaryCard(
              label: 'إجمالي الطلبات',
              value: '${orders.length}',
              hint: Formatters.price(_totalValue),
              icon: Icons.receipt_long_outlined,
              color: AppColors.secondary,
            ),
            // بطاقة صريحة عن الفجوة بدل رقم مخترع.
            const _MissingStatCard(
              label: 'تنبيهات المخزون',
              hint: 'بانتظار مسار مخزون من الـ Backend',
              icon: Icons.inventory_2_outlined,
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spaceXL),
        Row(
          children: [
            const Text('أحدث الطلبات', style: AppTextStyles.headlineMd),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(AppRoutes.merchantOrders),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: AppColors.surfaceContainerHighest),
            boxShadow: AppDimensions.cardShadow,
          ),
          child: recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppDimensions.spaceXL),
                  child: Center(
                    child: Text('لم تصلك أي طلبات بعد.',
                        style: AppTextStyles.bodySm),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      _RecentOrderTile(order: recent[i]),
                      if (i != recent.length - 1)
                        const Divider(
                            height: 1, color: AppColors.surfaceVariant),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// بطاقة ملخّص — رقم كبير وتسمية وأيقونة داخل مربّع ملوّن، كما في
/// التصميم.
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.surfaceContainerHighest),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(label, style: AppTextStyles.bodySm),
          Text(
            value,
            style: AppTextStyles.headlineMd,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            hint,
            style: AppTextStyles.labelSm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// بطاقة إحصائية لا مصدر لها في الـ API — تقول ذلك صراحةً بدل رقم.
class _MissingStatCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;

  const _MissingStatCard({
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textHint, size: 22),
          const Spacer(),
          Text(label, style: AppTextStyles.bodySm),
          const Text('—', style: AppTextStyles.headlineMd),
          Text(hint, style: AppTextStyles.labelSm, maxLines: 2),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Order order;
  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.go(AppRoutes.merchantOrders),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        ),
        child: const Icon(Icons.receipt, color: AppColors.secondary, size: 20),
      ),
      title: Text('طلب ${order.orderNumber}', style: AppTextStyles.labelBold),
      subtitle: Text(
        order.items.isEmpty
            ? (order.buyer?.name ?? '—')
            : order.items.first.product.title,
        style: AppTextStyles.labelSm,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Formatters.price(order.totalAmount),
              style: AppTextStyles.labelBold),
          const SizedBox(height: 2),
          StatusPill(
            label: order.displayStatus,
            color: orderStatusStyle(order),
          ),
        ],
      ),
    );
  }
}
