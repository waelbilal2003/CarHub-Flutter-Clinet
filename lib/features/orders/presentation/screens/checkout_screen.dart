import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/presentation/providers/address_provider.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/order_provider.dart';

/// شاشة تأكيد الطلب — POST /checkout بجسم { address_id, notes }.
///
/// مطابقة لـ 11_checkout_confirm.html في: رأس بتدرّج كحلي، قسم «تفاصيل
/// التوصيل» ببطاقة صفوف مفصولة، قسم «ملخص الطلب» بأسطر المنتجات
/// والمجموع بالأخضر، لافتة «الدفع والاستلام مع التاجر»، وزر تأكيد
/// نهائي بشكل حبّة أسفل الشاشة.
///
/// ملاحظة على العنوان: الـ API يحتاج `address_id`، فنقرأ عناوين
/// المستخدم من GET /addresses (المرحلة 2) ونختار الافتراضي تلقائياً،
/// مع إمكانية تغييره — هذا يقابل زر «تعديل» في التصميم.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _selectedAddressId;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// العنوان المختار: ما اختاره المستخدم، وإلا الافتراضي، وإلا الأول.
  Address? _resolveAddress(List<Address> addresses) {
    if (addresses.isEmpty) return null;
    if (_selectedAddressId != null) {
      for (final a in addresses) {
        if (a.id == _selectedAddressId) return a;
      }
    }
    for (final a in addresses) {
      if (a.isDefault) return a;
    }
    return addresses.first;
  }

  Future<void> _confirm(Address address) async {
    final orders = await ref.read(checkoutProvider.notifier).submit(
          addressId: address.id,
          notes: _notesController.text,
        );
    if (!mounted) return;

    if (orders == null) {
      final error = ref.read(checkoutProvider).error;
      AppSnackBar.showError(context, error ?? 'تعذّر إتمام الطلب.');
      return;
    }

    // نمرّر الطلبات الناتجة (قد تكون عدة، طلب لكل تاجر) لشاشة النجاح.
    ref.read(lastCheckoutOrdersProvider.notifier).state = orders;
    context.go(AppRoutes.orderSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressListProvider);
    final checkoutState = ref.watch(checkoutProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
          icon: const Icon(Icons.arrow_forward, color: AppColors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.cart),
        ),
        centerTitle: true,
        title: Text(
          'تأكيد الطلب',
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.white),
        ),
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(message: e.toString()),
        data: (cart) {
          if (cart.isEmpty) {
            return const _Message(
              message: 'سلتك فارغة — أضف قطعاً قبل إتمام الطلب.',
            );
          }
          return addressesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(message: e.toString()),
            data: (addresses) {
              final address = _resolveAddress(addresses);
              return _Body(
                cart: cart,
                addresses: addresses,
                selected: address,
                notesController: _notesController,
                onAddressChanged: (id) =>
                    setState(() => _selectedAddressId = id),
              );
            },
          );
        },
      ),
      bottomNavigationBar: cartAsync.maybeWhen(
        data: (cart) {
          if (cart.isEmpty) return null;
          final address = _resolveAddress(addressesAsync.valueOrNull ?? const []);
          return _ConfirmBar(
            isLoading: checkoutState.isLoading,
            // بلا عنوان لا يمكن إرسال address_id، فنعطّل الزر ونوجّه
            // المستخدم لإضافة عنوان بدل إرسال طلب سيُرفض.
            onConfirm: address == null ? null : () => _confirm(address),
            missingAddress: address == null,
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Cart cart;
  final List<Address> addresses;
  final Address? selected;
  final TextEditingController notesController;
  final ValueChanged<int> onAddressChanged;

  const _Body({
    required this.cart,
    required this.addresses,
    required this.selected,
    required this.notesController,
    required this.onAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.containerPadding,
        AppDimensions.spaceL,
        AppDimensions.containerPadding,
        140,
      ),
      children: [
        _SectionHeader(
          title: 'تفاصيل التوصيل',
          action: addresses.length > 1
              ? TextButton.icon(
                  onPressed: () => _pickAddress(context),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تغيير'),
                )
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceS),
        if (selected == null)
          const _Card(
            child: Text(
              'لا يوجد عنوان شحن محفوظ. أضف عنواناً من «حسابي ← عناويني» '
              'قبل إتمام الطلب.',
              style: AppTextStyles.bodySm,
            ),
          )
        else
          _Card(
            child: Column(
              children: [
                _AddressRow(
                  icon: Icons.person_outline,
                  label: 'الاسم',
                  value: selected!.recipientName,
                ),
                const _RowDivider(),
                _AddressRow(
                  icon: Icons.phone_iphone,
                  label: 'رقم الجوال',
                  value: selected!.phone,
                  ltr: true,
                ),
                const _RowDivider(),
                _AddressRow(
                  icon: Icons.location_on_outlined,
                  label: 'العنوان',
                  value: '${selected!.city}، ${selected!.addressLine}',
                ),
              ],
            ),
          ),

        const SizedBox(height: AppDimensions.spaceXL),
        const _SectionHeader(title: 'ملخص الطلب'),
        const SizedBox(height: AppDimensions.spaceS),
        _Card(
          child: Column(
            children: [
              for (final item in cart.items)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.spaceS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.title,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.onSurface)),
                            Text('الكمية: ${item.quantity}',
                                style: AppTextStyles.labelSm),
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
                  const Text('المجموع', style: AppTextStyles.headlineMd),
                  const Spacer(),
                  Text(
                    Formatters.price(cart.displayTotal),
                    style: AppTextStyles.headlineMd
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.spaceXL),
        const _SectionHeader(title: 'ملاحظات للتاجر'),
        const SizedBox(height: AppDimensions.spaceS),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'مثال: الرجاء التوصيل في الصباح (اختياري)',
          ),
        ),

        const SizedBox(height: AppDimensions.spaceL),
        // لافتة المعلومات كما في التصميم.
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
              SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Text(
                  'الدفع والاستلام يتم مباشرة مع التاجر. إذا احتوت سلتك '
                  'قطعاً من أكثر من متجر فسيُقسَّم طلبك تلقائياً إلى طلب '
                  'مستقل لكل متجر.',
                  style: AppTextStyles.bodySm,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickAddress(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppDimensions.containerPadding),
          children: [
            const Text('اختر عنوان التوصيل',
                style: AppTextStyles.headlineMd),
            const SizedBox(height: AppDimensions.spaceM),
            for (final address in addresses)
              ListTile(
                onTap: () {
                  onAddressChanged(address.id);
                  Navigator.of(sheetContext).pop();
                },
                leading: Icon(
                  address.id == selected?.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: address.id == selected?.id
                      ? AppColors.primaryContainer
                      : AppColors.outline,
                ),
                title: Text(address.title, style: AppTextStyles.labelBold),
                subtitle: Text(
                  '${address.recipientName} — ${address.city}، '
                  '${address.addressLine}',
                  style: AppTextStyles.labelSm,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.headlineMd),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: child,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.outlineVariant, height: 20);
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ltr;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.outline, size: 20),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSm),
              Text(
                value,
                style: AppTextStyles.bodyMd,
                textDirection: ltr ? TextDirection.ltr : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// الشريط السفلي الثابت لزر التأكيد النهائي.
class _ConfirmBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onConfirm;
  final bool missingAddress;

  const _ConfirmBar({
    required this.isLoading,
    required this.onConfirm,
    required this.missingAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.containerPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: AppDimensions.bottomBarShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (missingAddress) ...[
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.addresses),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('أضف عنوان شحن أولاً'),
              ),
              const SizedBox(height: AppDimensions.spaceS),
            ],
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onConfirm,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('تأكيد الطلب النهائي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String message;
  const _Message({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.spaceM),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.bodySm),
            const SizedBox(height: AppDimensions.spaceM),
            TextButton(
              onPressed: () => context.go(AppRoutes.marketplace),
              child: const Text('العودة للسوق'),
            ),
          ],
        ),
      ),
    );
  }
}
