import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../providers/auth_form_providers.dart';

/// تسجيل الدخول — مطابق لـ `client_app/02_login.html`.
///
/// السلوك (مستقل تماماً عن شاشة إنشاء الحساب):
///  • حالته من [loginFormProvider] وحده، فلا يتسرّب خطأ من شاشة لأخرى.
///  • Enter ينتقل للحقل التالي، وفي الأخير يُرسل النموذج.
///  • خطأ الخادم على حقل يختفي فور تعديل ذلك الحقل.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(loginFormProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    // النجاح: يفتح الجلسة فينقل الراوتر للرئيسية.
    // الفشل: الخطأ يظهر في الشريط وتحت الحقول ويبقى حتى يصحّحه المستخدم.
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: Stack(
        children: [
          // القبة الداكنة العلوية.
          Container(
            height: 397,
            decoration: const BoxDecoration(
              color: AppColors.inverseSurface,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.containerPadding,
                vertical: AppDimensions.sectionMargin,
              ),
              child: AutofillGroup(
                child: Column(
                  children: [
                    // ترويسة العلامة فوق القبة الداكنة.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car,
                            size: 32, color: AppColors.primaryFixed),
                        const SizedBox(width: AppDimensions.stackSm),
                        Text(
                          AppConstants.appName,
                          style: AppTextStyles.headlineXl
                              .copyWith(color: AppColors.primaryFixed),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.stackSm),
                    Text(
                      'سوق قطع الغيار والمزادات الأسرع نمواً',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg
                          .copyWith(color: AppColors.onInverseSurface),
                    ),
                    const SizedBox(height: AppDimensions.stackLg),

                    // بطاقة تسجيل الدخول.
                    //
                    // الحشوة 24 لا 32: الحشوة الأكبر كانت تقضم من عرض
                    // الحقول فيُقتطع البريد الطويل. الآن الحقول بنفس عرض
                    // حقول شاشة إنشاء الحساب تماماً.
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.stackLg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.surfaceContainerHighest),
                        boxShadow: AppDimensions.cardShadowStrong,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text('مرحباً بك مجدداً',
                                style: AppTextStyles.headlineLg),
                            const SizedBox(height: 4),
                            Text(
                              'قم بتسجيل الدخول للمتابعة إلى حسابك',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySm,
                            ),
                            const SizedBox(
                                height: AppDimensions.sectionMargin),

                            FormErrorBanner(message: form.error),

                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: Validators.email,
                              forceErrorText: form.fieldErrors['email'],
                              // الخطأ يختفي بمجرّد تعديل الحقل.
                              onChanged: (_) =>
                                  notifier.clearFieldError('email'),
                              // Enter ينقل للحقل التالي.
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              // البريد يُكتب لاتينياً دائماً، فنثبّت
                              // اتجاهه LTR حتى لا ينقلب داخل واجهة عربية.
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              // مقاس أصغر قليلاً من body-md مخصّص للبريد
                              // وحده: البريد أطول ما يُكتب في التطبيق
                              // (27 محرفاً فأكثر)، وهذا يُظهره كاملاً بدل
                              // اقتطاعه عند «@».
                              style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 15,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                // بلا أيقونة بادئة: كانت تقضم 48 بكسل من
                                // عرض الحقل، والنص «البريد الإلكتروني»
                                // يكفي وحده للدلالة.
                                labelText: 'البريد الإلكتروني',
                                hintText: 'name@example.com',
                              ),
                            ),
                            const SizedBox(height: AppDimensions.stackMd),

                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              // الحضور فقط: لا نفرض حداً أدنى عند الدخول،
                              // فالمستخدم يُدخل كلمة قائمة لا ينشئ جديدة.
                              validator: Validators.loginPassword,
                              forceErrorText: form.fieldErrors['password'],
                              onChanged: (_) =>
                                  notifier.clearFieldError('password'),
                              // Enter في الحقل الأخير يُرسل النموذج.
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
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
                            const SizedBox(height: AppDimensions.stackLg),

                            // الزر الأساسي — يعكس حالة هذا النموذج وحده.
                            ElevatedButton(
                              onPressed: form.isSubmitting ? null : _submit,
                              child: form.isSubmitting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('تسجيل الدخول'),
                                        SizedBox(
                                            width: AppDimensions.stackSm),
                                        Icon(Icons.arrow_back, size: 18),
                                      ],
                                    ),
                            ),

                            const SizedBox(
                                height: AppDimensions.sectionMargin),
                            // فاصل «ليس لديك حساب؟»
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.stackMd),
                                  child: Text('ليس لديك حساب؟',
                                      style: AppTextStyles.bodySm),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.stackMd),

                            // زر ثانوي — يفتح شاشة مستقلة بحالتها الخاصة.
                            OutlinedButton(
                              onPressed: form.isSubmitting
                                  ? null
                                  : () => context.push(AppRoutes.register),
                              child: const Text('إنشاء حساب جديد'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.sectionMargin),
                    Text(
                      'بتسجيل الدخول، أنت توافق على الشروط والأحكام '
                      'وسياسة الخصوصية',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm,
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
