import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../providers/bid_provider.dart';

/// شاشة العرض المقبول — مبنية على `client_app/20_accepted_offer_contact.html`.
///
/// تُفتح بعد نجاح `PATCH /bids/{id}/accept`، وتعرض المورّد الفائز والسعر
/// المتفق عليه ومدخلاً للتواصل معه.
///
/// ⚠️ تعارض بين التصميم والـ API (لم أخترع له حلاً):
/// التصميم يعرض شعار الورشة وموقعها الجغرافي وأزرار «واتساب» و«اتصال
/// هاتفي» و«الخريطة GPS»، لكن الـ Backend لا يعيد في `bid.merchant`
/// سوى `{ id, name, avatar_url }` — بلا هاتف ولا عنوان ولا إحداثيات.
/// لذلك استُبدلت تلك الأزرار بزر «مراسلة المورّد» وهو مدعوم فعلياً
/// عبر POST /messages. تُضاف البقية فور توفير إسراء لتلك الحقول.
class AcceptedOfferScreen extends ConsumerWidget {
  final int tenderId;
  final int bidId;

  const AcceptedOfferScreen({
    super.key,
    required this.tenderId,
    required this.bidId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(tenderBidsProvider(tenderId));

    return ClientScaffold(
      appBar: AppBar(title: const Text('العرض المقبول')),
      body: bidsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.containerPadding),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (bids) {
          final matches = bids.where((b) => b.id == bidId);
          if (matches.isEmpty) {
            return const Center(child: Text('تعذّر العثور على هذا العرض.'));
          }
          final bid = matches.first;
          final merchant = bid.merchant;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.containerPadding,
              AppDimensions.sectionMargin,
              AppDimensions.containerPadding,
              120,
            ),
            children: [
              // ── رأس النجاح ──
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      size: 48, color: AppColors.primaryContainer),
                ),
              ),
              const SizedBox(height: AppDimensions.stackMd),
              Text('العرض المقبول',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineXl),
              const SizedBox(height: AppDimensions.stackSm),
              Text(
                'تم قبول عرض ${merchant?.name ?? 'المورّد'} بنجاح',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg
                    .copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppDimensions.sectionMargin),

              // ── بطاقة المورّد ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCard),
                  boxShadow: AppDimensions.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // الشريط المتدرّج العلوي.
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryContainer,
                            AppColors.primary,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.stackLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusInput),
                                  border: Border.all(
                                      color:
                                          AppColors.surfaceContainerHighest),
                                  image: merchant?.avatarUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              merchant!.avatarUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: merchant?.avatarUrl == null
                                    ? const Icon(Icons.storefront_outlined,
                                        size: 32, color: AppColors.outline)
                                    : null,
                              ),
                              const SizedBox(width: AppDimensions.cardGap),
                              Expanded(
                                child: Text(
                                  merchant?.name ?? 'المورّد',
                                  style: AppTextStyles.headlineMd,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.stackMd),

                          // السعر المتفق عليه.
                          Container(
                            padding:
                                const EdgeInsets.all(AppDimensions.stackMd),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusInput),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('السعر المتفق عليه',
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: AppColors.onSurfaceVariant)),
                                Text(
                                  bid.price.toStringAsFixed(2),
                                  style: AppTextStyles.headlineMd.copyWith(
                                      color: AppColors.primaryContainer),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.stackMd),

                          // ملاحظة إرشادية.
                          Container(
                            padding:
                                const EdgeInsets.all(AppDimensions.stackSm),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed
                                  .withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusInput),
                              border: Border.all(
                                  color: AppColors.secondaryFixed),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 20,
                                    color: AppColors.onSecondaryFixed),
                                const SizedBox(width: AppDimensions.stackSm),
                                Expanded(
                                  child: Text(
                                    'يرجى التواصل مع المورّد لترتيب موعد '
                                    'الاستلام.',
                                    style: AppTextStyles.bodySm.copyWith(
                                      color:
                                          AppColors.onSecondaryFixedVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.stackLg),

              // ── الإجراءات ──
              if (merchant != null)
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.chat(merchant.id)),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('مراسلة المورّد'),
                ),
              const SizedBox(height: AppDimensions.stackMd),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: const Text('العودة للرئيسية'),
              ),
            ],
          );
        },
      ),
    );
  }
}
