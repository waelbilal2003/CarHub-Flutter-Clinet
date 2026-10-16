import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_style.dart';

/// شاشة «طلباتي» — GET /orders (مصفّحة).
///
/// مطابقة لـ 13_my_orders.html في: رأس بتدرّج كحلي واسم CarHub أخضر،
/// عنوان «طلباتي»، شريط تبويبات أفقي بخط سفلي للمحدَّد، ثم بطاقات
/// بيضاء بزوايا 12 وحدّ رفيع، كل بطاقة: اسم المتجر ورقم الطلب، شارة
/// الحالة الملوّنة، التاريخ، وفي الأسفل عدد العناصر والمبلغ بالأخضر
/// مع أزرار الإجراءات.
///
/// ⚠️ ثلاث فجوات مؤكّدة (بعد مراجعة routes/api.php نفسه، لا ملف Postman)
/// تظهر هنا كواجهة جاهزة بلا وظيفة:
///  • «عرض الفاتورة» — لا GET /orders/{id}/invoice.
///  • «طلب إرجاع» — لا أي مسار للإرجاع.
///  • «إلغاء الطلب» — لا مسار إلغاء للعميل (تحديث الحالة للتاجر فقط).
/// كل زر منها يشرح عند الضغط أنه بانتظار مسار من الـ Backend.
///
/// ⚠️ وفجوة رابعة: التبويبات تصفّي **محلياً** لأن
/// `OrderController::index` لا يقرأ أي معامل `status` — فقد يبدو تبويب
/// فارغاً وطلباته في صفحة لم تُحمَّل بعد.
///
/// ملاحظة: `GET /orders/{id}` موجود فعلاً، لكن أسطر الطلب (`items[]`)
/// تعود أصلاً داخل استجابة القائمة، فنعرض التفاصيل بلا نداء إضافي.
class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 300) {
        ref.read(myOrdersProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final filter = ref.watch(myOrdersFilterProvider);

    return ClientScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.onSecondaryFixed, AppColors.onTertiaryFixed],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: AppColors.primaryFixedDim),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        centerTitle: true,
        title: Text(
          'طلباتي',
          style: AppTextStyles.headlineLgMobile
              .copyWith(color: AppColors.primaryFixedDim),
        ),
        actions: [
          IconButton(
            tooltip: 'السلة',
            icon: const Icon(Icons.shopping_cart_outlined,
                color: AppColors.primaryFixedDim),
            onPressed: () => context.push(AppRoutes.cart),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusTabs(
            selected: filter,
            onSelected: (value) =>
                ref.read(myOrdersFilterProvider.notifier).state = value,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(myOrdersProvider.notifier).refreshList(),
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _OrdersMessage(
                  icon: Icons.cloud_off,
                  message: e.toString(),
                  actionLabel: 'إعادة المحاولة',
                  onAction: () =>
                      ref.read(myOrdersProvider.notifier).refreshList(),
                ),
                data: (orders) => _buildList(orders, filter),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Order> all, OrderStatus? filter) {
    final visible = filter == null
        ? all
        : all.where((o) => o.status == filter.value).toList();

    if (visible.isEmpty) {
      return _OrdersMessage(
        icon: Icons.receipt_long_outlined,
        message: all.isEmpty
            ? 'لم تنفّذ أي طلب بعد. تصفّح السوق وابدأ أول طلب لك.'
            : 'لا توجد طلبات بحالة «${filter!.label}» ضمن ما حُمّل.',
        actionLabel: all.isEmpty ? 'تصفّح السوق' : 'عرض كل الطلبات',
        onAction: () {
          if (all.isEmpty) {
            context.go(AppRoutes.marketplace);
          } else {
            ref.read(myOrdersFilterProvider.notifier).state = null;
          }
        },
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.containerPadding,
        AppDimensions.spaceM,
        AppDimensions.containerPadding,
        130,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.cardGap),
      itemBuilder: (_, i) => _OrderCard(order: visible[i]),
    );
  }
}

/// شريط التبويبات الأفقي — المحدَّد بخط سفلي أخضر كما في التصميم.
class _StatusTabs extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  const _StatusTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // null = «الكل»، ثم حالات الطلب بالترتيب المنطقي.
    final tabs = <(OrderStatus?, String)>[
      (null, 'الكل'),
      for (final status in OrderStatus.values) (status, status.label),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.containerPadding,
        ),
        child: Row(
          children: [
            for (final (status, label) in tabs)
              _Tab(
                label: label,
                isSelected: status == selected,
                onTap: () => onSelected(status),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: isSelected
                  ? AppColors.primaryContainer
                  : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelBold.copyWith(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// بطاقة طلب واحد.
class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  void _pendingEndpoint(BuildContext context, String feature, String hint) {
    AppSnackBar.showError(
      context,
      '$feature غير متاح بعد — بانتظار مسار من الـ Backend ($hint).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = orderStatusStyle(order);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.merchant?.name ?? 'متجر غير معروف',
                      style: AppTextStyles.labelBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('طلب ${order.orderNumber}',
                        style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              StatusPill(label: order.displayStatus, color: style),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(Formatters.date(order.createdAt),
                  style: AppTextStyles.bodySm),
            ],
          ),
          if (order.shippingAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    // الخادم يعيد العنوان نصاً جاهزاً للعرض.
                    order.shippingAddress!,
                    style: AppTextStyles.labelSm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const Divider(color: AppColors.surfaceVariant, height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Formatters.itemCount(order.totalQuantity),
                      style: AppTextStyles.bodySm),
                  Text(
                    Formatters.price(order.totalAmount),
                    style: AppTextStyles.headlineMd
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const Spacer(),
              // تفاصيل الأسطر موجودة داخل الاستجابة نفسها (items[])،
              // فنعرضها في ورقة سفلية بلا نداء إضافي — وهذا يعوّض
              // غياب GET /orders/{id}.
              TextButton(
                onPressed: () => _showItems(context),
                child: const Text('التفاصيل'),
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceVariant, height: 12),
          // أزرار الفجوات — واجهة جاهزة، وظيفتها بانتظار إسراء.
          Wrap(
            spacing: AppDimensions.spaceS,
            children: [
              _GapAction(
                icon: Icons.receipt_long_outlined,
                label: 'عرض الفاتورة',
                onTap: () => _pendingEndpoint(
                    context, 'الفاتورة', 'GET /orders/{id}/invoice'),
              ),
              _GapAction(
                icon: Icons.assignment_return_outlined,
                label: 'طلب إرجاع',
                onTap: () => _pendingEndpoint(
                    context, 'طلب الإرجاع', 'POST /orders/{id}/return'),
              ),
              if (order.status == OrderStatus.pending.value)
                _GapAction(
                  icon: Icons.cancel_outlined,
                  label: 'إلغاء الطلب',
                  isDestructive: true,
                  onTap: () => _pendingEndpoint(
                      context, 'إلغاء الطلب', 'مسار إلغاء للعميل'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showItems(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppDimensions.containerPadding),
          children: [
            Text('طلب ${order.orderNumber}',
                style: AppTextStyles.headlineMd),
            const SizedBox(height: AppDimensions.spaceS),
            if (order.notes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                child: Text('ملاحظاتك: ${order.notes}',
                    style: AppTextStyles.bodySm),
              ),
            const Divider(color: AppColors.surfaceVariant),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.title,
                              style: AppTextStyles.bodyMd),
                          Text(
                            '${item.quantity} × '
                            '${Formatters.price(item.unitPrice)}',
                            style: AppTextStyles.labelSm,
                          ),
                        ],
                      ),
                    ),
                    Text(Formatters.price(item.subtotal),
                        style: AppTextStyles.labelBold),
                  ],
                ),
              ),
            const Divider(color: AppColors.surfaceVariant),
            Row(
              children: [
                const Text('الإجمالي', style: AppTextStyles.labelBold),
                const Spacer(),
                Text(
                  Formatters.price(order.totalAmount),
                  style: AppTextStyles.headlineMd
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// زر إجراء ينتظر مساراً في الـ Backend — يظهر بشكله الطبيعي ويشرح
/// سبب عدم عمله عند الضغط، بدل أن يكون مخفياً أو صامتاً.
class _GapAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _GapAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: color),
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppTextStyles.labelBold.copyWith(color: color)),
    );
  }
}

class _OrdersMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _OrdersMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 56, color: AppColors.textHint),
        const SizedBox(height: AppDimensions.spaceM),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXL),
          child: Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.bodySm),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Center(child: TextButton(onPressed: onAction, child: Text(actionLabel))),
      ],
    );
  }
}
