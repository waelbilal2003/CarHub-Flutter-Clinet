import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/widgets/order_status_style.dart';
import '../providers/merchant_provider.dart';
import '../widgets/merchant_scaffold.dart';

/// الطلبات الواردة للتاجر — GET /merchant/orders + PATCH .../status.
///
/// مطابقة لـ 04_merchant_orders.html في: عنوان «الطلبات الواردة»،
/// أزرار تصفية بشكل حبّة، بطاقات بيضاء برأس فيه دائرة أيقونة المشتري
/// واسمه ورقم الطلب وشارة الحالة، ثم شريط رمادي بالعناصر والمجموع،
/// ثم أزرار الإجراء أسفل البطاقة.
///
/// الحالات مأخوذة من `App\Enums\OrderStatus` في الـ Backend مباشرة:
/// pending / processing / shipped / delivered / completed / canceled.
/// ⚠️ انتبه: الخادم يكتبها `canceled` بلام واحدة؛ أي قيمة أخرى يرفضها
/// `Rule::enum` بـ 422.
class MerchantOrdersScreen extends ConsumerStatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  ConsumerState<MerchantOrdersScreen> createState() =>
      _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends ConsumerState<MerchantOrdersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 300) {
        ref.read(merchantOrdersProvider.notifier).loadMore();
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
    final ordersAsync = ref.watch(merchantOrdersProvider);
    final filter = ref.watch(merchantOrdersFilterProvider);

    return MerchantScaffold(
      navIndex: 3,
      title: 'الطلبات الواردة',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterChips(
            selected: filter,
            onSelected: (value) =>
                ref.read(merchantOrdersFilterProvider.notifier).state = value,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(merchantOrdersProvider.notifier).refreshList(),
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _Message(
                  icon: Icons.cloud_off,
                  message: e.toString(),
                  actionLabel: 'إعادة المحاولة',
                  onAction: () =>
                      ref.read(merchantOrdersProvider.notifier).refreshList(),
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
      return _Message(
        icon: Icons.inbox_outlined,
        message: all.isEmpty
            ? 'لم تصلك أي طلبات بعد.'
            : 'لا طلبات بحالة «${filter!.label}» ضمن ما حُمّل.',
        actionLabel: all.isEmpty ? 'تحديث' : 'عرض الكل',
        onAction: () {
          if (all.isEmpty) {
            ref.read(merchantOrdersProvider.notifier).refreshList();
          } else {
            ref.read(merchantOrdersFilterProvider.notifier).state = null;
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
        120,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.cardGap),
      itemBuilder: (_, i) => _MerchantOrderCard(order: visible[i]),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = <(OrderStatus?, String)>[
      (null, 'الكل'),
      for (final status in OrderStatus.values) (status, status.label),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.containerPadding,
        AppDimensions.spaceS,
        AppDimensions.containerPadding,
        AppDimensions.spaceS,
      ),
      child: Row(
        children: [
          for (final (status, label) in options)
            Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spaceS),
              child: _Chip(
                label: label,
                isSelected: status == selected,
                onTap: () => onSelected(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelBold.copyWith(
            color: isSelected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _MerchantOrderCard extends ConsumerStatefulWidget {
  final Order order;
  const _MerchantOrderCard({required this.order});

  @override
  ConsumerState<_MerchantOrderCard> createState() => _MerchantOrderCardState();
}

class _MerchantOrderCardState extends ConsumerState<_MerchantOrderCard> {
  bool _isUpdating = false;

  Future<void> _update(OrderStatus status) async {
    setState(() => _isUpdating = true);
    final error = await ref
        .read(merchantOrdersProvider.notifier)
        .updateStatus(widget.order.id, status);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }
    AppSnackBar.showSuccess(context, 'تم تحديث حالة الطلب.');
  }

  /// الإجراءات المتاحة حسب الحالة الحالية — تسلسل يطابق ترتيب
  /// `App\Enums\OrderStatus` وأزرار التصميم («قبول» ← «جاهز للاستلام»).
  ///
  /// ملاحظة: الخادم لا يفرض أي انتقالات (يقبل أي قيمة من الـ enum في أي
  /// وقت)، فالتسلسل هنا قرار واجهة يمنع الأخطاء الشائعة لا قيد خادم.
  List<OrderStatus> get _nextStatuses {
    return switch (OrderStatus.fromValue(widget.order.status)) {
      OrderStatus.pending => [OrderStatus.processing, OrderStatus.canceled],
      OrderStatus.processing => [OrderStatus.shipped, OrderStatus.canceled],
      OrderStatus.shipped => [OrderStatus.delivered],
      OrderStatus.delivered => [OrderStatus.completed],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceContainer,
                backgroundImage: order.buyer?.avatarUrl != null
                    ? NetworkImage(order.buyer!.avatarUrl!)
                    : null,
                child: order.buyer?.avatarUrl == null
                    ? const Icon(Icons.person_outline,
                        color: AppColors.secondary)
                    : null,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.buyer?.name ?? 'مشترٍ',
                        style: AppTextStyles.labelBold),
                    Text('طلب رقم ${order.orderNumber}',
                        style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              StatusPill(
                label: order.displayStatus,
                color: orderStatusStyle(order),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          // الشريط الرمادي بالعناصر والمجموع كما في التصميم.
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceS),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('العناصر', style: AppTextStyles.labelSm),
                      Text(
                        order.items.isEmpty
                            ? '—'
                            : '${Formatters.itemCount(order.totalQuantity)}'
                                ' • ${order.items.first.product.title}'
                                '${order.items.length > 1 ? ' وغيرها' : ''}',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('المجموع', style: AppTextStyles.labelSm),
                    Text(
                      Formatters.price(order.totalAmount),
                      style: AppTextStyles.labelBold
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (order.shippingAddress != null) ...[
            const SizedBox(height: AppDimensions.spaceS),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(order.shippingAddress!,
                      style: AppTextStyles.labelSm),
                ),
              ],
            ),
          ],
          if (_nextStatuses.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceM),
            Row(
              children: [
                for (final status in _nextStatuses) ...[
                  Expanded(
                    child: status == OrderStatus.canceled
                        ? OutlinedButton(
                            onPressed:
                                _isUpdating ? null : () => _confirmCancel(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: const Text('رفض'),
                          )
                        : ElevatedButton(
                            onPressed:
                                _isUpdating ? null : () => _update(status),
                            child: Text(_actionLabel(status)),
                          ),
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// نصوص الأزرار من التصميم، لا مجرد اسم الحالة.
  static String _actionLabel(OrderStatus status) => switch (status) {
        OrderStatus.processing => 'قبول الطلب',
        OrderStatus.shipped => 'جاهز للاستلام',
        OrderStatus.delivered => 'تم التسليم',
        OrderStatus.completed => 'إتمام الطلب',
        _ => status.label,
      };

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Text(
          'سيتم تحويل حالة الطلب ${widget.order.orderNumber} إلى «ملغى». '
          'لا يمكن التراجع عن ذلك من التطبيق.',
          style: AppTextStyles.bodySm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض الطلب'),
          ),
        ],
      ),
    );

    if (confirmed == true) await _update(OrderStatus.canceled);
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
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
        const SizedBox(height: 80),
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
