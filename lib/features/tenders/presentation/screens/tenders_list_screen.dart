import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/entities/tender.dart';
import '../providers/tender_provider.dart';

/// قائمة المناقصات — GET /tenders (مصفّحة).
class TendersListScreen extends ConsumerWidget {
  const TendersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tendersAsync = ref.watch(tenderListProvider);

    return ClientScaffold(
      navIndex: 2,
      appBar: AppBar(
        title: const Text('المناقصات'),
        actions: [
          IconButton(
            tooltip: 'إنشاء مناقصة',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.createTender),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tenderListProvider.notifier).refreshList(),
        child: tendersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.read(tenderListProvider.notifier).refreshList(),
          ),
          data: (tenders) {
            if (tenders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('لا توجد مناقصات بعد.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceL, AppDimensions.spaceL,
                  AppDimensions.spaceL, 120),
              itemCount: tenders.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceM),
              itemBuilder: (_, i) => _TenderCard(tender: tenders[i]),
            );
          },
        ),
      ),
    );
  }
}

class _TenderCard extends StatelessWidget {
  final Tender tender;
  const _TenderCard({required this.tender});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.tenderDetails(tender.id)),
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      child: Container(
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
                Expanded(
                  child: Text(
                    tender.title,
                    style: AppTextStyles.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusPill(
                  label: tender.statusLabel,
                  color: tender.isOpen ? AppColors.success : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              tender.description,
              style: AppTextStyles.bodySecondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 4),
                Text('${tender.budget.toStringAsFixed(0)} ',
                    style: AppTextStyles.link),
                const Spacer(),
                if (tender.contractor != null) ...[
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(tender.contractor!.name,
                      style: AppTextStyles.caption),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off, size: 48, color: AppColors.textHint),
        const SizedBox(height: AppDimensions.spaceM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
          child: Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Center(
          child: TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ),
      ],
    );
  }
}
