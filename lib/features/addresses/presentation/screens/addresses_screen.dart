import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/entities/address.dart';
import '../providers/address_provider.dart';

/// عناوين الشحن — يغطّي المسارات الستة:
/// GET/POST /addresses، GET/PUT/DELETE /addresses/{id}،
/// PATCH /addresses/{id}/default
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressListProvider);

    return ClientScaffold(
      appBar: AppBar(title: const Text('عناوين الشحن')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('عنوان جديد'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(addressListProvider.notifier).refreshList(),
        child: addressesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary),
            ),
          ]),
          data: (addresses) {
            if (addresses.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('لا توجد عناوين محفوظة.')),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              itemCount: addresses.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceM),
              itemBuilder: (_, i) =>
                  _AddressCard(address: addresses[i]),
            );
          },
        ),
      ),
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Address? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddressForm(existing: existing),
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final Address address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addressListProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(address.title, style: AppTextStyles.title)),
              if (address.isDefault)
                const StatusPill(label: 'افتراضي', color: AppColors.success),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text('${address.recipientName} — ${address.phone}',
              style: AppTextStyles.bodySecondary),
          Text('${address.city}، ${address.addressLine}',
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              if (!address.isDefault)
                TextButton(
                  onPressed: () async {
                    final ok = await notifier.makeDefault(address.id);
                    if (context.mounted && !ok) {
                      AppSnackBar.showError(context, 'تعذّر تعيين العنوان.');
                    }
                  },
                  child: const Text('اجعله افتراضياً'),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'تعديل',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () =>
                    AddressesScreen._openForm(context, ref, existing: address),
              ),
              IconButton(
                tooltip: 'حذف',
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
                onPressed: () async {
                  final ok = await notifier.remove(address.id);
                  if (context.mounted && !ok) {
                    AppSnackBar.showError(context, 'تعذّر حذف العنوان.');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  final Address? existing;
  const _AddressForm({this.existing});

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _lineCtrl;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _nameCtrl = TextEditingController(text: a?.recipientName ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _cityCtrl = TextEditingController(text: a?.city ?? '');
    _lineCtrl = TextEditingController(text: a?.addressLine ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final address = Address(
      id: widget.existing?.id ?? 0,
      title: _titleCtrl.text.trim(),
      recipientName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      addressLine: _lineCtrl.text.trim(),
      isDefault: _isDefault,
    );

    final notifier = ref.read(addressListProvider.notifier);
    final ok = widget.existing == null
        ? await notifier.add(address)
        : await notifier.edit(widget.existing!.id, address);

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      AppSnackBar.showError(context, 'تعذّر حفظ العنوان.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'عنوان جديد' : 'تعديل العنوان',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              AppTextField(
                label: 'العنوان (مثال: المنزل)',
                controller: _titleCtrl,
                validator: Validators.required,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              AppTextField(
                label: 'اسم المستلم',
                controller: _nameCtrl,
                validator: Validators.required,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              AppTextField(
                label: 'رقم الهاتف',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: Validators.required,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              AppTextField(
                label: 'المدينة',
                controller: _cityCtrl,
                validator: Validators.required,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              AppTextField(
                label: 'تفاصيل العنوان',
                controller: _lineCtrl,
                validator: Validators.required,
              ),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('اجعله العنوان الافتراضي'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              PrimaryButton(
                label: 'حفظ',
                isLoading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: AppDimensions.spaceM),
            ],
          ),
        ),
      ),
    );
  }
}
