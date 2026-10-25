import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import '../widgets/product_grid_card.dart';

/// شاشة السوق — GET /products (مصفّحة).
///
/// مطابقة لـ 07_marketplace.html في: الرأس الملتصق بخلفية فاتحة واسم
/// CarHub في الوسط، شريط بحث بزوايا 8، بانر متدرّج كحلي←أخضر بزوايا 16،
/// عنوان قسم مع «عرض الكل»، ثم شبكة عمودين بفجوة 16.
///
/// البحث يُنفَّذ **على الخادم** عبر `GET /products?search=` (لا محلياً)،
/// مع كتم كتابة 400ms حتى لا يُرسَل طلب لكل حرف.
///
/// اختلافان مقصودان عن التصميم:
///  1. شريط التصنيفات (المحرك/الفرامل/...) غير مرسوم بعد: المسار
///     `GET /categories` موجود ويقبل `GET /products?category_id=`، لكن
///     جدول التصنيفات فارغ في قاعدة البيانات الحالية — فرسم الشريط
///     الآن يعني أزراراً بلا تصنيفات. يُفعَّل فور تعبئة الجدول.
///  2. «الموقع الحالي» و«الإشعارات» في الرأس بلا مسار في الـ Backend،
///     فاستبدلناهما باسم المستخدم الحقيقي وبالسلة مع عدّاد حقيقي.
///
/// يقبل بحثاً وفلتر توافق مبدئيين (من بطاقة open_marketplace_search في
/// المساعد الذكي عبر [AppRoutes.marketplaceSearch])؛ يُطبَّقان مرة عند الفتح.
class MarketplaceScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? initialCarMake;
  final String? initialCarModel;
  final int? initialYear;

  const MarketplaceScreen({
    super.key,
    this.initialSearch,
    this.initialCarMake,
    this.initialCarModel,
    this.initialYear,
  });

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyInitialFilters();
    // تمرير لا نهائي: نطلب الصفحة التالية قبل بلوغ النهاية بـ 300 بكسل
    // حتى لا يرى المستخدم فراغاً أثناء الجلب.
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 300) {
        ref.read(productListProvider.notifier).loadMore();
      }
    });
  }

  /// عند الفتح من المساعد: نضبط البحث وفلتر السيارة. بلا معاملات (التنقّل
  /// العادي) لا نلمس الحالة الحالية.
  void _applyInitialFilters() {
    final hasSearch = widget.initialSearch != null;
    final make = widget.initialCarMake;
    final model = widget.initialCarModel;
    final hasCar =
        make != null && make.isNotEmpty && model != null && model.isNotEmpty;
    if (!hasSearch && !hasCar) return;

    _searchController.text = widget.initialSearch ?? '';
    // التعديل بعد أول إطار: لا يجوز تغيير مزوّد أثناء بناء الشجرة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(productSearchQueryProvider.notifier).state =
          widget.initialSearch ?? '';
      ref.read(productCarFilterProvider.notifier).state = hasCar
          ? CarFilter(make: make, model: model, year: widget.initialYear)
          : null;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final query = ref.watch(productSearchQueryProvider);

    return ClientScaffold(
      navIndex: 1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _MarketHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(productListProvider.notifier).refreshList(),
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _MarketMessage(
                    icon: Icons.cloud_off,
                    message: e.toString(),
                    actionLabel: 'إعادة المحاولة',
                    onAction: () =>
                        ref.read(productListProvider.notifier).refreshList(),
                  ),
                  data: (products) => _buildList(products, query),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Product> visible, String query) {
    // القائمة وصلت مفلترة من الخادم أصلاً — لا تصفية محلية هنا.
    final notifier = ref.read(productListProvider.notifier);

    return CustomScrollView(
      controller: _scrollController,
      // نُبقي التمرير ممكناً دائماً ليعمل السحب للتحديث حتى مع قائمة فارغة.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.containerPadding,
            AppDimensions.spaceM,
            AppDimensions.containerPadding,
            0,
          ),
          sliver: SliverList.list(
            children: [
              _SearchField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(productSearchQueryProvider.notifier)
                    .state = value,
              ),
              if (ref.watch(productCarFilterProvider) case final car?) ...[
                const SizedBox(height: AppDimensions.spaceS),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InputChip(
                    avatar: const Icon(Icons.directions_car_outlined, size: 18),
                    label: Text('متوافق مع: ${car.label}'),
                    onDeleted: () =>
                        ref.read(productCarFilterProvider.notifier).state = null,
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.spaceL),
              const _PromoBanner(),
              const SizedBox(height: AppDimensions.spaceL),
              Row(
                children: [
                  const Text('أحدث القطع', style: AppTextStyles.headlineMd),
                  const Spacer(),
                  Text(
                    // عدد حقيقي مما جُلب فعلاً، لا رقم ثابت.
                    '${visible.length} قطعة',
                    style: AppTextStyles.labelSm,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),
            ],
          ),
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _MarketMessage(
              icon: Icons.inventory_2_outlined,
              message: query.trim().isEmpty
                  ? 'لا توجد منتجات معروضة في السوق بعد.'
                  : 'لا نتائج مطابقة لـ «${query.trim()}».',
              actionLabel: query.trim().isEmpty ? 'تحديث' : 'مسح البحث',
              onAction: () {
                if (query.trim().isEmpty) {
                  notifier.refreshList();
                } else {
                  _searchController.clear();
                  ref.read(productSearchQueryProvider.notifier).state = '';
                }
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.containerPadding,
            ),
            sliver: SliverGrid.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.cardGap,
                mainAxisSpacing: AppDimensions.cardGap,
                // البطاقة أطول من عرضها: صورة مربّعة + شارة + سطران
                // عنوان + المتجر + السعر.
                childAspectRatio: 0.58,
              ),
              itemCount: visible.length,
              itemBuilder: (_, i) => ProductGridCard(
                product: visible[i],
                onTap: () =>
                    context.push(AppRoutes.productDetails(visible[i].id)),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            // مساحة سفلية تكفي شريط التنقّل العائم وزر المساعد.
            padding: const EdgeInsets.fromLTRB(0, AppDimensions.spaceL, 0, 130),
            // البحث يعود مصفّحاً أيضاً، فتحميل المزيد يعمل مع النتائج.
            child: notifier.hasMore
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// رأس السوق — خلفية فاتحة وظل خفيف كما في التصميم، مع اسم المستخدم
/// على اليمين، CarHub في الوسط، والسلة مع عدّادها على اليسار.
class _MarketHeader extends ConsumerWidget {
  const _MarketHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final count = ref.watch(cartItemCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.containerPadding,
        vertical: AppDimensions.spaceS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(color: Color(0x0D0A192F), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin_circle_outlined,
              color: AppColors.primary),
          const SizedBox(width: AppDimensions.spaceS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تسوّق باسم', style: AppTextStyles.labelSm),
              Text(
                user?.name ?? '—',
                style: AppTextStyles.labelBold,
              ),
            ],
          ),
          const Spacer(),
          Text(
            'CarHub',
            style: AppTextStyles.headlineLgMobile
                .copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          _CartButton(count: count),
        ],
      ),
    );
  }
}

/// زر السلة مع شارة عدد القطع (العدد حقيقي من GET /cart).
class _CartButton extends StatelessWidget {
  final int count;
  const _CartButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'السلة',
      onPressed: () => context.push(AppRoutes.cart),
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.primaryContainer,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined,
            color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

/// شريط البحث — زوايا 8 وحدّ رفيع كما في التصميم.
/// البحث محلي داخل الصفحات المحمّلة (لا معامل بحث في الـ API).
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث عن قطع الغيار...',
        prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
          borderSide: const BorderSide(color: AppColors.primaryContainer),
        ),
      ),
    );
  }
}

/// البانر المتدرّج أعلى الشبكة — نفس شكل التصميم حرفياً:
/// تدرّج أفقي من الكحلي `#0d1c32` إلى الأخضر `#006d37`، زوايا 16،
/// حشوة 16، ودائرتان شفافتان للعمق.
///
/// ⚠️ اختلاف في المحتوى: بانر التصميم إعلان «خصم 15% على الفرامل»،
/// ولا يوجد في الـ API أي مسار للعروض الترويجية — فأي نسبة خصم نكتبها
/// ستكون بيانات مخترعة. وضعنا مكانها إجراءً حقيقياً في التطبيق
/// (إنشاء مناقصة عند عدم توفّر القطعة) بنفس المعالجة البصرية.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.createTender),
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          gradient: const LinearGradient(
            colors: [AppColors.onSecondaryFixed, AppColors.primary],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0A192F),
              offset: Offset(0, 4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لم تجد القطعة؟',
                    style: AppTextStyles.headlineMd
                        .copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    'أنشئ مناقصة ودع الموردين يتنافسون على سعرك',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel_outlined,
                  color: AppColors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة فارغة/خطأ موحّدة داخل السوق.
class _MarketMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MarketMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
