import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../providers/auth_form_providers.dart';
import '../widgets/password_hint.dart';

/// إنشاء حساب — مطابق لـ `client_app/03_register.html`.
///
/// السلوك (مستقل تماماً عن شاشة تسجيل الدخول):
///  • حالته من [registerFormProvider] وحده — زر الدخول لا يتأثر به
///    ولا تظهر أخطاؤه على حقول شاشة الدخول.
///  • Enter ينتقل عبر الحقول الخمسة بالترتيب ثم يُرسل من الأخير.
///  • خطأ الخادم على حقل يختفي فور تعديل ذلك الحقل.
///
/// الربط: POST /auth/register → data.token + data.user.
/// لا يوجد تحقق بريد ولا OTP — الحساب يُفعّل مباشرة ويدخل المستخدم فوراً.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _emailFocus,
      _phoneFocus,
      _passwordFocus,
      _confirmFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // الـ API يتطلب password_confirmation و type.
    // 'client' دائماً: هذا التطبيق للعميل وحده، ولا يُنشئ منه أي دور آخر.
    await ref.read(registerFormProvider.notifier).submit(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          passwordConfirmation: _confirmCtrl.text,
          phone: _phoneCtrl.text.trim(),
          type: 'client',
        );
    // النجاح: تُفتح الجلسة وينقل الراوتر للرئيسية مباشرة.
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(registerFormProvider);
    final notifier = ref.read(registerFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.containerPadding,
              vertical: AppDimensions.sectionMargin,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.stackLg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCard),
                  border:
                      Border.all(color: AppColors.surfaceContainerHighest),
                  boxShadow: AppDimensions.cardShadow,
                ),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineXl
                              .copyWith(color: AppColors.primaryContainer),
                        ),
                        const SizedBox(height: AppDimensions.stackSm),
                        Text('إنشاء حساب جديد',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineMd),
                        const SizedBox(height: AppDimensions.stackSm),
                        Text(
                          'انضم إلى منصة قطع الغيار والمزادات الرائدة',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm,
                        ),
                        const SizedBox(height: AppDimensions.stackLg),

                        FormErrorBanner(message: form.error),

                        TextFormField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: Validators.name,
                          forceErrorText: form.fieldErrors['name'],
                          onChanged: (_) => notifier.clearFieldError('name'),
                          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                          decoration:
                              const InputDecoration(labelText: 'الاسم'),
                        ),
                        const SizedBox(height: AppDimensions.stackMd),

                        TextFormField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                          forceErrorText: form.fieldErrors['email'],
                          onChanged: (_) => notifier.clearFieldError('email'),
                          onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                          // البريد لاتيني دائماً — نثبّت اتجاهه ونصغّر
                          // مقاسه قليلاً ليظهر كاملاً مهما طال.
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: AppTextStyles.bodyMd
                              .copyWith(fontSize: 15, height: 1.4),
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            hintText: 'name@example.com',
                          ),
                        ),
                        const SizedBox(height: AppDimensions.stackMd),

                        TextFormField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.telephoneNumber
                          ],
                          forceErrorText: form.fieldErrors['phone'],
                          onChanged: (_) => notifier.clearFieldError('phone'),
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                          decoration:
                              const InputDecoration(labelText: 'رقم الهاتف'),
                        ),
                        const SizedBox(height: AppDimensions.stackMd),

                        TextFormField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: Validators.newPassword,
                          forceErrorText: form.fieldErrors['password'],
                          // نعيد البناء مع كل حرف ليتحدّث المؤشّر أدناه.
                          onChanged: (_) {
                            notifier.clearFieldError('password');
                            setState(() {});
                          },
                          onFieldSubmitted: (_) =>
                              _confirmFocus.requestFocus(),
                          decoration: InputDecoration(
                            // العنوان اسم الحقل فقط؛ الشرط انتقل إلى
                            // المؤشّر الحيّ أسفله.
                            labelText: 'كلمة المرور',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        PasswordHint(value: _passwordCtrl.text),
                        const SizedBox(height: AppDimensions.stackMd),

                        TextFormField(
                          controller: _confirmCtrl,
                          focusNode: _confirmFocus,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          validator: (v) => Validators.confirmPassword(
                              v, _passwordCtrl.text),
                          onChanged: (_) => setState(() {}),
                          // Enter في الحقل الأخير يُنشئ الحساب.
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                              labelText: 'تأكيد كلمة المرور'),
                        ),
                        _ConfirmHint(
                          password: _passwordCtrl.text,
                          confirmation: _confirmCtrl.text,
                        ),
                        const SizedBox(height: AppDimensions.stackLg),

                        // زر أخضر متدرّج — يعكس حالة هذا النموذج وحده.
                        _GradientButton(
                          label: 'إنشاء الحساب',
                          isLoading: form.isSubmitting,
                          onPressed: _submit,
                        ),

                        const SizedBox(height: AppDimensions.stackLg),
                        const Divider(),
                        const SizedBox(height: AppDimensions.stackSm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('لديك حساب بالفعل؟',
                                style: AppTextStyles.bodySm),
                            TextButton(
                              onPressed: form.isSubmitting
                                  ? null
                                  : () => context.pop(),
                              child: const Text('تسجيل الدخول'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// مؤشّر تطابق كلمتَي المرور — يظهر فقط بعد أن يبدأ المستخدم كتابة
/// التأكيد، فلا يلومه على حقل لم يملأه بعد.
class _ConfirmHint extends StatelessWidget {
  final String password;
  final String confirmation;

  const _ConfirmHint({required this.password, required this.confirmation});

  @override
  Widget build(BuildContext context) {
    if (confirmation.isEmpty) return const SizedBox.shrink();

    final matches = confirmation == password;
    final color = matches ? AppColors.primaryContainer : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.spaceXS,
        right: AppDimensions.spaceXS,
      ),
      child: Row(
        children: [
          Icon(
            matches ? Icons.check_circle_outline : Icons.error_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              matches ? 'الكلمتان متطابقتان.' : 'الكلمتان غير متطابقتين.',
              style: AppTextStyles.labelSm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر بتدرّج أفقي من #00B761 إلى #009E53 مع ظل أخضر — كما في التصميم.
class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, Color(0xFF009E53)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  const SizedBox(width: AppDimensions.stackSm),
                  const Icon(Icons.arrow_back, size: 18),
                ],
              ),
      ),
    );
  }
}
