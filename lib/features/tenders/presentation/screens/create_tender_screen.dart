import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/tender_provider.dart';

/// إنشاء مناقصة — POST /tenders (multipart).
class CreateTenderScreen extends ConsumerStatefulWidget {
  const CreateTenderScreen({super.key});

  @override
  ConsumerState<CreateTenderScreen> createState() => _CreateTenderScreenState();
}

class _CreateTenderScreenState extends ConsumerState<CreateTenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  DateTime _deadline = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      // نثبّت الوقت على نهاية اليوم كما في مثال الـ API (23:59:59).
      setState(() => _deadline =
          DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final tender = await ref.read(createTenderProvider.notifier).create(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          budget: double.tryParse(_budgetCtrl.text.trim()) ?? 0,
          deadline: _deadline,
        );

    if (!mounted) return;
    if (tender != null) {
      AppSnackBar.showSuccess(context, 'تم إنشاء المناقصة بنجاح.');
      context.pop();
    } else {
      final err = ref.read(createTenderProvider).error ?? 'تعذّر إنشاء المناقصة.';
      AppSnackBar.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createTenderProvider).isLoading;

    return ClientScaffold(
      appBar: AppBar(title: const Text('إنشاء مناقصة')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'عنوان المناقصة',
                  hint: 'مثال: مطلوب إسمنت',
                  controller: _titleCtrl,
                  prefixIcon: Icons.title,
                  validator: Validators.required,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                AppTextField(
                  label: 'الوصف',
                  hint: 'اشرح تفاصيل ما تحتاجه',
                  controller: _descCtrl,
                  prefixIcon: Icons.description_outlined,
                  validator: Validators.required,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                AppTextField(
                  label: 'الميزانية',
                  hint: '50000',
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل الميزانية';
                    if (double.tryParse(v.trim()) == null) {
                      return 'أدخل رقماً صحيحاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // الموعد النهائي — يُرسل بصيغة "yyyy-MM-dd HH:mm:ss".
                InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 20, color: AppColors.textHint),
                        const SizedBox(width: AppDimensions.spaceM),
                        Text(
                          'الموعد النهائي: '
                          '${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}'
                          '-${_deadline.day.toString().padLeft(2, '0')}',
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_outlined, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceXL),
                PrimaryButton(
                  label: 'نشر المناقصة',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
