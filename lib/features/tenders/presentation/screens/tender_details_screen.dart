import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bids/domain/entities/bid.dart';
import '../../../bids/presentation/providers/bid_provider.dart';
import '../../domain/entities/tender.dart';
import '../providers/tender_provider.dart';

/// تفاصيل مناقصة + عروضها.
/// GET /tenders/{id} و GET /bids?tender_id={id}
class TenderDetailsScreen extends ConsumerWidget {
  final int tenderId;
  const TenderDetailsScreen({super.key, required this.tenderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenderAsync = ref.watch(tenderDetailsProvider(tenderId));
    final bidsAsync = ref.watch(tenderBidsProvider(tenderId));

    return ClientScaffold(
      appBar: AppBar(title: const Text('تفاصيل المناقصة')),
      body: tenderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (tender) => ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          children: [
            _TenderHeader(tender: tender),
            const SizedBox(height: AppDimensions.spaceXL),
            Text('العروض المقدّمة', style: AppTextStyles.title),
            const SizedBox(height: AppDimensions.spaceM),
            bidsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString(),
                  style: AppTextStyles.bodySecondary),
              data: (bids) {
                if (bids.isEmpty) {
                  return Text('لا توجد عروض بعد.',
                      style: AppTextStyles.bodySecondary);
                }
                return Column(
                  children: [
                    for (final bid in bids) ...[
                      _BidCard(bid: bid, tender: tender),
                      const SizedBox(height: AppDimensions.spaceM),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TenderHeader extends StatelessWidget {
  final Tender tender;
  const _TenderHeader({required this.tender});

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: Text(tender.title, style: AppTextStyles.headline)),
              StatusPill(
                label: tender.statusLabel,
                color: tender.isOpen
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(tender.description, style: AppTextStyles.body),
          const Divider(height: AppDimensions.spaceXL),
          _Row(
            icon: Icons.payments_outlined,
            label: 'الميزانية',
            value: tender.budget.toStringAsFixed(2),
          ),
          if (tender.deadline != null)
            _Row(
              icon: Icons.event_outlined,
              label: 'آخر موعد',
              value: '${tender.deadline!.year}-'
                  '${tender.deadline!.month.toString().padLeft(2, '0')}-'
                  '${tender.deadline!.day.toString().padLeft(2, '0')}',
            ),
          if (tender.contractor != null)
            _Row(
              icon: Icons.person_outline,
              label: 'صاحب المناقصة',
              value: tender.contractor!.name,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.spaceS),
          Text(label, style: AppTextStyles.bodySecondary),
          const Spacer(),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _BidCard extends ConsumerWidget {
  final Bid bid;
  final Tender tender;
  const _BidCard({required this.bid, required this.tender});

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('قبول العرض'),
        content: const Text(
          'سيتم قبول هذا العرض، وإغلاق المناقصة، ورفض باقي العروض تلقائياً. '
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(bidActionProvider.notifier)
        .accept(bidId: bid.id, tenderId: tender.id);

    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.showSuccess(
        context,
        'تم قبول العرض. أُغلقت المناقصة ورُفضت باقي العروض.',
      );
      // ننتقل لشاشة العرض المقبول (20_accepted_offer_contact).
      context.push(AppRoutes.acceptedOffer(tender.id, bid.id));
    } else {
      final err = ref.read(bidActionProvider).error ?? 'تعذّر قبول العرض.';
      AppSnackBar.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(bidActionProvider).isLoading;
    final merchant = bid.merchant;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        boxShadow: AppDimensions.cardShadow,
        border: bid.isAccepted
            ? Border.all(color: AppColors.success, width: 1.4)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: merchant?.avatarUrl != null
                    ? NetworkImage(merchant!.avatarUrl!)
                    : null,
                child: merchant?.avatarUrl == null
                    ? const Icon(Icons.person_outline, size: 18)
                    : null,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Text(merchant?.name ?? 'مورّد',
                    style: AppTextStyles.title),
              ),
              StatusPill(
                label: bid.statusLabel,
                color: bid.isAccepted
                    ? AppColors.success
                    : bid.isRejected
                        ? AppColors.error
                        : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              const Icon(Icons.sell_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(bid.price.toStringAsFixed(2), style: AppTextStyles.link),
            ],
          ),
          if (bid.proposal != null) ...[
            const SizedBox(height: AppDimensions.spaceS),
            Text(bid.proposal!, style: AppTextStyles.bodySecondary),
          ],
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              if (merchant != null)
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.chat(merchant.id)),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('مراسلة'),
                ),
              const Spacer(),
              // القبول متاح فقط لصاحب المناقصة وما دامت مفتوحة.
              if (tender.isOpen && !bid.isAccepted)
                _AcceptButton(
                  isLoading: isLoading,
                  onPressed: () => _accept(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptButton extends ConsumerWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _AcceptButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(authProvider).user?.id;
    if (myId == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 40),
      ),
      child: const Text('قبول العرض'),
    );
  }
}
