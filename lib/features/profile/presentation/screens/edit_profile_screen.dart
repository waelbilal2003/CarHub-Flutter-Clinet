import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// شاشة تعديل بيانات الملف الشخصي (الاسم، الهاتف، المدينة).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    // نملأ الحقول ببيانات المستخدم الحالية.
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(profileControllerProvider.notifier).updateProfile(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );

    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'تم حفظ التغييرات.');
      context.pop();
    } else {
      final err =
          ref.read(profileControllerProvider).error ?? 'تعذّر حفظ التغييرات.';
      AppSnackBar.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return ClientScaffold(
      appBar: AppBar(title: const Text('تعديل الملف')),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.containerPadding,
                AppDimensions.containerPadding,
                AppDimensions.containerPadding,
                120,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                AppTextField(
                  label: 'الاسم الكامل',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.name,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                AppTextField(
                  label: 'رقم الهاتف',
                  hint: '+49 ...',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  // الهاتف اختياري هنا؛ لا نضع validator إلزامياً.
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // الـ API لا يقبل حقل مدينة، لكنه يقبل تعديل البريد.
                AppTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'name@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                ),
                    const SizedBox(height: AppDimensions.spaceXL),
                    PrimaryButton(
                      label: 'حفظ التغييرات',
                      isLoading: isLoading,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
